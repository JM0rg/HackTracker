"""
Remove Player Lambda Handler

API Gateway handler to remove a player from a team roster.
Only allows deletion of ghost players (unlinked).
Linked players must be unlinked first.
"""

import json
import sys
from pathlib import Path

# Add utils to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from botocore.exceptions import ClientError
from utils import get_table, create_response
from utils.authorization import get_user_id_from_event, check_team_role, PermissionError


def handler(event, context):
    """
    Lambda handler for DELETE /teams/{teamId}/players/{playerId}
    
    Removes a ghost player from a team roster (hard delete).
    Linked players cannot be deleted - they must be unlinked first.
    Requires team-owner or team-coach role.
    
    Args:
        event: API Gateway event
        context: Lambda context
        
    Returns:
        API Gateway response (204 No Content)
    """
    print(json.dumps({
        'level': 'INFO',
        'message': 'Processing remove player request',
        'httpMethod': event.get('requestContext', {}).get('http', {}).get('method'),
        'path': event.get('requestContext', {}).get('http', {}).get('path')
    }))
    
    try:
        # Extract user ID from JWT
        try:
            user_id = get_user_id_from_event(event)
        except ValueError as e:
            return create_response(401, {'error': str(e)})
        
        # Extract team ID and player ID from path
        path_params = event.get('pathParameters', {})
        team_id = path_params.get('teamId')
        player_id = path_params.get('playerId')
        
        if not team_id:
            return create_response(400, {'error': 'teamId is required in path'})
        if not player_id:
            return create_response(400, {'error': 'playerId is required in path'})
        
        # Authorize: only owner or coach can remove players
        table = get_table()
        try:
            check_team_role(table, user_id, team_id, ['team-owner', 'team-coach'])
        except PermissionError as e:
            return create_response(403, {'error': str(e)})
        except ClientError as e:
            if e.response['Error']['Code'] == 'ResourceNotFoundException':
                return create_response(404, {'error': 'Team not found'})
            raise
        
        # Get player to check if it's a ghost player
        print(json.dumps({
            'level': 'INFO',
            'message': 'Checking player status',
            'teamId': team_id,
            'playerId': player_id
        }))
        
        response = table.get_item(
            Key={
                'PK': f'TEAM#{team_id}',
                'SK': f'PLAYER#{player_id}'
            }
        )
        
        if 'Item' not in response:
            print(json.dumps({
                'level': 'WARN',
                'message': 'Player not found',
                'teamId': team_id,
                'playerId': player_id
            }))
            return create_response(404, {'error': 'Player not found'})
        
        player = response['Item']
        
        # Check if player is linked (has userId)
        if player.get('userId') is not None:
            print(json.dumps({
                'level': 'WARN',
                'message': 'Attempted to delete linked player',
                'teamId': team_id,
                'playerId': player_id,
                'userId': player.get('userId')
            }))
            return create_response(400, {
                'error': 'Cannot delete linked player. Use unlink operation instead.'
            })
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'Deleting ghost player',
            'playerId': player_id,
            'teamId': team_id
        }))
        
        # Delete player from DynamoDB (hard delete)
        # Use ConditionExpression to ensure player still exists and is still a ghost
        try:
            table.delete_item(
                Key={
                    'PK': f'TEAM#{team_id}',
                    'SK': f'PLAYER#{player_id}'
                },
                ConditionExpression='attribute_exists(PK) AND isGhost = :true',
                ExpressionAttributeValues={
                    ':true': True
                }
            )
        except ClientError as e:
            if e.response['Error']['Code'] == 'ConditionalCheckFailedException':
                # Player either doesn't exist or is no longer a ghost
                print(json.dumps({
                    'level': 'ERROR',
                    'message': 'Player not found or no longer a ghost',
                    'playerId': player_id,
                    'teamId': team_id
                }))
                return create_response(404, {'error': 'Player not found or cannot be deleted'})
            raise
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'Player deleted successfully',
            'playerId': player_id,
            'teamId': team_id
        }))
        
        return create_response(204)
        
    except ClientError as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'DynamoDB error',
            'error': str(e)
        }))
        return create_response(500, {'error': 'Could not remove player'})
        
    except Exception as e:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'Unexpected error',
            'error': str(e),
            'errorType': type(e).__name__
        }))
        return create_response(500, {'error': 'Internal server error'})

