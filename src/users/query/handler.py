"""
Query Users Lambda Handler

API Gateway handler to query/list users with various filters
Supports:
- GET /users - List all users (paginated)
- GET /users?email=x - Query by email (GSI2)
- GET /users?cognitoSub=x - Query by Cognito sub (GSI1)
- GET /users?teamId=x - Query by team (GSI3)
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
        'userId': item['userId'],
        'email': item['email'],
        'firstName': item['firstName'],
        'lastName': item['lastName'],
        'cognitoSub': item['cognitoSub'],
        'createdAt': item['createdAt'],
        'updatedAt': item['updatedAt']
    }
    
    # Add optional fields
    if 'phoneNumber' in item:
        user['phoneNumber'] = item['phoneNumber']
    
    return user


def query_by_email(table, email):
    """Query user by email using GSI2"""
    response = table.query(
        IndexName='GSI2',
        KeyConditionExpression=Key('GSI2PK').eq(f'EMAIL#{email.lower()}')
    )
    
    items = response.get('Items', [])
    return items[0] if items else None


def query_by_cognito_sub(table, cognito_sub):
    """Query user by Cognito sub using GSI1"""
    response = table.query(
        IndexName='GSI1',
        KeyConditionExpression=Key('GSI1PK').eq(f'COGNITO#{cognito_sub}')
    )
    
    items = response.get('Items', [])
    return items[0] if items else None


def query_by_team(table, team_id, limit=50, next_token=None):
    """Query users by team using GSI3"""
    query_params = {
        'IndexName': 'GSI3',
        'KeyConditionExpression': Key('GSI3PK').eq(f'TEAM#{team_id}'),
        'Limit': limit
    }
    
    if next_token:
        query_params['ExclusiveStartKey'] = json.loads(next_token)
    
    response = table.query(**query_params)
    
    return {
        'items': response.get('Items', []),
        'nextToken': json.dumps(response['LastEvaluatedKey']) if 'LastEvaluatedKey' in response else None
    }


def list_all_users(table, limit=50, next_token=None):
    """List all users with pagination"""
    scan_params = {
        'FilterExpression': 'begins_with(PK, :pk) AND SK = :sk',
        'ExpressionAttributeValues': {
            ':pk': 'USER#',
            ':sk': 'METADATA'
        },
        'Limit': limit
    }
    
    if next_token:
        scan_params['ExclusiveStartKey'] = json.loads(next_token)
    
    response = table.scan(**scan_params)
    
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
        email = query_params.get('email')
        cognito_sub = query_params.get('cognitoSub')
        team_id = query_params.get('teamId')
        limit = int(query_params.get('limit', 50))
        next_token = query_params.get('nextToken')
        
        table = get_table()
        
        # Query by email (single result)
        if email:
            print(json.dumps({
                'level': 'INFO',
                'message': 'Querying by email',
                'email': email
            }))
            
            user = query_by_email(table, email)
            
            if not user:
                return create_response(404, {
                    'error': 'User not found'
                })
            
            return create_response(200, format_user(user))
        
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
        
        # Query by team (multiple results)
        if team_id:
            print(json.dumps({
                'level': 'INFO',
                'message': 'Querying by team',
                'teamId': team_id
            }))
            
            result = query_by_team(table, team_id, limit, next_token)
            
            response_body = {
                'users': [format_user(item) for item in result['items']],
                'count': len(result['items'])
            }
            
            if result['nextToken']:
                response_body['nextToken'] = result['nextToken']
            
            return create_response(200, response_body)
        
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

