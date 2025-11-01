"""
Create AtBat Lambda Handler

API Gateway handler to create a new at-bat for a game.
Records individual plate appearance with result, location, and optional details.
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
from utils.validation import (
    validate_atbat_result,
    validate_hit_location,
    validate_hit_type,
    validate_inning,
    validate_outs,
    validate_rbis
)
from utils.authorization import get_user_id_from_event, authorize, PermissionError


def handler(event, context):
    """
    Lambda handler for POST /games/{gameId}/atbats
    
    Creates a new at-bat for a game.
    Requires owner, manager, or scorekeeper role.
    Game must be IN_PROGRESS for MANAGED teams (PERSONAL teams don't require lineup).
    
    Args:
        event: API Gateway event
        context: Lambda context
        
    Returns:
        API Gateway response with new at-bat data (201 Created)
    """
    print(json.dumps({
        'level': 'INFO',
        'message': 'Processing create at-bat request',
        'httpMethod': event.get('requestContext', {}).get('http', {}).get('method'),
        'path': event.get('requestContext', {}).get('http', {}).get('path')
    }))
    
    try:
        # Extract user ID from JWT
        try:
            user_id = get_user_id_from_event(event)
        except ValueError as e:
            return create_response(401, {'error': str(e)})
        
        # Extract gameId from path parameters
        path_params = event.get('pathParameters', {})
        game_id = path_params.get('gameId')
        
        if not game_id:
            return create_response(400, {'error': 'gameId is required in path'})
        
        # Parse request body
        try:
            body = json.loads(event.get('body', '{}'))
        except json.JSONDecodeError:
            return create_response(400, {'error': 'Invalid JSON in request body'})
        
        # Validate required fields
        if 'playerId' not in body:
            return create_response(400, {'error': 'playerId is required'})
        
        if 'result' not in body:
            return create_response(400, {'error': 'result is required'})
        
        if 'inning' not in body:
            return create_response(400, {'error': 'inning is required'})
        
        if 'outs' not in body:
            return create_response(400, {'error': 'outs is required'})
        
        if 'battingOrder' not in body:
            return create_response(400, {'error': 'battingOrder is required'})
        
        player_id = body['playerId']
        
        # Get game from DynamoDB to extract teamId
        table = get_table()
        response = table.get_item(
            Key={
                'PK': f'GAME#{game_id}',
                'SK': 'METADATA'
            }
        )
        
        if 'Item' not in response:
            return create_response(404, {'error': 'Game not found'})
        
        game = response['Item']
        team_id = game['teamId']
        game_status = game.get('status')
        game_lineup = game.get('lineup', [])
        
        # Get team to check team type
        team_response = table.get_item(
            Key={
                'PK': f'TEAM#{team_id}',
                'SK': 'METADATA'
            }
        )
        
        if 'Item' not in team_response:
            return create_response(404, {'error': 'Team not found'})
        
        team = team_response['Item']
        team_type = team.get('team_type', 'MANAGED')
        
        # Authorize: check if user can manage at-bats for this team
        try:
            authorize(table, user_id, team_id, 'manage_atbats')
        except PermissionError as e:
            return create_response(403, {'error': str(e)})
        except ClientError as e:
            if e.response['Error']['Code'] == 'ResourceNotFoundException':
                return create_response(404, {'error': 'Team not found'})
            raise
        
        # Validate game status (must be IN_PROGRESS)
        if game_status != 'IN_PROGRESS':
            return create_response(400, {'error': 'Game must be IN_PROGRESS to record at-bats'})
        
        # For MANAGED teams, lineup must be set
        if team_type == 'MANAGED' and not game_lineup:
            return create_response(400, {'error': 'Game lineup must be set before recording at-bats'})
        
        # If lineup exists, validate player is in lineup
        if game_lineup:
            lineup_player_ids = [item['playerId'] for item in game_lineup if isinstance(item, dict) and 'playerId' in item]
            if player_id not in lineup_player_ids:
                return create_response(400, {'error': 'Player must be in game lineup to record at-bat'})
        
        # Validate required fields
        try:
            result = validate_atbat_result(body['result'])
            inning = validate_inning(body['inning'])
            outs = validate_outs(body['outs'])
            batting_order = int(body['battingOrder'])
            
            if batting_order < 1:
                return create_response(400, {'error': 'battingOrder must be 1 or greater'})
        except ValueError as e:
            return create_response(400, {'error': str(e)})
        
        # Validate optional fields
        hit_location = None
        if 'hitLocation' in body and body['hitLocation']:
            try:
                hit_location = validate_hit_location(body['hitLocation'])
            except ValueError as e:
                return create_response(400, {'error': str(e)})
        
        hit_type = None
        if 'hitType' in body and body['hitType']:
            try:
                hit_type = validate_hit_type(body['hitType'])
            except ValueError as e:
                return create_response(400, {'error': str(e)})
        
        rbis = None
        if 'rbis' in body:
            try:
                rbis = validate_rbis(body['rbis'])
            except ValueError as e:
                return create_response(400, {'error': str(e)})
        
        # Generate at-bat ID and timestamp
        atbat_id = str(uuid.uuid4())
        timestamp = datetime.now(timezone.utc).isoformat()
        
        # Prepare at-bat record
        atbat_item = {
            'PK': f'GAME#{game_id}',
            'SK': f'ATBAT#{atbat_id}',
            'atBatId': atbat_id,
            'gameId': game_id,
            'playerId': player_id,
            'teamId': team_id,
            'result': result,
            'inning': inning,
            'outs': outs,
            'battingOrder': batting_order,
            'createdAt': timestamp,
            'updatedAt': timestamp,
            'GSI5PK': f'PLAYER#{player_id}',
            'GSI5SK': f'ATBAT#{timestamp}'
        }
        
        # Add optional fields if provided
        if hit_location:
            atbat_item['hitLocation'] = hit_location
        
        if hit_type:
            atbat_item['hitType'] = hit_type
        
        if rbis is not None:
            atbat_item['rbis'] = rbis
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'Creating at-bat',
            'atBatId': atbat_id,
            'gameId': game_id,
            'playerId': player_id,
            'result': result
        }))
        
        # Create at-bat record
        try:
            table.put_item(
                Item=atbat_item,
                ConditionExpression='attribute_not_exists(PK) AND attribute_not_exists(SK)'
            )
        except ClientError as e:
            if e.response['Error']['Code'] == 'ConditionalCheckFailedException':
                print(json.dumps({
                    'level': 'ERROR',
                    'message': 'At-bat already exists',
                    'atBatId': atbat_id
                }))
                return create_response(409, {'error': 'At-bat already exists'})
            raise
        
        # Format response (remove internal DynamoDB keys)
        atbat_response = {
            'atBatId': atbat_id,
            'gameId': game_id,
            'playerId': player_id,
            'teamId': team_id,
            'result': result,
            'inning': inning,
            'outs': outs,
            'battingOrder': batting_order,
            'createdAt': timestamp,
            'updatedAt': timestamp
        }
        
        # Add optional fields to response if present
        if hit_location:
            atbat_response['hitLocation'] = hit_location
        if hit_type:
            atbat_response['hitType'] = hit_type
        if rbis is not None:
            atbat_response['rbis'] = rbis
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'At-bat created successfully',
            'atBatId': atbat_id
        }))
        
        return create_response(201, atbat_response)
        
    except ClientError as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'DynamoDB error',
            'error': str(e),
            'errorCode': e.response['Error']['Code']
        }))
        return create_response(500, {'error': 'Could not create at-bat'})
    
    except Exception as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'Unexpected error',
            'error': str(e),
            'type': type(e).__name__
        }))
        return create_response(500, {'error': 'Internal server error'})

