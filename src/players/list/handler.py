"""
List Players Lambda Handler

API Gateway handler to list all players on a team roster.
Returns players sorted by number, then name.
"""

import json
import sys
from pathlib import Path
from decimal import Decimal

# Add utils to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from botocore.exceptions import ClientError
from utils import get_table, create_response
from utils.authorization import get_user_id_from_event, check_team_membership, PermissionError


def handler(event, context):
    """
    Lambda handler for GET /teams/{teamId}/players
    
    Lists all players on a team roster.
    All team members can view the roster.
    
    Args:
        event: API Gateway event
        context: Lambda context
        
    Returns:
        API Gateway response with list of players (200 OK)
    """
    print(json.dumps({
        'level': 'INFO',
        'message': 'Processing list players request',
        'httpMethod': event.get('requestContext', {}).get('http', {}).get('method'),
        'path': event.get('requestContext', {}).get('http', {}).get('path')
    }))
    
    try:
        # Extract user ID from JWT
        try:
            user_id = get_user_id_from_event(event)
        except ValueError as e:
            return create_response(401, {'error': str(e)})
        
        # Extract team ID from path
        path_params = event.get('pathParameters', {})
        team_id = path_params.get('teamId')
        
        if not team_id:
            return create_response(400, {'error': 'teamId is required in path'})
        
        # Extract optional query parameters
        query_params = event.get('queryStringParameters') or {}
        status_filter = query_params.get('status')  # active, inactive, sub
        ghost_filter = query_params.get('isGhost')  # true, false
        
        # Authorize: any active team member can view roster
        table = get_table()
        try:
            check_team_membership(table, user_id, team_id)
        except PermissionError as e:
            return create_response(403, {'error': str(e)})
        except ClientError as e:
            if e.response['Error']['Code'] == 'ResourceNotFoundException':
                return create_response(404, {'error': 'Team not found'})
            raise
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'Querying players',
            'teamId': team_id,
            'filters': {'status': status_filter, 'isGhost': ghost_filter}
        }))
        
        # Query all players for the team
        response = table.query(
            KeyConditionExpression='PK = :pk AND begins_with(SK, :sk)',
            ExpressionAttributeValues={
                ':pk': f'TEAM#{team_id}',
                ':sk': 'PLAYER#'
            }
        )
        
        players = response.get('Items', [])
        
        # Apply filters if provided
        if status_filter:
            status_filter = status_filter.lower()
            players = [p for p in players if p.get('status', '').lower() == status_filter]
        
        if ghost_filter:
            is_ghost = ghost_filter.lower() == 'true'
            players = [p for p in players if p.get('isGhost', False) == is_ghost]
        
        # Sort players: by playerNumber (ascending, nulls last), then lastName, then firstName
        def sort_key(player):
            # Convert Decimal to int/float for comparison
            number = player.get('playerNumber')
            if isinstance(number, Decimal):
                number = int(number)
            # Put None/null numbers at the end
            number_sort = (1, 999999) if number is None else (0, number)
            
            last_name = (player.get('lastName') or '').lower()
            first_name = (player.get('firstName') or '').lower()
            
            return (number_sort, last_name, first_name)
        
        players.sort(key=sort_key)
        
        # Build clean response (exclude internal DynamoDB keys)
        clean_players = []
        for player in players:
            clean_player = {
                'playerId': player['playerId'],
                'teamId': player['teamId'],
                'firstName': player['firstName'],
                'status': player['status'],
                'isGhost': player.get('isGhost', False),
                'createdAt': player['createdAt'],
                'updatedAt': player['updatedAt']
            }
            
            # Add optional fields
            if 'lastName' in player and player['lastName']:
                clean_player['lastName'] = player['lastName']
            
            if 'playerNumber' in player and player['playerNumber'] is not None:
                # Convert Decimal to int for JSON serialization
                clean_player['playerNumber'] = int(player['playerNumber']) if isinstance(player['playerNumber'], Decimal) else player['playerNumber']
            
            if 'userId' in player and player['userId']:
                clean_player['userId'] = player['userId']
            
            if 'linkedAt' in player and player['linkedAt']:
                clean_player['linkedAt'] = player['linkedAt']
            
            if 'positions' in player and player['positions']:
                clean_player['positions'] = player['positions']
            
            clean_players.append(clean_player)
        
        # Build response
        response_data = {
            'players': clean_players,
            'count': len(clean_players)
        }
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'Players retrieved successfully',
            'teamId': team_id,
            'count': len(players)
        }))
        
        return create_response(200, response_data)
        
    except ClientError as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'DynamoDB error',
            'error': str(e)
        }))
        return create_response(500, {'error': 'Could not list players'})
        
    except Exception as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'Unexpected error',
            'error': str(e),
            'errorType': type(e).__name__
        }))
        return create_response(500, {'error': 'Internal server error'})

