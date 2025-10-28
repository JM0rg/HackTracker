"""
Add Player Lambda Handler

API Gateway handler to add a ghost player to a team roster.
Creates unlinked player record that can be linked to a user later.
"""

import json
import sys
import uuid
from pathlib import Path
from datetime import datetime, timezone

# Add utils to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from botocore.exceptions import ClientError
from utils import get_table, create_response
from utils.validation import validate_player_name, validate_player_number, validate_player_status
from utils.authorization import get_user_id_from_event, authorize, check_personal_team_operation, PermissionError


def handler(event, context):
    """
    Lambda handler for POST /teams/{teamId}/players
    
    Adds a ghost player (unlinked roster slot) to a team.
    Requires team-owner or team-coach role.
    
    Args:
        event: API Gateway event
        context: Lambda context
        
    Returns:
        API Gateway response with new player data (201 Created)
    """
    print(json.dumps({
        'level': 'INFO',
        'message': 'Processing add player request',
        'httpMethod': event.get('requestContext', {}).get('http', {}).get('method'),
        'path': event.get('requestContext', {}).get('http', {}).get('path')
    }))
    
    try:
        # Extract user ID from JWT
        try:
            user_id = get_user_id_from_event(event)
        except ValueError as e:
            return create_response(401, {'error': str(e)})
        
        # Extract team ID from path
        path_params = event.get('pathParameters', {})
        team_id = path_params.get('teamId')
        
        if not team_id:
            return create_response(400, {'error': 'teamId is required in path'})
        
        # Parse request body
        try:
            body = json.loads(event.get('body', '{}'))
        except json.JSONDecodeError:
            return create_response(400, {'error': 'Invalid JSON in request body'})
        
        # Validate required fields
        if not body.get('firstName'):
            return create_response(400, {'error': 'firstName is required'})
        
        # Validate first name
        try:
            first_name = validate_player_name(body['firstName'], 'firstName')
        except ValueError as e:
            return create_response(400, {'error': str(e)})
        
        # Validate last name (optional)
        last_name = None
        if 'lastName' in body and body['lastName']:
            try:
                last_name = validate_player_name(body['lastName'], 'lastName')
            except ValueError as e:
                return create_response(400, {'error': str(e)})
        
        # Validate player number (optional)
        player_number = None
        if 'playerNumber' in body and body['playerNumber'] is not None:
            try:
                player_number = validate_player_number(body['playerNumber'])
            except ValueError as e:
                return create_response(400, {'error': str(e)})
        
        # Validate status (defaults to 'active')
        try:
            status = validate_player_status(body.get('status'))
        except ValueError as e:
            return create_response(400, {'error': str(e)})
        
        table = get_table()
        
        # Check team type - PERSONAL teams can only have the owner's player
        try:
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
            
            if team_type == 'PERSONAL':
                return create_response(400, {
                    'error': 'Cannot add players to personal teams. Personal teams can only contain the owner as a player.'
                })
        except ClientError as e:
            return create_response(500, {'error': 'Could not verify team type'})
        
        # Authorize: check if user can manage roster
        try:
            authorize(table, user_id, team_id, action='manage_roster')
        except PermissionError as e:
            return create_response(403, {'error': str(e)})
        except ClientError as e:
            if e.response['Error']['Code'] == 'ResourceNotFoundException':
                return create_response(404, {'error': 'Team not found'})
            raise
        
        # Generate player ID and timestamp
        player_id = str(uuid.uuid4())
        timestamp = datetime.now(timezone.utc).isoformat()
        
        # Prepare player record
        player_item = {
            'PK': f'TEAM#{team_id}',
            'SK': f'PLAYER#{player_id}',
            'playerId': player_id,
            'teamId': team_id,
            'firstName': first_name,
            'status': status,
            'isGhost': True,
            'userId': None,  # Ghost player - not linked
            'linkedAt': None,
            'createdAt': timestamp,
            'updatedAt': timestamp
        }
        
        # Add optional fields if provided
        if last_name:
            player_item['lastName'] = last_name
        
        if player_number is not None:
            player_item['playerNumber'] = player_number
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'Creating ghost player',
            'playerId': player_id,
            'teamId': team_id,
            'firstName': first_name,
            'status': status
        }))
        
        # Create player record
        try:
            table.put_item(
                Item=player_item,
                ConditionExpression='attribute_not_exists(PK) AND attribute_not_exists(SK)'
            )
        except ClientError as e:
            if e.response['Error']['Code'] == 'ConditionalCheckFailedException':
                print(json.dumps({
                    'level': 'ERROR',
                    'message': 'Player already exists',
                    'playerId': player_id,
                    'teamId': team_id
                }))
                return create_response(409, {'error': 'Player already exists'})
            raise
        
        # Build response (include all fields from player_item)
        response_data = {
            'playerId': player_id,
            'teamId': team_id,
            'firstName': first_name,
            'lastName': last_name,
            'playerNumber': player_number,
            'status': status,
            'isGhost': True,
            'userId': None,
            'linkedAt': None,
            'createdAt': timestamp,
            'updatedAt': timestamp
        }
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'Player created successfully',
            'playerId': player_id,
            'teamId': team_id
        }))
        
        return create_response(201, response_data)
        
    except ClientError as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'DynamoDB error',
            'error': str(e)
        }))
        return create_response(500, {'error': 'Could not create player'})
        
    except Exception as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'Unexpected error',
            'error': str(e),
            'errorType': type(e).__name__
        }))
        return create_response(500, {'error': 'Internal server error'})

