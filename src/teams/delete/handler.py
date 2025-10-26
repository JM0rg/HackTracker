"""
Delete Team Lambda Handler

API Gateway handler to soft-delete a team.
Only team owners can delete teams.
Performs soft delete (sets status='deleted') for 30-day recovery period.
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
from utils.authorization import get_user_id_from_event, authorize, check_personal_team_operation, PermissionError


def handler(event, context):
    """
    Lambda handler for DELETE /teams/{teamId}
    
    Performs soft delete (sets status='deleted', adds deletedAt timestamp).
    Only team owners can delete teams.
    Team data is retained for 30-day recovery period.
    
    Args:
        event: API Gateway event
        context: Lambda context
        
    Returns:
        API Gateway response (204 No Content on success)
    """
    print(json.dumps({
        'level': 'INFO',
        'message': 'Processing delete team request',
        'httpMethod': event.get('requestContext', {}).get('http', {}).get('method'),
        'path': event.get('requestContext', {}).get('http', {}).get('path')
    }))
    
    # Extract teamId from path parameters
    team_id = event.get('pathParameters', {}).get('teamId')
    if not team_id:
        return create_response(400, {'error': 'Missing teamId in path'})
    
    # Get user ID from request
    try:
        user_id = get_user_id_from_event(event)
    except ValueError as e:
        return create_response(401, {'error': str(e)})
    
    table = get_table()
    
    try:
        # Check if this is a personal team (can't delete personal teams)
        try:
            check_personal_team_operation(table, team_id, 'delete_team')
        except PermissionError as e:
            return create_response(403, {'error': str(e)})
        
        # Check authorization: can user delete this team?
        try:
            authorize(table, user_id, team_id, action='delete_team')
        except PermissionError as e:
            return create_response(403, {'error': str(e)})
        
        # Check if team exists
        get_response = table.get_item(
            Key={
                'PK': f'TEAM#{team_id}',
                'SK': 'METADATA'
            }
        )
        
        if 'Item' not in get_response:
            print(json.dumps({
                'level': 'WARN',
                'message': 'Team not found',
                'teamId': team_id
            }))
            return create_response(404, {'error': 'Team not found'})
        
        team = get_response['Item']
        
        # Check if team is already deleted
        if team.get('status') == 'deleted':
            print(json.dumps({
                'level': 'WARN',
                'message': 'Team already deleted',
                'teamId': team_id
            }))
            return create_response(404, {'error': 'Team not found'})
        
        # Perform soft delete
        timestamp = datetime.now(timezone.utc).isoformat()
        recovery_token = str(uuid.uuid4())
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'Soft deleting team',
            'teamId': team_id,
            'userId': user_id
        }))
        
        # Update team status to deleted
        table.update_item(
            Key={
                'PK': f'TEAM#{team_id}',
                'SK': 'METADATA'
            },
            UpdateExpression='SET #status = :status, #deletedAt = :deletedAt, #recoveryToken = :recoveryToken, #updatedAt = :updatedAt',
            ExpressionAttributeNames={
                '#status': 'status',
                '#deletedAt': 'deletedAt',
                '#recoveryToken': 'recoveryToken',
                '#updatedAt': 'updatedAt'
            },
            ExpressionAttributeValues={
                ':status': 'deleted',
                ':deletedAt': timestamp,
                ':recoveryToken': recovery_token,
                ':updatedAt': timestamp
            }
        )
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'Team soft deleted successfully',
            'teamId': team_id,
            'recoveryToken': recovery_token
        }))
        
        # Return 204 No Content (standard for successful DELETE)
        return create_response(204)
        
    except ClientError as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'DynamoDB error',
            'error': str(e),
            'teamId': team_id,
            'userId': user_id
        }))
        return create_response(500, {'error': 'Could not delete team'})
    
    except Exception as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'Unexpected error',
            'error': str(e),
            'teamId': team_id,
            'userId': user_id
        }))
        return create_response(500, {'error': 'Internal server error'})

