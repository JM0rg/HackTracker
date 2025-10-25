"""
Query Teams Lambda Handler

API Gateway handler to query/list teams with various filters.
Supports:
- GET /teams - List all teams (paginated, uses GSI2)
- GET /teams?userId=x - List teams user is member of
- GET /teams?ownerId=x - List teams owned by user
"""

import json
import sys
from pathlib import Path

# Add utils to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from botocore.exceptions import ClientError
from boto3.dynamodb.conditions import Key
from utils import get_table, create_response


def format_team(item):
    """Format team item for response (remove internal keys)"""
    team = {
        'teamId': item['teamId'],
        'name': item['name'],
        'ownerId': item['ownerId'],
        'status': item['status'],
        'createdAt': item['createdAt']
    }
    
    # Add optional fields
    if 'description' in item and item['description']:
        team['description'] = item['description']
    
    if 'updatedAt' in item:
        team['updatedAt'] = item['updatedAt']
    
    return team


def list_all_teams(table, limit=50, next_token=None):
    """List all teams with pagination using GSI2 (entity listing)"""
    query_params = {
        'IndexName': 'GSI2',
        'KeyConditionExpression': Key('GSI2PK').eq('ENTITY#TEAM'),
        'Limit': limit
    }
    
    if next_token:
        query_params['ExclusiveStartKey'] = json.loads(next_token)
    
    response = table.query(**query_params)
    
    # Filter out deleted teams
    items = [item for item in response.get('Items', []) if item.get('status') != 'deleted']
    
    return {
        'items': items,
        'nextToken': json.dumps(response['LastEvaluatedKey']) if 'LastEvaluatedKey' in response else None
    }


def list_teams_by_owner(table, owner_id, limit=50):
    """List teams owned by specific user (client-side filter on GSI2 results)"""
    # Query all teams from GSI2
    query_params = {
        'IndexName': 'GSI2',
        'KeyConditionExpression': Key('GSI2PK').eq('ENTITY#TEAM'),
        'Limit': 100  # Get more to filter
    }
    
    response = table.query(**query_params)
    
    # Filter by owner and status
    items = [
        item for item in response.get('Items', [])
        if item.get('ownerId') == owner_id and item.get('status') != 'deleted'
    ]
    
    # Apply limit after filtering
    items = items[:limit]
    
    return {
        'items': items,
        'nextToken': None  # Simplified: no pagination for filtered results
    }


def list_user_teams(table, user_id):
    """List teams user is a member of (query user memberships)"""
    # Query user's team memberships
    response = table.query(
        KeyConditionExpression=Key('PK').eq(f'USER#{user_id}') & Key('SK').begins_with('TEAM#')
    )
    
    memberships = response.get('Items', [])
    
    # Fetch team details for each membership
    teams = []
    for membership in memberships:
        if membership.get('status') != 'active':
            continue
        
        team_id = membership['teamId']
        
        # Get team details
        team_response = table.get_item(
            Key={
                'PK': f'TEAM#{team_id}',
                'SK': 'METADATA'
            }
        )
        
        if 'Item' in team_response:
            team = team_response['Item']
            if team.get('status') != 'deleted':
                team_data = format_team(team)
                # Add user's role in this team
                team_data['role'] = membership.get('role')
                teams.append(team_data)
    
    return {
        'items': teams,
        'nextToken': None
    }


def handler(event, context):
    """
    Lambda handler for GET /teams with query parameters
    
    Args:
        event: API Gateway event
        context: Lambda context
        
    Returns:
        API Gateway response
    """
    print(json.dumps({
        'level': 'INFO',
        'message': 'Processing query teams request',
        'httpMethod': event.get('requestContext', {}).get('http', {}).get('method'),
        'path': event.get('requestContext', {}).get('http', {}).get('path')
    }))
    
    try:
        # Extract query parameters
        query_params = event.get('queryStringParameters') or {}
        user_id = query_params.get('userId')
        owner_id = query_params.get('ownerId')
        limit = int(query_params.get('limit', 50))
        next_token = query_params.get('nextToken')
        
        table = get_table()
        
        # Query by user membership
        if user_id:
            print(json.dumps({
                'level': 'INFO',
                'message': 'Querying teams by user membership',
                'userId': user_id
            }))
            
            result = list_user_teams(table, user_id)
            
            response_body = {
                'teams': result['items'],
                'count': len(result['items'])
            }
            
            return create_response(200, response_body)
        
        # Query by owner
        if owner_id:
            print(json.dumps({
                'level': 'INFO',
                'message': 'Querying teams by owner',
                'ownerId': owner_id
            }))
            
            result = list_teams_by_owner(table, owner_id, limit)
            
            response_body = {
                'teams': [format_team(item) for item in result['items']],
                'count': len(result['items'])
            }
            
            return create_response(200, response_body)
        
        # List all teams (default)
        print(json.dumps({
            'level': 'INFO',
            'message': 'Listing all teams',
            'limit': limit
        }))
        
        result = list_all_teams(table, limit, next_token)
        
        response_body = {
            'teams': [format_team(item) for item in result['items']],
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
        return create_response(500, {'error': 'Internal server error'})
        
    except Exception as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'Unexpected error',
            'error': str(e)
        }))
        return create_response(500, {'error': 'Internal server error'})

