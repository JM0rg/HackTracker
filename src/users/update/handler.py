"""
Update User Lambda Handler

API Gateway handler to update user information
Only allows updating specific fields (firstName, lastName, phoneNumber)
Automatically updates the updatedAt timestamp
"""

import json
import sys
from pathlib import Path
from datetime import datetime, timezone

# Add utils to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from botocore.exceptions import ClientError
from utils import get_table, create_response

# Fields that users are allowed to update
ALLOWED_FIELDS = {'firstName', 'lastName', 'phoneNumber'}

# Fields that are read-only (cannot be updated)
READONLY_FIELDS = {'userId', 'email', 'createdAt', 'updatedAt', 'PK', 'SK', 'GSI1PK', 'GSI1SK', 'GSI2PK', 'GSI2SK', 'GSI3PK', 'GSI3SK', 'GSI4PK', 'GSI4SK', 'GSI5PK', 'GSI5SK'}


def handler(event, context):
    """
    Lambda handler for PUT /users/{userId}
    
    Allows updating: firstName, lastName, phoneNumber
    Automatically updates: updatedAt
    Read-only: userId, email, createdAt, PK, SK, GSI*
    
    Args:
        event: API Gateway event (v2.0 format)
        context: Lambda context
        
    Returns:
        API Gateway response with updated user data
    """
    print(json.dumps({
        'level': 'INFO',
        'message': 'Processing update user request',
        'httpMethod': event.get('requestContext', {}).get('http', {}).get('method'),
        'path': event.get('requestContext', {}).get('http', {}).get('path')
    }))
    
    # Get userId from path parameters
    user_id = event.get('pathParameters', {}).get('userId')
    if not user_id:
        return create_response(400, {'error': 'Missing userId in path'})
    
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
        
        # Build update expression
        update_expression_parts = []
        expression_attribute_names = {}
        expression_attribute_values = {}
        
        # Add updatedAt timestamp
        update_expression_parts.append('#updatedAt = :updatedAt')
        expression_attribute_names['#updatedAt'] = 'updatedAt'
        expression_attribute_values[':updatedAt'] = datetime.now(timezone.utc).isoformat()
        
        # Add user-provided fields
        for field, value in body.items():
            if field in ALLOWED_FIELDS:
                # Validate field values
                if field in ['firstName', 'lastName']:
                    if not isinstance(value, str) or not value.strip():
                        return create_response(400, {
                            'error': f'{field} must be a non-empty string'
                        })
                elif field == 'phoneNumber':
                    if value is not None and (not isinstance(value, str) or not value.strip()):
                        return create_response(400, {
                            'error': 'phoneNumber must be a non-empty string or null'
                        })
                
                update_expression_parts.append(f'#{field} = :{field}')
                expression_attribute_names[f'#{field}'] = field
                expression_attribute_values[f':{field}'] = value
        
        update_expression = 'SET ' + ', '.join(update_expression_parts)
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'Updating user',
            'userId': user_id,
            'fields': list(body.keys())
        }))
        
        # Update the item
        response = table.update_item(
            Key={
                'PK': f'USER#{user_id}',
                'SK': 'METADATA'
            },
            UpdateExpression=update_expression,
            ExpressionAttributeNames=expression_attribute_names,
            ExpressionAttributeValues=expression_attribute_values,
            ReturnValues='ALL_NEW'
        )
        
        updated_item = response['Attributes']
        
        # Format response (remove internal DynamoDB keys)
        user_data = {
            'userId': updated_item.get('userId'),  # userId is the Cognito sub
            'email': updated_item.get('email'),
            'firstName': updated_item.get('firstName'),
            'lastName': updated_item.get('lastName'),
            'phoneNumber': updated_item.get('phoneNumber'),
            'createdAt': updated_item.get('createdAt'),
            'updatedAt': updated_item.get('updatedAt')
        }
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'User updated successfully',
            'userId': user_id
        }))
        
        return create_response(200, user_data)
        
    except ClientError as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'DynamoDB error',
            'error': str(e),
            'userId': user_id
        }))
        return create_response(500, {'error': 'Could not update user'})

