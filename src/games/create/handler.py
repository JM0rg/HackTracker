"""
Create Game Lambda Handler

API Gateway handler to create a new game.
Creates standalone game record with optional season reference.
"""

import json
import sys
import uuid
from pathlib import Path
from datetime import datetime, timezone

# Add utils to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from botocore.exceptions import ClientError
from boto3.dynamodb.conditions import Key
from utils import get_table, create_response
from utils.validation import validate_game_status, validate_score, validate_lineup
from utils.authorization import get_user_id_from_event, authorize, PermissionError


def handler(event, context):
    """
    Lambda handler for POST /games
    
    Creates a new game for a team.
    Requires team-owner, team-coach, or team-scorekeeper role.
    
    Args:
        event: API Gateway event
        context: Lambda context
        
    Returns:
        API Gateway response with new game data (201 Created)
    """
    print(json.dumps({
        'level': 'INFO',
        'message': 'Processing create game request',
        'httpMethod': event.get('requestContext', {}).get('http', {}).get('method'),
        'path': event.get('requestContext', {}).get('http', {}).get('path')
    }))
    
    try:
        # Extract user ID from JWT
        try:
            user_id = get_user_id_from_event(event)
        except ValueError as e:
            return create_response(401, {'error': str(e)})
        
        # Parse request body
        try:
            body = json.loads(event.get('body', '{}'))
        except json.JSONDecodeError:
            return create_response(400, {'error': 'Invalid JSON in request body'})
        
        # No required fields in body - teamId is optional
        
        # Get table reference
        table = get_table()
        
        # teamId is optional - if not provided, find user's "Default" personal team
        team_id = body.get('teamId')
        
        if not team_id:
            # Find user's "Default" PERSONAL team
            user_teams_response = table.query(
                KeyConditionExpression=Key('PK').eq(f'USER#{user_id}') & Key('SK').begins_with('TEAM#')
            )
            
            default_team_id = None
            for membership in user_teams_response.get('Items', []):
                if membership.get('status') != 'active':
                    continue
                
                # Get team details
                team_response = table.get_item(
                    Key={
                        'PK': f'TEAM#{membership["teamId"]}',
                        'SK': 'METADATA'
                    }
                )
                
                if 'Item' in team_response:
                    team = team_response['Item']
                    if team.get('name') == 'Default' and team.get('team_type') == 'PERSONAL':
                        default_team_id = team['teamId']
                        break
            
            if not default_team_id:
                return create_response(400, {
                    'error': 'No default personal team found. Please create a personal team first or specify a teamId.'
                })
            
            team_id = default_team_id
            
            print(json.dumps({
                'level': 'INFO',
                'message': 'Using default personal team for game',
                'userId': user_id,
                'teamId': team_id
            }))
        
        # Authorize: check if user can manage games for this team
        try:
            authorize(table, user_id, team_id, action='manage_games')
        except PermissionError as e:
            return create_response(403, {'error': str(e)})
        except ClientError as e:
            if e.response['Error']['Code'] == 'ResourceNotFoundException':
                return create_response(404, {'error': 'Team not found'})
            raise
        
        # Generate game ID and timestamp
        game_id = str(uuid.uuid4())
        timestamp = datetime.now(timezone.utc).isoformat()
        
        # Set defaults
        status = 'SCHEDULED'
        team_score = 0
        opponent_score = 0
        lineup = []
        
        # Validate optional fields if provided
        if 'status' in body:
            try:
                status = validate_game_status(body['status'])
            except ValueError as e:
                return create_response(400, {'error': str(e)})
        
        if 'teamScore' in body:
            try:
                team_score = validate_score(body['teamScore'])
            except ValueError as e:
                return create_response(400, {'error': str(e)})
        
        if 'opponentScore' in body:
            try:
                opponent_score = validate_score(body['opponentScore'])
            except ValueError as e:
                return create_response(400, {'error': str(e)})
        
        if 'lineup' in body:
            try:
                lineup = validate_lineup(body['lineup'])
            except ValueError as e:
                return create_response(400, {'error': str(e)})
        
        # Prepare game record
        game_item = {
            'PK': f'GAME#{game_id}',
            'SK': 'METADATA',
            'gameId': game_id,
            'teamId': team_id,
            'status': status,
            'teamScore': team_score,
            'opponentScore': opponent_score,
            'lineup': lineup,
            'createdAt': timestamp,
            'updatedAt': timestamp,
            'GSI2PK': 'ENTITY#GAME',
            'GSI2SK': f'METADATA#{game_id}',
            'GSI3PK': f'TEAM#{team_id}',
            'GSI3SK': f'GAME#{game_id}'
        }
        
        # Add optional fields if provided
        if 'scheduledStart' in body and body['scheduledStart']:
            game_item['scheduledStart'] = body['scheduledStart']
        
        if 'opponentName' in body and body['opponentName']:
            game_item['opponentName'] = body['opponentName']
        
        if 'location' in body and body['location']:
            game_item['location'] = body['location']
        
        if 'seasonId' in body and body['seasonId']:
            game_item['seasonId'] = body['seasonId']
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'Creating game',
            'gameId': game_id,
            'teamId': team_id,
            'status': status
        }))
        
        # Create game record
        try:
            table.put_item(
                Item=game_item,
                ConditionExpression='attribute_not_exists(PK) AND attribute_not_exists(SK)'
            )
        except ClientError as e:
            if e.response['Error']['Code'] == 'ConditionalCheckFailedException':
                print(json.dumps({
                    'level': 'ERROR',
                    'message': 'Game already exists',
                    'gameId': game_id,
                    'teamId': team_id
                }))
                return create_response(409, {'error': 'Game already exists'})
            raise
        
        # Build response (include all fields from game_item)
        response_data = {
            'gameId': game_id,
            'teamId': team_id,
            'status': status,
            'teamScore': team_score,
            'opponentScore': opponent_score,
            'lineup': lineup,
            'createdAt': timestamp,
            'updatedAt': timestamp
        }
        
        # Add optional fields to response
        if 'scheduledStart' in game_item:
            response_data['scheduledStart'] = game_item['scheduledStart']
        
        if 'opponentName' in game_item:
            response_data['opponentName'] = game_item['opponentName']
        
        if 'location' in game_item:
            response_data['location'] = game_item['location']
        
        if 'seasonId' in game_item:
            response_data['seasonId'] = game_item['seasonId']
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'Game created successfully',
            'gameId': game_id,
            'teamId': team_id
        }))
        
        return create_response(201, response_data)
        
    except ClientError as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'DynamoDB error',
            'error': str(e)
        }))
        return create_response(500, {'error': 'Could not create game'})
        
    except Exception as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'Unexpected error',
            'error': str(e),
            'errorType': type(e).__name__
        }))
        return create_response(500, {'error': 'Internal server error'})
