"""
Delete AtBat Lambda Handler

API Gateway handler to delete an at-bat.
Permanently removes a plate appearance record.
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
    Lambda handler for DELETE /games/{gameId}/atbats/{atBatId}
    
    Deletes an at-bat.
    Requires owner, manager, or scorekeeper role.
    
    Args:
        event: API Gateway event
        context: Lambda context
        
    Returns:
        API Gateway response with 204 No Content on success
    """
    print(json.dumps({
        'level': 'INFO',
        'message': 'Processing delete at-bat request',
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
        
        # Get at-bat from DynamoDB to extract teamId
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
        
        # Authorize: check if user can manage at-bats for this team
        try:
            authorize(table, user_id, team_id, 'manage_atbats')
        except PermissionError as e:
            return create_response(403, {'error': str(e)})
        except ClientError as e:
            if e.response['Error']['Code'] == 'ResourceNotFoundException':
                return create_response(404, {'error': 'Team not found'})
            raise
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'Deleting at-bat',
            'atBatId': atbat_id,
            'gameId': game_id
        }))
        
        # Delete at-bat from DynamoDB
        table.delete_item(
            Key={
                'PK': f'GAME#{game_id}',
                'SK': f'ATBAT#{atbat_id}'
            }
        )
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'At-bat deleted successfully',
            'atBatId': atbat_id
        }))
        
        return create_response(204, None)
        
    except ClientError as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'DynamoDB error',
            'error': str(e),
            'errorCode': e.response['Error']['Code']
        }))
        return create_response(500, {'error': 'Could not delete at-bat'})
    
    except Exception as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'Unexpected error',
            'error': str(e),
            'type': type(e).__name__
        }))
        return create_response(500, {'error': 'Internal server error'})

