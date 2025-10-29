"""
User Context Lambda Handler

API Gateway handler to return user's team context for dynamic UI rendering.
Returns whether user has personal teams (including "Default") and managed teams.
"""

import json
import sys
from pathlib import Path

# Add utils to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from botocore.exceptions import ClientError
from boto3.dynamodb.conditions import Key
from utils import get_table, create_response
from utils.authorization import get_user_id_from_event


def handler(event, context):
    """
    Lambda handler for GET /users/context
    
    Returns user's team context for dynamic UI rendering:
    - has_personal_context: True if user owns/is member of any PERSONAL teams (including "Default")
    - has_managed_context: True if user is member of any MANAGED teams
    
    Args:
        event: API Gateway event
        context: Lambda context
        
    Returns:
        API Gateway response with user context (200 OK)
    """
    print(json.dumps({
        'level': 'INFO',
        'message': 'Processing get user context request',
        'httpMethod': event.get('requestContext', {}).get('http', {}).get('method'),
        'path': event.get('requestContext', {}).get('http', {}).get('path')
    }))
    
    try:
        # Extract user ID from JWT
        try:
            user_id = get_user_id_from_event(event)
        except ValueError as e:
            return create_response(401, {'error': str(e)})
        
        table = get_table()
        
        # Query user's team memberships
        response = table.query(
            KeyConditionExpression=Key('PK').eq(f'USER#{user_id}') & Key('SK').begins_with('TEAM#')
        )
        
        memberships = response.get('Items', [])
        
        has_personal_context = False
        has_managed_context = False
        
        # Check each team membership
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
                # Skip deleted teams
                if team.get('status') == 'deleted':
                    continue
                
                team_type = team.get('team_type', 'MANAGED')
                
                if team_type == 'PERSONAL':
                    has_personal_context = True
                elif team_type == 'MANAGED':
                    has_managed_context = True
                
                # Early exit if both are true
                if has_personal_context and has_managed_context:
                    break
        
        response_data = {
            'has_personal_context': has_personal_context,
            'has_managed_context': has_managed_context
        }
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'User context retrieved successfully',
            'userId': user_id,
            'hasPersonalContext': has_personal_context,
            'hasManagedContext': has_managed_context
        }))
        
        return create_response(200, response_data)
        
    except ClientError as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'DynamoDB error',
            'error': str(e)
        }))
        return create_response(500, {'error': 'Could not retrieve user context'})
        
    except Exception as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'Unexpected error',
            'error': str(e),
            'errorType': type(e).__name__
        }))
        return create_response(500, {'error': 'Internal server error'})

