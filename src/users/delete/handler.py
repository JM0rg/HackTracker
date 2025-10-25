"""
Delete User Lambda Handler

API Gateway handler to delete a user
Performs a soft delete by removing the user's metadata record
"""

import json
import sys
from pathlib import Path

# Add utils to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from botocore.exceptions import ClientError
from utils import get_table, create_response


def handler(event, context):
    """
    Lambda handler for DELETE /users/{userId}
    
    Deletes the user's METADATA record from DynamoDB
    
    Args:
        event: API Gateway event (v2.0 format)
        context: Lambda context
        
    Returns:
        API Gateway response with 204 No Content on success
    """
    print(json.dumps({
        'level': 'INFO',
        'message': 'Processing delete user request',
        'httpMethod': event.get('requestContext', {}).get('http', {}).get('method'),
        'path': event.get('requestContext', {}).get('http', {}).get('path')
    }))
    
    # Get userId from path parameters
    user_id = event.get('pathParameters', {}).get('userId')
    if not user_id:
        return create_response(400, {'error': 'Missing userId in path'})
    
    table = get_table()
    
    try:
        # First, check if user exists
        get_response = table.get_item(
            Key={
                'PK': f'USER#{user_id}',
                'SK': 'METADATA'
            }
        )
        
        if 'Item' not in get_response:
            print(json.dumps({
                'level': 'WARN',
                'message': 'User not found',
                'userId': user_id
            }))
            return create_response(404, {'error': 'User not found'})
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'Deleting user',
            'userId': user_id
        }))
        
        # Delete the user's metadata record
        table.delete_item(
            Key={
                'PK': f'USER#{user_id}',
                'SK': 'METADATA'
            }
        )
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'User deleted successfully',
            'userId': user_id
        }))
        
        # Return 204 No Content (standard for successful DELETE)
        return {
            'statusCode': 204,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,Authorization',
                'Access-Control-Allow-Methods': 'DELETE,OPTIONS'
            }
        }
        
    except ClientError as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'DynamoDB error',
            'error': str(e),
            'userId': user_id
        }))
        return create_response(500, {'error': 'Could not delete user'})

