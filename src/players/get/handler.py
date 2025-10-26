"""
Get Player Lambda Handler

API Gateway handler to get a single player from a team roster.
"""

import json
import sys
from pathlib import Path
from decimal import Decimal

# Add utils to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from botocore.exceptions import ClientError
from utils import get_table, create_response
from utils.authorization import get_user_id_from_event, check_team_role, PermissionError


def handler(event, context):
    """
    Lambda handler for GET /teams/{teamId}/players/{playerId}
    
    Gets a single player from a team roster.
    All team members can view players.
    
    Args:
        event: API Gateway event
        context: Lambda context
        
    Returns:
        API Gateway response with player data (200 OK)
    """
    print(json.dumps({
        'level': 'INFO',
        'message': 'Processing get player request',
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
        
        # Authorize: all team members can view players
        table = get_table()
        try:
            check_team_role(
                table, 
                user_id, 
                team_id, 
                ['team-owner', 'team-coach', 'team-player', 'team-assistant', 'team-scorekeeper', 'team-viewer']
            )
        except PermissionError as e:
            return create_response(403, {'error': str(e)})
        except ClientError as e:
            if e.response['Error']['Code'] == 'ResourceNotFoundException':
                return create_response(404, {'error': 'Team not found'})
            raise
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'Getting player',
            'teamId': team_id,
            'playerId': player_id
        }))
        
        # Get player from DynamoDB
        response = table.get_item(
            Key={
                'PK': f'TEAM#{team_id}',
                'SK': f'PLAYER#{player_id}'
            }
        )
        
        if 'Item' not in response:
            print(json.dumps({
                'level': 'WARN',
                'message': 'Player not found',
                'teamId': team_id,
                'playerId': player_id
            }))
            return create_response(404, {'error': 'Player not found'})
        
        player = response['Item']
        
        # Convert Decimal to int for JSON serialization
        if 'playerNumber' in player and isinstance(player['playerNumber'], Decimal):
            player['playerNumber'] = int(player['playerNumber'])
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'Player retrieved successfully',
            'playerId': player_id,
            'teamId': team_id
        }))
        
        return create_response(200, player)
        
    except ClientError as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'DynamoDB error',
            'error': str(e)
        }))
        return create_response(500, {'error': 'Could not get player'})
        
    except Exception as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'Unexpected error',
            'error': str(e),
            'errorType': type(e).__name__
        }))
        return create_response(500, {'error': 'Internal server error'})

