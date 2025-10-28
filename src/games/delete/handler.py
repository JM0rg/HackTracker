"""
Delete Game Lambda Handler

API Gateway handler to delete a game.
Only team-owner, team-coach, or team-scorekeeper can delete games.
Performs hard delete (no soft delete for games).
"""

import json
import sys
from pathlib import Path

# Add utils to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from botocore.exceptions import ClientError
from utils import get_table, create_response
from utils.authorization import get_user_id_from_event, authorize, PermissionError


def handler(event, context):
    """
    Lambda handler for DELETE /games/{gameId}
    
    Deletes a game permanently (hard delete).
    Only team-owner, team-coach, or team-scorekeeper can delete games.
    
    Args:
        event: API Gateway event
        context: Lambda context
        
    Returns:
        API Gateway response (204 No Content on success)
    """
    print(json.dumps({
        'level': 'INFO',
        'message': 'Processing delete game request',
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
    
    table = get_table()
    
    try:
        # Fetch game record to get teamId and verify it exists
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
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'Deleting game',
            'gameId': game_id,
            'teamId': team_id,
            'userId': user_id
        }))
        
        # Delete the game (hard delete)
        table.delete_item(
            Key={
                'PK': f'GAME#{game_id}',
                'SK': 'METADATA'
            }
        )
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'Game deleted successfully',
            'gameId': game_id,
            'teamId': team_id
        }))
        
        # Return 204 No Content (standard for successful DELETE)
        return create_response(204)
        
    except ClientError as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'DynamoDB error',
            'error': str(e),
            'gameId': game_id,
            'userId': user_id
        }))
        return create_response(500, {'error': 'Could not delete game'})
    
    except Exception as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'Unexpected error',
            'error': str(e),
            'gameId': game_id,
            'userId': user_id
        }))
        return create_response(500, {'error': 'Internal server error'})
