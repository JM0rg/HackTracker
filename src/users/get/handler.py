"""
Get User Lambda Handler

API Gateway handler to retrieve a single user by userId
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
    Lambda handler for GET /users/{userId}
    
    Args:
        event: API Gateway event
        context: Lambda context
        
    Returns:
        API Gateway response
    """
    print(json.dumps({
        'level': 'INFO',
        'message': 'Processing get user request',
        'httpMethod': event.get('httpMethod'),
        'path': event.get('path')
    }))
    
    try:
        # Extract userId from path parameters
        path_params = event.get('pathParameters', {})
        user_id = path_params.get('userId')
        
        if not user_id:
            return create_response(400, {
                'error': 'Missing userId in path'
            })
        
        # Get user from DynamoDB
        table = get_table()
        response = table.get_item(
            Key={
                'PK': f'USER#{user_id}',
                'SK': 'METADATA'
            }
        )
        
        # Check if user exists
        if 'Item' not in response:
            print(json.dumps({
                'level': 'WARN',
                'message': 'User not found',
                'userId': user_id
            }))
            return create_response(404, {
                'error': 'User not found'
            })
        
        user = response['Item']
        
        # Format response (remove internal keys)
        user_response = {
            'userId': user['userId'],  # userId is the Cognito sub
            'email': user['email'],
            'firstName': user['firstName'],
            'lastName': user['lastName'],
            'createdAt': user['createdAt'],
            'updatedAt': user['updatedAt']
        }
        
        # Add optional fields
        if 'phoneNumber' in user:
            user_response['phoneNumber'] = user['phoneNumber']
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'User retrieved successfully',
            'userId': user_id
        }))
        
        return create_response(200, user_response)
        
    except ClientError as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'DynamoDB error',
            'error': str(e)
        }))
        return create_response(500, {
            'error': 'Internal server error'
        })
        
    except Exception as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'Unexpected error',
            'error': str(e)
        }))
        return create_response(500, {
            'error': 'Internal server error'
        })

