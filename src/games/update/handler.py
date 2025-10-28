"""
Update Game Lambda Handler

API Gateway handler to update game information.
Only allows team-owner, team-coach, or team-scorekeeper to update.
Includes critical lineup validation for real teams transitioning to IN_PROGRESS.
"""

import json
import sys
from pathlib import Path
from datetime import datetime, timezone

# Add utils to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from botocore.exceptions import ClientError
from utils import get_table, create_response
from utils.validation import validate_game_title, validate_game_status, validate_score, validate_lineup
from utils.authorization import get_user_id_from_event, authorize, PermissionError

# Fields that are allowed to be updated
ALLOWED_FIELDS = {'gameTitle', 'status', 'scheduledStart', 'opponentName', 'location', 'teamScore', 'opponentScore', 'lineup', 'seasonId'}

# Fields that are read-only (cannot be updated)
READONLY_FIELDS = {'gameId', 'teamId', 'createdAt', 'updatedAt', 'PK', 'SK', 'GSI1PK', 'GSI1SK', 'GSI2PK', 'GSI2SK', 'GSI3PK', 'GSI3SK', 'GSI4PK', 'GSI4SK', 'GSI5PK', 'GSI5SK'}


def _validate_lineup_players_belong_to_team(table, lineup, team_id):
    """
    Validate that all players in the lineup belong to the team.
    
    Args:
        table: DynamoDB table resource
        lineup: List of dicts with playerId and battingOrder
        team_id: Team ID to validate against
        
    Raises:
        ValueError: If any player in lineup doesn't belong to the team
    """
    if not lineup or len(lineup) == 0:
        return
    
    # Extract all player IDs from the lineup
    lineup_player_ids = {player.get('playerId') for player in lineup if player.get('playerId')}
    
    if not lineup_player_ids:
        return
    
    # Query all players for this team
    try:
        response = table.query(
            KeyConditionExpression='PK = :pk AND begins_with(SK, :sk_prefix)',
            ExpressionAttributeValues={
                ':pk': f'TEAM#{team_id}',
                ':sk_prefix': 'PLAYER#'
            }
        )
        
        team_player_ids = {item.get('playerId') for item in response.get('Items', []) if item.get('playerId')}
        
        # Check if all lineup players belong to the team
        invalid_players = lineup_player_ids - team_player_ids
        if invalid_players:
            raise ValueError(f'The following players are not on this team: {", ".join(invalid_players)}')
            
    except ClientError as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'Failed to validate lineup players',
            'error': str(e),
            'teamId': team_id
        }))
        raise ValueError('Could not validate lineup players')


