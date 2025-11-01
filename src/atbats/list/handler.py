"""
List AtBats Lambda Handler

API Gateway handler to list all at-bats for a game.
Returns all plate appearances in the order they occurred.
"""

import json
import sys
from pathlib import Path

# Add utils to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from botocore.exceptions import ClientError
from boto3.dynamodb.conditions import Key
from utils import get_table, create_response
from utils.authorization import get_user_id_from_event, check_team_membership, PermissionError


def handler(event, context):
    """
    Lambda handler for GET /games/{gameId}/atbats
    
    Lists all at-bats for a game.
    Requires team membership (any role).
    
    Args:
        event: API Gateway event
        context: Lambda context
        
    Returns:
        API Gateway response with array of at-bats (200 OK)
    """
    print(json.dumps({
        'level': 'INFO',
        'message': 'Processing list at-bats request',
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
        
        # Authorize: check if user is a member of this team
        try:
            check_team_membership(table, user_id, team_id)
        except PermissionError as e:
            return create_response(403, {'error': str(e)})
        except ClientError as e:
            if e.response['Error']['Code'] == 'ResourceNotFoundException':
                return create_response(404, {'error': 'Team not found'})
            raise
        
        # Query all at-bats for this game
        print(json.dumps({
            'level': 'INFO',
            'message': 'Querying at-bats for game',
            'gameId': game_id
        }))
        
        query_response = table.query(
            KeyConditionExpression=Key('PK').eq(f'GAME#{game_id}') & Key('SK').begins_with('ATBAT#')
        )
        
        atbats = query_response.get('Items', [])
        
        # Format at-bats for response (remove internal DynamoDB keys)
        formatted_atbats = []
        for atbat in atbats:
            formatted_atbat = {
                'atBatId': atbat['atBatId'],
                'gameId': atbat['gameId'],
                'playerId': atbat['playerId'],
                'teamId': atbat['teamId'],
                'result': atbat['result'],
                'inning': atbat['inning'],
                'outs': atbat['outs'],
                'battingOrder': atbat['battingOrder'],
                'createdAt': atbat['createdAt'],
                'updatedAt': atbat['updatedAt']
            }
            
            # Add optional fields if present
            if 'hitLocation' in atbat:
                formatted_atbat['hitLocation'] = atbat['hitLocation']
            if 'hitType' in atbat:
                formatted_atbat['hitType'] = atbat['hitType']
            if 'rbis' in atbat:
                formatted_atbat['rbis'] = atbat['rbis']
            
            formatted_atbats.append(formatted_atbat)
        
        # Sort by createdAt (chronological order)
        formatted_atbats.sort(key=lambda x: x['createdAt'])
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'At-bats retrieved successfully',
            'gameId': game_id,
            'count': len(formatted_atbats)
        }))
        
        return create_response(200, formatted_atbats)
        
    except ClientError as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'DynamoDB error',
            'error': str(e),
            'errorCode': e.response['Error']['Code']
        }))
        return create_response(500, {'error': 'Could not retrieve at-bats'})
    
    except Exception as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'Unexpected error',
            'error': str(e),
            'type': type(e).__name__
        }))
        return create_response(500, {'error': 'Internal server error'})

