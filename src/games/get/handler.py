"""
Get Game Lambda Handler

API Gateway handler to retrieve a single game by gameId.
Any team member can view the game.
"""

import json
import sys
from pathlib import Path

# Add utils to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from botocore.exceptions import ClientError
from utils import get_table, create_response
from utils.authorization import get_user_id_from_event, check_team_membership, PermissionError


def handler(event, context):
    """
    Lambda handler for GET /games/{gameId}
    
    Retrieves a single game by gameId.
    Any team member can view the game.
    
    Args:
        event: API Gateway event
        context: Lambda context
        
    Returns:
        API Gateway response with game data (200 OK) or 404 if not found
    """
    print(json.dumps({
        'level': 'INFO',
        'message': 'Processing get game request',
        'httpMethod': event.get('requestContext', {}).get('http', {}).get('method'),
        'path': event.get('requestContext', {}).get('http', {}).get('path')
    }))
    
    try:
        # Extract user ID from JWT
        try:
            user_id = get_user_id_from_event(event)
        except ValueError as e:
            return create_response(401, {'error': str(e)})
        
        # Extract gameId from path parameters
        path_params = event.get('pathParameters', {})
        game_id = path_params.get('gameId')
        
        if not game_id:
            return create_response(400, {'error': 'gameId is required in path'})
        
        # Get game from DynamoDB
        table = get_table()
        response = table.get_item(
            Key={
                'PK': f'GAME#{game_id}',
                'SK': 'METADATA'
            }
        )
        
        # Check if game exists
        if 'Item' not in response:
            print(json.dumps({
                'level': 'WARN',
                'message': 'Game not found',
                'gameId': game_id
            }))
            return create_response(404, {'error': 'Game not found'})
        
        game = response['Item']
        team_id = game['teamId']
        
        # Authorize: check if user is a member of this team
        try:
            check_team_membership(table, user_id, team_id)
        except PermissionError as e:
            return create_response(403, {'error': str(e)})
        except ClientError as e:
            if e.response['Error']['Code'] == 'ResourceNotFoundException':
                return create_response(404, {'error': 'Team not found'})
            raise
        
        # Format response (remove internal DynamoDB keys)
        game_response = {
            'gameId': game['gameId'],
            'teamId': game['teamId'],
            'gameTitle': game['gameTitle'],
            'status': game['status'],
            'teamScore': game.get('teamScore', 0),
            'opponentScore': game.get('opponentScore', 0),
            'lineup': game.get('lineup', []),
            'createdAt': game['createdAt'],
            'updatedAt': game['updatedAt']
        }
        
        # Add optional fields
        if 'scheduledStart' in game:
            game_response['scheduledStart'] = game['scheduledStart']
        
        if 'opponentName' in game:
            game_response['opponentName'] = game['opponentName']
        
        if 'location' in game:
            game_response['location'] = game['location']
        
        if 'seasonId' in game:
            game_response['seasonId'] = game['seasonId']
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'Game retrieved successfully',
            'gameId': game_id,
            'teamId': team_id
        }))
        
        return create_response(200, game_response)
        
    except ClientError as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'DynamoDB error',
            'error': str(e)
        }))
        return create_response(500, {'error': 'Internal server error'})
        
    except Exception as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'Unexpected error',
            'error': str(e),
            'errorType': type(e).__name__
        }))
        return create_response(500, {'error': 'Internal server error'})
