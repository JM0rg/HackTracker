"""
List Games by Team Lambda Handler

API Gateway handler to retrieve all games for a specific team.
Any team member can view games.
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
    Lambda handler for GET /teams/{teamId}/games
    
    Lists all games for a specific team.
    Any team member can view games.
    
    Args:
        event: API Gateway event
        context: Lambda context
        
    Returns:
        API Gateway response with array of game objects (200 OK)
    """
    print(json.dumps({
        'level': 'INFO',
        'message': 'Processing list games by team request',
        'httpMethod': event.get('requestContext', {}).get('http', {}).get('method'),
        'path': event.get('requestContext', {}).get('http', {}).get('path')
    }))
    
    try:
        # Extract user ID from JWT
        try:
            user_id = get_user_id_from_event(event)
        except ValueError as e:
            return create_response(401, {'error': str(e)})
        
        # Extract team ID from path parameters
        path_params = event.get('pathParameters', {})
        team_id = path_params.get('teamId')
        
        if not team_id:
            return create_response(400, {'error': 'teamId is required in path'})
        
        # Authorize: check if user is a member of this team
        table = get_table()
        try:
            check_team_membership(table, user_id, team_id)
        except PermissionError as e:
            return create_response(403, {'error': str(e)})
        except ClientError as e:
            if e.response['Error']['Code'] == 'ResourceNotFoundException':
                return create_response(404, {'error': 'Team not found'})
            raise
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'Querying games for team',
            'teamId': team_id,
            'userId': user_id
        }))
        
        # Query games using GSI3 (team-based index)
        response = table.query(
            IndexName='GSI3',
            KeyConditionExpression='GSI3PK = :pk AND begins_with(GSI3SK, :sk_prefix)',
            ExpressionAttributeValues={
                ':pk': f'TEAM#{team_id}',
                ':sk_prefix': 'GAME#'
            }
        )
        
        games = response.get('Items', [])
        
        # Sort by scheduledStart descending (newest first)
        # Games without scheduledStart will be sorted to the end
        def sort_key(game):
            scheduled_start = game.get('scheduledStart')
            if scheduled_start:
                return scheduled_start
            return '0000-00-00T00:00:00Z'  # Put games without date at end
        
        games.sort(key=sort_key, reverse=True)
        
        # Format response (remove internal DynamoDB keys)
        formatted_games = []
        for game in games:
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
            
            formatted_games.append(game_response)
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'Games retrieved successfully',
            'teamId': team_id,
            'gameCount': len(formatted_games)
        }))
        
        return create_response(200, formatted_games)
        
    except ClientError as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'DynamoDB error',
            'error': str(e)
        }))
        return create_response(500, {'error': 'Could not retrieve games'})
        
    except Exception as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'Unexpected error',
            'error': str(e),
            'errorType': type(e).__name__
        }))
        return create_response(500, {'error': 'Internal server error'})
