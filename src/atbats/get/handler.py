"""
Get AtBat Lambda Handler

API Gateway handler to retrieve a specific at-bat.
Returns details of a single plate appearance.
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
    Lambda handler for GET /games/{gameId}/atbats/{atBatId}
    
    Retrieves a specific at-bat.
    Requires team membership (any role).
    
    Args:
        event: API Gateway event
        context: Lambda context
        
    Returns:
        API Gateway response with at-bat details (200 OK)
    """
    print(json.dumps({
        'level': 'INFO',
        'message': 'Processing get at-bat request',
        'httpMethod': event.get('requestContext', {}).get('http', {}).get('method'),
        'path': event.get('requestContext', {}).get('http', {}).get('path')
    }))
    
    try:
        # Extract user ID from JWT
        try:
            user_id = get_user_id_from_event(event)
        except ValueError as e:
            return create_response(401, {'error': str(e)})
        
        # Extract path parameters
        path_params = event.get('pathParameters', {})
        game_id = path_params.get('gameId')
        atbat_id = path_params.get('atBatId')
        
        if not game_id:
            return create_response(400, {'error': 'gameId is required in path'})
        
        if not atbat_id:
            return create_response(400, {'error': 'atBatId is required in path'})
        
        # Get at-bat from DynamoDB
        table = get_table()
        response = table.get_item(
            Key={
                'PK': f'GAME#{game_id}',
                'SK': f'ATBAT#{atbat_id}'
            }
        )
        
        # Check if at-bat exists
        if 'Item' not in response:
            print(json.dumps({
                'level': 'WARN',
                'message': 'At-bat not found',
                'gameId': game_id,
                'atBatId': atbat_id
            }))
            return create_response(404, {'error': 'At-bat not found'})
        
        atbat = response['Item']
        team_id = atbat['teamId']
        
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
        atbat_response = {
            'atBatId': atbat['atBatId'],
            'gameId': atbat['gameId'],
            'playerId': atbat['playerId'],
            'teamId': atbat['teamId'],
            'result': atbat['result'],
            'inning': atbat['inning'],
            'outs': atbat['outs'],
            'battingOrder': atbat['battingOrder'],
            'createdAt': atbat['createdAt'],
            'updatedAt': atbat['updatedAt']
        }
        
        # Add optional fields if present
        if 'hitLocation' in atbat:
            atbat_response['hitLocation'] = atbat['hitLocation']
        if 'hitType' in atbat:
            atbat_response['hitType'] = atbat['hitType']
        if 'rbis' in atbat:
            atbat_response['rbis'] = atbat['rbis']
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'At-bat retrieved successfully',
            'atBatId': atbat_id
        }))
        
        return create_response(200, atbat_response)
        
    except ClientError as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'DynamoDB error',
            'error': str(e),
            'errorCode': e.response['Error']['Code']
        }))
        return create_response(500, {'error': 'Could not retrieve at-bat'})
    
    except Exception as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'Unexpected error',
            'error': str(e),
            'type': type(e).__name__
        }))
        return create_response(500, {'error': 'Internal server error'})

