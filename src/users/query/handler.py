"""
Query Users Lambda Handler

API Gateway handler to query/list users with various filters
Supports:
- GET /users - List all users (paginated, uses GSI2)
- GET /users?cognitoSub=x - Query by Cognito sub (GSI1)

Note: Email and team queries removed per architecture:
- Email lookup: Use Cognito ListUsers API instead
- Team lookup: GSI3 repurposed for geographic search
"""

import json
import sys
from pathlib import Path

# Add utils to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from botocore.exceptions import ClientError
from boto3.dynamodb.conditions import Key
from utils import get_table, create_response


def format_user(item):
    """Format user item for response (remove internal keys)"""
    user = {
        'userId': item['userId'],  # userId is the Cognito sub
        'email': item['email'],
        'firstName': item['firstName'],
        'lastName': item['lastName'],
        'createdAt': item['createdAt'],
        'updatedAt': item['updatedAt']
    }
    
    # Add optional fields
    if 'phoneNumber' in item:
        user['phoneNumber'] = item['phoneNumber']
    
    return user


# Email query removed - GSI2 repurposed for entity listing
# Use Cognito ListUsers API for email-based lookups instead


def query_by_cognito_sub(table, cognito_sub):
    """Query user by Cognito sub using GSI1"""
    response = table.query(
        IndexName='GSI1',
        KeyConditionExpression=Key('GSI1PK').eq(f'COGNITO#{cognito_sub}')
    )
    
    items = response.get('Items', [])
    return items[0] if items else None


# Team query removed - GSI3 repurposed for geographic search
# Team membership queries will use USER#id → TEAM#* pattern instead


def list_all_users(table, limit=50, next_token=None):
    """List all users with pagination using GSI2 (entity listing)"""
    query_params = {
        'IndexName': 'GSI2',
        'KeyConditionExpression': Key('GSI2PK').eq('ENTITY#USER'),
        'Limit': limit
    }
    
    if next_token:
        query_params['ExclusiveStartKey'] = json.loads(next_token)
    
    response = table.query(**query_params)
    
    return {
        'items': response.get('Items', []),
        'nextToken': json.dumps(response['LastEvaluatedKey']) if 'LastEvaluatedKey' in response else None
    }


def handler(event, context):
    """
    Lambda handler for GET /users with query parameters
    
    Args:
        event: API Gateway event
        context: Lambda context
        
    Returns:
        API Gateway response
    """
    print(json.dumps({
        'level': 'INFO',
        'message': 'Processing query users request',
        'httpMethod': event.get('httpMethod'),
        'path': event.get('path')
    }))
    
    try:
        # Extract query parameters
        query_params = event.get('queryStringParameters') or {}
        cognito_sub = query_params.get('cognitoSub')
        limit = int(query_params.get('limit', 50))
        next_token = query_params.get('nextToken')
        
        table = get_table()
        
        # Query by Cognito sub (single result)
        if cognito_sub:
            print(json.dumps({
                'level': 'INFO',
                'message': 'Querying by Cognito sub',
                'cognitoSub': cognito_sub
            }))
            
            user = query_by_cognito_sub(table, cognito_sub)
            
            if not user:
                return create_response(404, {
                    'error': 'User not found'
                })
            
            return create_response(200, format_user(user))
        
        # List all users (default)
        print(json.dumps({
            'level': 'INFO',
            'message': 'Listing all users',
            'limit': limit
        }))
        
        result = list_all_users(table, limit, next_token)
        
        response_body = {
            'users': [format_user(item) for item in result['items']],
            'count': len(result['items'])
        }
        
        if result['nextToken']:
            response_body['nextToken'] = result['nextToken']
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'Query completed successfully',
            'count': len(result['items'])
        }))
        
        return create_response(200, response_body)
        
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

