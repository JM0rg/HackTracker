"""
Update Player Lambda Handler

API Gateway handler to update a player's information.
Allows updating firstName, lastName, playerNumber, and status.
"""

import json
import sys
from pathlib import Path
from datetime import datetime, timezone
from decimal import Decimal

# Add utils to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from botocore.exceptions import ClientError
from utils import get_table, create_response
from utils.validation import validate_player_name, validate_player_number, validate_player_status, validate_player_positions
from utils.authorization import get_user_id_from_event, authorize, PermissionError


def handler(event, context):
    """
    Lambda handler for PUT /teams/{teamId}/players/{playerId}
    
    Updates a player's information.
    Requires team-owner or team-coach role.
    
    Args:
        event: API Gateway event
        context: Lambda context
        
    Returns:
        API Gateway response with updated player data (200 OK)
    """
    print(json.dumps({
        'level': 'INFO',
        'message': 'Processing update player request',
        'httpMethod': event.get('requestContext', {}).get('http', {}).get('method'),
        'path': event.get('requestContext', {}).get('http', {}).get('path')
    }))
    
    try:
        # Extract user ID from JWT
        try:
            user_id = get_user_id_from_event(event)
        except ValueError as e:
            return create_response(401, {'error': str(e)})
        
        # Extract team ID and player ID from path
        path_params = event.get('pathParameters', {})
        team_id = path_params.get('teamId')
        player_id = path_params.get('playerId')
        
        if not team_id:
            return create_response(400, {'error': 'teamId is required in path'})
        if not player_id:
            return create_response(400, {'error': 'playerId is required in path'})
        
        # Parse request body
        try:
            body = json.loads(event.get('body', '{}'))
        except json.JSONDecodeError:
            return create_response(400, {'error': 'Invalid JSON in request body'})
        
        # Check for read-only fields
        readonly_fields = {
            'playerId', 'teamId', 'isGhost', 'userId', 'linkedAt', 
            'createdAt', 'updatedAt', 'PK', 'SK'
        }
        
        invalid_fields = readonly_fields & set(body.keys())
        if invalid_fields:
            return create_response(400, {
                'error': f'Cannot update read-only fields: {", ".join(invalid_fields)}'
            })
        
        # Authorize: check if user can manage roster
        table = get_table()
        try:
            authorize(table, user_id, team_id, action='manage_roster')
        except PermissionError as e:
            return create_response(403, {'error': str(e)})
        except ClientError as e:
            if e.response['Error']['Code'] == 'ResourceNotFoundException':
                return create_response(404, {'error': 'Team not found'})
            raise
        
        # Validate and prepare updates
        update_fields = {}
        
        # Validate firstName if provided
        if 'firstName' in body:
            try:
                first_name = validate_player_name(body['firstName'], 'firstName')
                update_fields['firstName'] = first_name
            except ValueError as e:
                return create_response(400, {'error': str(e)})
        
        # Validate lastName if provided (can be null/empty to remove)
        if 'lastName' in body:
            if body['lastName'] is None or body['lastName'] == '':
                update_fields['lastName'] = None
            else:
                try:
                    last_name = validate_player_name(body['lastName'], 'lastName')
                    update_fields['lastName'] = last_name
                except ValueError as e:
                    return create_response(400, {'error': str(e)})
        
        # Validate playerNumber if provided (can be null to remove)
        if 'playerNumber' in body:
            if body['playerNumber'] is None:
                update_fields['playerNumber'] = None
            else:
                try:
                    player_number = validate_player_number(body['playerNumber'])
                    update_fields['playerNumber'] = player_number
                except ValueError as e:
                    return create_response(400, {'error': str(e)})
        
        # Validate status if provided
        if 'status' in body:
            try:
                status = validate_player_status(body['status'])
                update_fields['status'] = status
            except ValueError as e:
                return create_response(400, {'error': str(e)})
        
        # Validate positions if provided
        if 'positions' in body:
            try:
                # Allow null/None to remove positions
                if body['positions'] is None:
                    update_fields['positions'] = None
                else:
                    positions = validate_player_positions(body['positions'])
                    update_fields['positions'] = positions
            except ValueError as e:
                return create_response(400, {'error': str(e)})
        
        # Check if there are any fields to update
        if not update_fields:
            return create_response(400, {'error': 'No valid fields to update'})
        
        # Build UpdateExpression dynamically
        update_expression_parts = []
        expression_attribute_names = {}
        expression_attribute_values = {}
        
        for idx, (field, value) in enumerate(update_fields.items()):
            attr_name = f'#field{idx}'
            attr_value = f':value{idx}'
            
            if value is None:
                # Remove attribute if value is None
                update_expression_parts.append(f'REMOVE {attr_name}')
                expression_attribute_names[attr_name] = field
            else:
                # Set attribute
                update_expression_parts.append(f'{attr_name} = {attr_value}')
                expression_attribute_names[attr_name] = field
                expression_attribute_values[attr_value] = value
        
        # Always update updatedAt
        update_expression_parts.append('#updatedAt = :updatedAt')
        expression_attribute_names['#updatedAt'] = 'updatedAt'
        expression_attribute_values[':updatedAt'] = datetime.now(timezone.utc).isoformat()
        
        # Combine SET and REMOVE operations
        set_parts = [p for p in update_expression_parts if not p.startswith('REMOVE')]
        remove_parts = [p for p in update_expression_parts if p.startswith('REMOVE')]
        
        update_expression = ''
        if set_parts:
            update_expression += 'SET ' + ', '.join(set_parts)
        if remove_parts:
            if update_expression:
                update_expression += ' '
            update_expression += ' '.join(remove_parts)
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'Updating player',
            'playerId': player_id,
            'teamId': team_id,
            'fields': list(update_fields.keys())
        }))
        
        # Update player in DynamoDB
        try:
            response = table.update_item(
                Key={
                    'PK': f'TEAM#{team_id}',
                    'SK': f'PLAYER#{player_id}'
                },
                UpdateExpression=update_expression,
                ExpressionAttributeNames=expression_attribute_names,
                ExpressionAttributeValues=expression_attribute_values if expression_attribute_values else None,
                ConditionExpression='attribute_exists(PK)',
                ReturnValues='ALL_NEW'
            )
        except ClientError as e:
            if e.response['Error']['Code'] == 'ConditionalCheckFailedException':
                print(json.dumps({
                    'level': 'ERROR',
                    'message': 'Player not found',
                    'playerId': player_id,
                    'teamId': team_id
                }))
                return create_response(404, {'error': 'Player not found'})
            raise
        
        updated_player = response['Attributes']
        
        # Build clean response (exclude internal DynamoDB keys)
        response_data = {
            'playerId': updated_player['playerId'],
            'teamId': updated_player['teamId'],
            'firstName': updated_player['firstName'],
            'status': updated_player['status'],
            'isGhost': updated_player.get('isGhost', False),
            'createdAt': updated_player['createdAt'],
            'updatedAt': updated_player['updatedAt']
        }
        
        # Add optional fields
        if 'lastName' in updated_player and updated_player['lastName']:
            response_data['lastName'] = updated_player['lastName']
        
        if 'playerNumber' in updated_player and updated_player['playerNumber'] is not None:
            # Convert Decimal to int for JSON serialization
            response_data['playerNumber'] = int(updated_player['playerNumber']) if isinstance(updated_player['playerNumber'], Decimal) else updated_player['playerNumber']
        
        if 'userId' in updated_player and updated_player['userId']:
            response_data['userId'] = updated_player['userId']
        
        if 'linkedAt' in updated_player and updated_player['linkedAt']:
            response_data['linkedAt'] = updated_player['linkedAt']
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'Player updated successfully',
            'playerId': player_id,
            'teamId': team_id
        }))
        
        return create_response(200, response_data)
        
    except ClientError as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'DynamoDB error',
            'error': str(e)
        }))
        return create_response(500, {'error': 'Could not update player'})
        
    except Exception as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'Unexpected error',
            'error': str(e),
            'errorType': type(e).__name__
        }))
        return create_response(500, {'error': 'Internal server error'})