def handler(event, context):
    """
    Lambda handler for PATCH /games/{gameId}
    
    Allows updating: gameTitle, status, scheduledStart, opponentName, location, teamScore, opponentScore, lineup, seasonId
    Requires: team-owner, team-coach, or team-scorekeeper role
    Automatically updates: updatedAt
    Read-only: gameId, teamId, createdAt, GSI*
    
    Args:
        event: API Gateway event
        context: Lambda context
        
    Returns:
        API Gateway response with updated game data
    """
    print(json.dumps({
        'level': 'INFO',
        'message': 'Processing update game request',
        'httpMethod': event.get('requestContext', {}).get('http', {}).get('method'),
        'path': event.get('requestContext', {}).get('http', {}).get('path')
    }))
    
    # Extract gameId from path parameters
    game_id = event.get('pathParameters', {}).get('gameId')
    if not game_id:
        return create_response(400, {'error': 'Missing gameId in path'})
    
    # Get user ID from request
    try:
        user_id = get_user_id_from_event(event)
    except ValueError as e:
        return create_response(401, {'error': str(e)})
    
    # Parse request body
    try:
        body = json.loads(event.get('body', '{}'))
    except json.JSONDecodeError:
        return create_response(400, {'error': 'Invalid JSON in request body'})
    
    if not body:
        return create_response(400, {'error': 'Request body is required'})
    
    # Validate fields - check for readonly fields
    readonly_attempted = set(body.keys()) & READONLY_FIELDS
    if readonly_attempted:
        return create_response(400, {
            'error': 'Cannot update read-only fields',
            'readOnlyFields': list(readonly_attempted)
        })
    
    # Validate fields - check for unknown fields
    unknown_fields = set(body.keys()) - ALLOWED_FIELDS
    if unknown_fields:
        return create_response(400, {
            'error': 'Invalid fields in request',
            'invalidFields': list(unknown_fields),
            'allowedFields': list(ALLOWED_FIELDS)
        })
    
    # Check if there are any fields to update
    if not body:
        return create_response(400, {'error': 'No valid fields to update'})
    
    table = get_table()

    try:
        # Fetch existing game record
        get_response = table.get_item(
            Key={
                'PK': f'GAME#{game_id}',
                'SK': 'METADATA'
            }
        )
        
        if 'Item' not in get_response:
            print(json.dumps({
                'level': 'WARN',
                'message': 'Game not found',
                'gameId': game_id
            }))
            return create_response(404, {'error': 'Game not found'})
        
        game = get_response['Item']
        team_id = game['teamId']
        
        # Check authorization: can user manage games for this team?
        try:
            authorize(table, user_id, team_id, action='manage_games')
        except PermissionError as e:
            return create_response(403, {'error': str(e)})
        
        # CRITICAL VALIDATION: Check lineup requirement for real teams transitioning to IN_PROGRESS
        if 'status' in body and body['status'] == 'IN_PROGRESS':
            # Fetch team record to check if it's a personal team
            team_response = table.get_item(
                Key={
                    'PK': f'TEAM#{team_id}',
                    'SK': 'METADATA'
                }
            )
            
            if 'Item' not in team_response:
                return create_response(404, {'error': 'Team not found'})
            
            team = team_response['Item']
            team_type = team.get('team_type', 'MANAGED')  # Default to MANAGED for backwards compatibility
            
            # Check current lineup (either from update or existing game)
            current_lineup = body.get('lineup', game.get('lineup', []))
            
            # If it's a MANAGED team AND lineup is empty, block the update
            if team_type == 'MANAGED' and (not current_lineup or len(current_lineup) == 0):
                print(json.dumps({
                    'level': 'WARN',
                    'message': 'Lineup required for managed team to start game',
                    'gameId': game_id,
                    'teamId': team_id,
                    'team_type': team_type
                }))
                return create_response(400, {
                    'error': 'A lineup is required before you can start the game. Please set the lineup first.'
                })
        
        # Build update expression
        update_expression_parts = []
        expression_attribute_names = {}
        expression_attribute_values = {}
        
        # Add updatedAt timestamp
        update_expression_parts.append('#updatedAt = :updatedAt')
        expression_attribute_names['#updatedAt'] = 'updatedAt'
        expression_attribute_values[':updatedAt'] = datetime.now(timezone.utc).isoformat()
        
        # Validate and add user-provided fields
        for field, value in body.items():
            if field in ALLOWED_FIELDS:
                # Validate gameTitle
                if field == 'gameTitle':
                    try:
                        value = validate_game_title(value)
                    except ValueError as e:
                        return create_response(400, {'error': str(e)})
                
                # Validate status
                elif field == 'status':
                    try:
                        value = validate_game_status(value)
                    except ValueError as e:
                        return create_response(400, {'error': str(e)})
                
                # Validate scores
                elif field in ['teamScore', 'opponentScore']:
                    try:
                        value = validate_score(value)
                    except ValueError as e:
                        return create_response(400, {'error': str(e)})
                
                # Validate lineup
                elif field == 'lineup':
                    try:
                        value = validate_lineup(value)
                    except ValueError as e:
                        return create_response(400, {'error': str(e)})
                    
                    # Additional validation: verify all players in lineup belong to the team
                    if value and len(value) > 0:
                        try:
                            _validate_lineup_players_belong_to_team(table, value, team_id)
                        except ValueError as e:
                            return create_response(400, {'error': str(e)})
                
                # Handle optional string fields (can be set to null/empty to remove them)
                elif field in ['scheduledStart', 'opponentName', 'location', 'seasonId']:
                    if value is None or value == '':
                        # Use REMOVE instead of SET for null values
                        if field in game:
                            update_expression_parts.append(f'#{field}')
                            expression_attribute_names[f'#{field}'] = field
                        continue
                
                update_expression_parts.append(f'#{field} = :{field}')
                expression_attribute_names[f'#{field}'] = field
                expression_attribute_values[f':{field}'] = value
        
        # Construct update expression
        set_parts = [part for part in update_expression_parts if ' = ' in part]
        remove_parts = [part for part in update_expression_parts if ' = ' not in part]
        
        update_expression = ''
        if set_parts:
            update_expression = 'SET ' + ', '.join(set_parts)
        if remove_parts:
            if update_expression:
                update_expression += ' '
            update_expression += 'REMOVE ' + ', '.join(remove_parts)
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'Updating game',
            'gameId': game_id,
            'teamId': team_id,
            'userId': user_id,
            'fields': list(body.keys())
        }))
        
        # Update the item
        update_params = {
            'Key': {
                'PK': f'GAME#{game_id}',
                'SK': 'METADATA'
            },
            'UpdateExpression': update_expression,
            'ExpressionAttributeNames': expression_attribute_names,
            'ReturnValues': 'ALL_NEW'
        }
        
        if expression_attribute_values:
            update_params['ExpressionAttributeValues'] = expression_attribute_values
        
        response = table.update_item(**update_params)
        
        updated_item = response['Attributes']
        
        # Format response (remove internal DynamoDB keys)
        game_data = {
            'gameId': updated_item.get('gameId'),
            'teamId': updated_item.get('teamId'),
            'gameTitle': updated_item.get('gameTitle'),
            'status': updated_item.get('status'),
            'teamScore': updated_item.get('teamScore', 0),
            'opponentScore': updated_item.get('opponentScore', 0),
            'lineup': updated_item.get('lineup', []),
            'createdAt': updated_item.get('createdAt'),
            'updatedAt': updated_item.get('updatedAt')
        }
        
        # Add optional fields
        if 'scheduledStart' in updated_item:
            game_data['scheduledStart'] = updated_item['scheduledStart']
        
        if 'opponentName' in updated_item:
            game_data['opponentName'] = updated_item['opponentName']
        
        if 'location' in updated_item:
            game_data['location'] = updated_item['location']
        
        if 'seasonId' in updated_item:
            game_data['seasonId'] = updated_item['seasonId']
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'Game updated successfully',
            'gameId': game_id
        }))
        
        return create_response(200, game_data)
        
    except ClientError as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'DynamoDB error',
            'error': str(e),
            'gameId': game_id
        }))
        return create_response(500, {'error': 'Could not update game'})
    
    except Exception as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'Unexpected error',
            'error': str(e),
            'gameId': game_id
        }))
        return create_response(500, {'error': 'Internal server error'})
