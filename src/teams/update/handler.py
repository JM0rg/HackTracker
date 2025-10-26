"""
Update Team Lambda Handler

API Gateway handler to update team information.
Only allows team-owner and team-coach to update.
Only allows updating specific fields (name, description).
"""

import json
import sys
from pathlib import Path
from datetime import datetime, timezone

# Add utils to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from botocore.exceptions import ClientError
from utils import get_table, create_response
from utils.validation import validate_team_name, validate_team_description
from utils.authorization import get_user_id_from_event, authorize, PermissionError

# Fields that are allowed to be updated
ALLOWED_FIELDS = {'name', 'description'}

# Fields that are read-only (cannot be updated)
READONLY_FIELDS = {'teamId', 'ownerId', 'status', 'createdAt', 'updatedAt', 'deletedAt', 'recoveryToken', 'PK', 'SK', 'GSI1PK', 'GSI1SK', 'GSI2PK', 'GSI2SK', 'GSI3PK', 'GSI3SK', 'GSI4PK', 'GSI4SK', 'GSI5PK', 'GSI5SK'}


def handler(event, context):
    """
    Lambda handler for PUT /teams/{teamId}
    
    Allows updating: name, description
    Requires: team-owner or team-coach role
    Automatically updates: updatedAt
    Read-only: teamId, ownerId, status, createdAt, GSI*
    
    Args:
        event: API Gateway event
        context: Lambda context
        
    Returns:
        API Gateway response with updated team data
    """
    print(json.dumps({
        'level': 'INFO',
        'message': 'Processing update team request',
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
    
    # Parse request body
    try:
        body = json.loads(event.get('body', '{}'))
    except json.JSONDecodeError:
        return create_response(400, {'error': 'Invalid JSON in request body'})
    
    if not body:
        return create_response(400, {'error': 'Request body is required'})
    
    # Validate fields - check for readonly fields
    readonly_attempted = set(body.keys()) & READONLY_FIELDS
    if readonly_attempted:
        return create_response(400, {
            'error': 'Cannot update read-only fields',
            'readOnlyFields': list(readonly_attempted)
        })
    
    # Validate fields - check for unknown fields
    unknown_fields = set(body.keys()) - ALLOWED_FIELDS
    if unknown_fields:
        return create_response(400, {
            'error': 'Invalid fields in request',
            'invalidFields': list(unknown_fields),
            'allowedFields': list(ALLOWED_FIELDS)
        })
    
    # Check if there are any fields to update
    if not body:
        return create_response(400, {'error': 'No valid fields to update'})
    
    table = get_table()
    
    try:
        # Check authorization: can user manage this team?
        try:
            authorize(table, user_id, team_id, action='manage_team')
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
        
        # Check if team is deleted
        if team.get('status') == 'deleted':
            return create_response(404, {'error': 'Team not found'})
        
        # Build update expression
        update_expression_parts = []
        expression_attribute_names = {}
        expression_attribute_values = {}
        
        # Add updatedAt timestamp
        update_expression_parts.append('#updatedAt = :updatedAt')
        expression_attribute_names['#updatedAt'] = 'updatedAt'
        expression_attribute_values[':updatedAt'] = datetime.now(timezone.utc).isoformat()
        
        # Validate and add user-provided fields
        for field, value in body.items():
            if field in ALLOWED_FIELDS:
                # Validate name
                if field == 'name':
                    try:
                        value = validate_team_name(value)
                    except ValueError as e:
                        return create_response(400, {'error': str(e)})
                
                # Validate description
                elif field == 'description':
                    try:
                        value = validate_team_description(value)
                    except ValueError as e:
                        return create_response(400, {'error': str(e)})
                    
                    # If description is None/empty, remove it from the item
                    if value is None:
                        # Use REMOVE instead of SET for null values
                        if 'description' in team:
                            update_expression_parts.append(f'#{field}')
                            expression_attribute_names[f'#{field}'] = field
                        continue
                
                update_expression_parts.append(f'#{field} = :{field}')
                expression_attribute_names[f'#{field}'] = field
                expression_attribute_values[f':{field}'] = value
        
        # Construct update expression
        set_parts = [part for part in update_expression_parts if ' = ' in part]
        remove_parts = [part for part in update_expression_parts if ' = ' not in part]
        
        update_expression = ''
        if set_parts:
            update_expression = 'SET ' + ', '.join(set_parts)
        if remove_parts:
            if update_expression:
                update_expression += ' '
            update_expression += 'REMOVE ' + ', '.join(remove_parts)
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'Updating team',
            'teamId': team_id,
            'userId': user_id,
            'fields': list(body.keys())
        }))
        
        # Update the item
        update_params = {
            'Key': {
                'PK': f'TEAM#{team_id}',
                'SK': 'METADATA'
            },
            'UpdateExpression': update_expression,
            'ExpressionAttributeNames': expression_attribute_names,
            'ReturnValues': 'ALL_NEW'
        }
        
        if expression_attribute_values:
            update_params['ExpressionAttributeValues'] = expression_attribute_values
        
        response = table.update_item(**update_params)
        
        updated_item = response['Attributes']
        
        # Format response (remove internal DynamoDB keys)
        team_data = {
            'teamId': updated_item.get('teamId'),
            'name': updated_item.get('name'),
            'ownerId': updated_item.get('ownerId'),
            'status': updated_item.get('status'),
            'createdAt': updated_item.get('createdAt'),
            'updatedAt': updated_item.get('updatedAt')
        }
        
        # Add optional description
        if 'description' in updated_item and updated_item['description']:
            team_data['description'] = updated_item['description']
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'Team updated successfully',
            'teamId': team_id
        }))
        
        return create_response(200, team_data)
        
    except ClientError as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'DynamoDB error',
            'error': str(e),
            'teamId': team_id
        }))
        return create_response(500, {'error': 'Could not update team'})
    
    except Exception as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'Unexpected error',
            'error': str(e),
            'teamId': team_id
        }))
        return create_response(500, {'error': 'Internal server error'})

