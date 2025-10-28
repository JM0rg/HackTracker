"""
Get Team Lambda Handler

API Gateway handler to retrieve a single team by teamId
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
    Lambda handler for GET /teams/{teamId}
    
    Args:
        event: API Gateway event
        context: Lambda context
        
    Returns:
        API Gateway response with team data
    """
    print(json.dumps({
        'level': 'INFO',
        'message': 'Processing get team request',
        'httpMethod': event.get('requestContext', {}).get('http', {}).get('method'),
        'path': event.get('requestContext', {}).get('http', {}).get('path')
    }))
    
    try:
        # Extract teamId from path parameters
        path_params = event.get('pathParameters', {})
        team_id = path_params.get('teamId')
        
        if not team_id:
            return create_response(400, {'error': 'Missing teamId in path'})
        
        # Get team from DynamoDB
        table = get_table()
        response = table.get_item(
            Key={
                'PK': f'TEAM#{team_id}',
                'SK': 'METADATA'
            }
        )
        
        # Check if team exists
        if 'Item' not in response:
            print(json.dumps({
                'level': 'WARN',
                'message': 'Team not found',
                'teamId': team_id
            }))
            return create_response(404, {'error': 'Team not found'})
        
        team = response['Item']
        
        # Check if team is deleted
        if team.get('status') == 'deleted':
            print(json.dumps({
                'level': 'WARN',
                'message': 'Team is deleted',
                'teamId': team_id
            }))
            return create_response(404, {'error': 'Team not found'})
        
        # Format response (remove internal keys)
        team_response = {
            'teamId': team['teamId'],
            'name': team['name'],
            'ownerId': team['ownerId'],
            'status': team['status'],
            'createdAt': team['createdAt'],
            'updatedAt': team['updatedAt']
        }
        
        # Add optional fields
        if 'description' in team and team['description']:
            team_response['description'] = team['description']
        
        # Add team_type if present
        if 'team_type' in team:
            team_response['team_type'] = team['team_type']
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'Team retrieved successfully',
            'teamId': team_id
        }))
        
        return create_response(200, team_response)
        
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

