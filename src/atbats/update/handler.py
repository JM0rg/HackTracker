"""
Update AtBat Lambda Handler

API Gateway handler to update an existing at-bat.
Allows editing result, location, and optional details after recording.
"""

import json
import sys
from pathlib import Path
from datetime import datetime, timezone

# Add utils to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from botocore.exceptions import ClientError
from utils import get_table, create_response
from utils.validation import (
    validate_atbat_result,
    validate_hit_location,
    validate_hit_type,
    validate_inning,
    validate_outs,
    validate_rbis
)
from utils.authorization import get_user_id_from_event, authorize, PermissionError

# Fields that are allowed to be updated
ALLOWED_FIELDS = {'result', 'hitLocation', 'hitType', 'rbis', 'inning', 'outs'}

# Fields that are read-only (cannot be updated)
READONLY_FIELDS = {'atBatId', 'gameId', 'playerId', 'teamId', 'battingOrder', 'createdAt', 'updatedAt', 'PK', 'SK', 'GSI5PK', 'GSI5SK'}


def handler(event, context):
    """
    Lambda handler for PUT /games/{gameId}/atbats/{atBatId}
    
    Allows updating: result, hitLocation, hitType, rbis, inning, outs
    Requires: owner, manager, or scorekeeper role
    Automatically updates: updatedAt
    Read-only: atBatId, gameId, playerId, teamId, battingOrder, createdAt, GSI*
    
    Args:
        event: API Gateway event
        context: Lambda context
        
    Returns:
        API Gateway response with updated at-bat data (200 OK)
    """
    print(json.dumps({
        'level': 'INFO',
        'message': 'Processing update at-bat request',
        'httpMethod': event.get('requestContext', {}).get('http', {}).get('method'),
        'path': event.get('requestContext', {}).get('http', {}).get('path')
    }))
    
    # Extract path parameters
    path_params = event.get('pathParameters', {})
    game_id = path_params.get('gameId')
    atbat_id = path_params.get('atBatId')
    
    if not game_id:
        return create_response(400, {'error': 'Missing gameId in path'})
    
    if not atbat_id:
        return create_response(400, {'error': 'Missing atBatId in path'})
    
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
        return create_response(400, {'error': 'Request body cannot be empty'})
    
    # Check for read-only fields in request
    readonly_in_request = [field for field in body.keys() if field in READONLY_FIELDS]
    if readonly_in_request:
        return create_response(400, {
            'error': f'Cannot update read-only fields: {", ".join(readonly_in_request)}'
        })
    
    # Get at-bat from DynamoDB
    table = get_table()
    
    try:
        response = table.get_item(
            Key={
                'PK': f'GAME#{game_id}',
                'SK': f'ATBAT#{atbat_id}'
            }
        )
        
        if 'Item' not in response:
            return create_response(404, {'error': 'At-bat not found'})
        
        atbat = response['Item']
        team_id = atbat['teamId']
        
        # Authorize: check if user can manage at-bats for this team
        try:
            authorize(table, user_id, team_id, 'manage_atbats')
        except PermissionError as e:
            return create_response(403, {'error': str(e)})
        except ClientError as e:
            if e.response['Error']['Code'] == 'ResourceNotFoundException':
                return create_response(404, {'error': 'Team not found'})
            raise
        
        # Build update expression
        update_parts = []
        expression_values = {}
        expression_names = {}
        
        # Validate and add fields to update
        if 'result' in body:
            try:
                result = validate_atbat_result(body['result'])
                update_parts.append('#result = :result')
                expression_values[':result'] = result
                expression_names['#result'] = 'result'
            except ValueError as e:
                return create_response(400, {'error': str(e)})
        
        if 'hitLocation' in body:
            # Allow null to remove hitLocation
            if body['hitLocation'] is None:
                update_parts.append('REMOVE hitLocation')
            else:
                try:
                    hit_location = validate_hit_location(body['hitLocation'])
                    update_parts.append('hitLocation = :hitLocation')
                    expression_values[':hitLocation'] = hit_location
                except ValueError as e:
                    return create_response(400, {'error': str(e)})
        
        if 'hitType' in body:
            # Allow null to remove hitType
            if body['hitType'] is None or body['hitType'] == '':
                update_parts.append('REMOVE hitType')
            else:
                try:
                    hit_type = validate_hit_type(body['hitType'])
                    update_parts.append('hitType = :hitType')
                    expression_values[':hitType'] = hit_type
                except ValueError as e:
                    return create_response(400, {'error': str(e)})
        
        if 'rbis' in body:
            # Allow null to remove rbis
            if body['rbis'] is None:
                update_parts.append('REMOVE rbis')
            else:
                try:
                    rbis = validate_rbis(body['rbis'])
                    update_parts.append('rbis = :rbis')
                    expression_values[':rbis'] = rbis
                except ValueError as e:
                    return create_response(400, {'error': str(e)})
        
        if 'inning' in body:
            try:
                inning = validate_inning(body['inning'])
                update_parts.append('inning = :inning')
                expression_values[':inning'] = inning
            except ValueError as e:
                return create_response(400, {'error': str(e)})
        
        if 'outs' in body:
            try:
                outs = validate_outs(body['outs'])
                update_parts.append('outs = :outs')
                expression_values[':outs'] = outs
            except ValueError as e:
                return create_response(400, {'error': str(e)})
        
        # Always update timestamp
        timestamp = datetime.now(timezone.utc).isoformat()
        update_parts.append('updatedAt = :updatedAt')
        expression_values[':updatedAt'] = timestamp
        
        # Construct final update expression
        if not update_parts:
            return create_response(400, {'error': 'No valid fields to update'})
        
        # Separate SET and REMOVE clauses
        set_parts = [p for p in update_parts if not p.startswith('REMOVE')]
        remove_parts = [p.replace('REMOVE ', '') for p in update_parts if p.startswith('REMOVE')]
        
        update_expression = ''
        if set_parts:
            update_expression += 'SET ' + ', '.join(set_parts)
        if remove_parts:
            if update_expression:
                update_expression += ' '
            update_expression += 'REMOVE ' + ', '.join(remove_parts)
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'Updating at-bat',
            'atBatId': atbat_id,
            'gameId': game_id,
            'fieldsToUpdate': list(body.keys())
        }))
        
        # Update at-bat
        update_params = {
            'Key': {
                'PK': f'GAME#{game_id}',
                'SK': f'ATBAT#{atbat_id}'
            },
            'UpdateExpression': update_expression,
            'ReturnValues': 'ALL_NEW'
        }
        
        if expression_values:
            update_params['ExpressionAttributeValues'] = expression_values
        if expression_names:
            update_params['ExpressionAttributeNames'] = expression_names
        
        updated_response = table.update_item(**update_params)
        updated_atbat = updated_response['Attributes']
        
        # Format response (remove internal DynamoDB keys)
        atbat_response = {
            'atBatId': updated_atbat['atBatId'],
            'gameId': updated_atbat['gameId'],
            'playerId': updated_atbat['playerId'],
            'teamId': updated_atbat['teamId'],
            'result': updated_atbat['result'],
            'inning': updated_atbat['inning'],
            'outs': updated_atbat['outs'],
            'battingOrder': updated_atbat['battingOrder'],
            'createdAt': updated_atbat['createdAt'],
            'updatedAt': updated_atbat['updatedAt']
        }
        
        # Add optional fields if present
        if 'hitLocation' in updated_atbat:
            atbat_response['hitLocation'] = updated_atbat['hitLocation']
        if 'hitType' in updated_atbat:
            atbat_response['hitType'] = updated_atbat['hitType']
        if 'rbis' in updated_atbat:
            atbat_response['rbis'] = updated_atbat['rbis']
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'At-bat updated successfully',
            'atBatId': atbat_id
        }))
        
        return create_response(200, atbat_response)
        
    except ClientError as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'DynamoDB error',
            'error': str(e),
            'errorCode': e.response['Error']['Code']
        }))
        return create_response(500, {'error': 'Could not update at-bat'})
    
    except Exception as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'Unexpected error',
            'error': str(e),
            'type': type(e).__name__
        }))
        return create_response(500, {'error': 'Internal server error'})

