"""
Create Team Lambda Handler

API Gateway handler to create a new team with atomic transaction.
Creates both team record and owner membership in a single transaction.
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
from utils.validation import validate_team_name, validate_team_description
from utils.authorization import get_user_id_from_event


def handler(event, context):
    """
    Lambda handler for POST /teams
    
    Creates a team and assigns the creator as owner atomically.
    
    Args:
        event: API Gateway event
        context: Lambda context
        
    Returns:
        API Gateway response with new team data (201 Created)
    """
    print(json.dumps({
        'level': 'INFO',
        'message': 'Processing create team request',
        'httpMethod': event.get('requestContext', {}).get('http', {}).get('method'),
        'path': event.get('requestContext', {}).get('http', {}).get('path')
    }))
    
    try:
        # Extract user ID from request
        try:
            user_id = get_user_id_from_event(event)
        except ValueError as e:
            return create_response(401, {'error': str(e)})
        
        # Parse request body
        try:
            body = json.loads(event.get('body', '{}'))
        except json.JSONDecodeError:
            return create_response(400, {'error': 'Invalid JSON in request body'})
        
        # Validate required fields
        if not body.get('name'):
            return create_response(400, {'error': 'Team name is required'})
        
        # Validate and clean team name
        try:
            team_name = validate_team_name(body['name'])
        except ValueError as e:
            return create_response(400, {'error': str(e)})
        
        # Validate and clean description (optional)
        description = None
        if 'description' in body and body['description']:
            try:
                description = validate_team_description(body['description'])
            except ValueError as e:
                return create_response(400, {'error': str(e)})
        
        # Generate team ID
        team_id = str(uuid.uuid4())
        timestamp = datetime.now(timezone.utc).isoformat()
        
        # Prepare team record
        team_item = {
            'PK': f'TEAM#{team_id}',
            'SK': 'METADATA',
            'teamId': team_id,
            'name': team_name,
            'ownerId': user_id,
            'status': 'active',
            'createdAt': timestamp,
            'updatedAt': timestamp,
            'GSI2PK': 'ENTITY#TEAM',
            'GSI2SK': f'METADATA#{team_id}'
        }
        
        # Add description if provided
        if description:
            team_item['description'] = description
        
        # Prepare owner membership record
        membership_item = {
            'PK': f'USER#{user_id}',
            'SK': f'TEAM#{team_id}',
            'teamId': team_id,
            'userId': user_id,
            'role': 'team-owner',
            'status': 'active',
            'joinedAt': timestamp,
            'invitedBy': None  # Self-created, no inviter
        }
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'Creating team with transaction',
            'teamId': team_id,
            'teamName': team_name,
            'ownerId': user_id
        }))
        
        # Execute atomic transaction
        table = get_table()
        try:
            table.meta.client.transact_write_items(
                TransactItems=[
                    {
                        'Put': {
                            'TableName': table.name,
                            'Item': team_item,
                            'ConditionExpression': 'attribute_not_exists(PK)'
                        }
                    },
                    {
                        'Put': {
                            'TableName': table.name,
                            'Item': membership_item,
                            'ConditionExpression': 'attribute_not_exists(PK) AND attribute_not_exists(SK)'
                        }
                    }
                ]
            )
        except ClientError as e:
            if e.response['Error']['Code'] == 'TransactionCanceledException':
                print(json.dumps({
                    'level': 'ERROR',
                    'message': 'Transaction cancelled - team or membership already exists',
                    'teamId': team_id,
                    'userId': user_id
                }))
                return create_response(409, {'error': 'Team creation conflict'})
            raise
        
        # Build response
        response_data = {
            'teamId': team_id,
            'name': team_name,
            'ownerId': user_id,
            'role': 'team-owner',
            'status': 'active',
            'createdAt': timestamp,
            'updatedAt': timestamp
        }
        
        if description:
            response_data['description'] = description
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'Team created successfully',
            'teamId': team_id,
            'teamName': team_name
        }))
        
        return create_response(201, response_data)
        
    except ClientError as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'DynamoDB error',
            'error': str(e)
        }))
        return create_response(500, {'error': 'Could not create team'})
        
    except Exception as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'Unexpected error',
            'error': str(e)
        }))
        return create_response(500, {'error': 'Internal server error'})

