"""
Personal Team utilities

Provides functions for creating and managing personal stats teams.
Personal teams are invisible containers for at-bats not linked to any real team.
"""

import json
import uuid
from botocore.exceptions import ClientError


def create_personal_team(table, user_id, first_name, timestamp):
    """
    Create personal stats team with linked player for a new user
    
    Creates 3 records atomically:
    1. Team record (isPersonal: true)
    2. Membership record (team-owner)
    3. Player record (auto-linked to user)
    
    Args:
        table: DynamoDB table resource
        user_id (str): User's unique identifier (Cognito sub)
        first_name (str): User's first name for player record
        timestamp (str): ISO 8601 timestamp
    
    Returns:
        tuple: (team_id, player_id) if successful, (None, None) if failed
    
    Raises:
        ClientError: If DynamoDB transaction fails
    """
    team_id = str(uuid.uuid4())
    player_id = str(uuid.uuid4())
    
    # Team record (isPersonal: true)
    team_item = {
        'PK': f'TEAM#{team_id}',
        'SK': 'METADATA',
        'teamId': team_id,
        'name': 'Personal Stats',
        'ownerId': user_id,
        'status': 'active',
        'isPersonal': True,  # Key flag for filtering
        'createdAt': timestamp,
        'updatedAt': timestamp,
        'GSI2PK': 'ENTITY#TEAM',
        'GSI2SK': f'METADATA#{team_id}'
    }
    
    # Membership record (team-owner)
    # Note: invitedBy is omitted (not set to None) since this is self-created
    membership_item = {
        'PK': f'USER#{user_id}',
        'SK': f'TEAM#{team_id}',
        'teamId': team_id,
        'userId': user_id,
        'role': 'team-owner',
        'status': 'active',
        'joinedAt': timestamp
    }
    
    # Player record (auto-linked to user)
    player_item = {
        'PK': f'TEAM#{team_id}',
        'SK': f'PLAYER#{player_id}',
        'playerId': player_id,
        'teamId': team_id,
        'firstName': first_name,
        'status': 'active',
        'isGhost': False,  # Immediately linked
        'userId': user_id,  # Auto-linked
        'linkedAt': timestamp,
        'createdAt': timestamp,
        'updatedAt': timestamp,
        'GSI4PK': f'USER#{user_id}',  # For stat queries
        'GSI4SK': f'PLAYER#{player_id}'
    }
    
    print(json.dumps({
        'level': 'INFO',
        'message': 'Creating personal stats team',
        'userId': user_id,
        'teamId': team_id,
        'playerId': player_id
    }))
    
    try:
        # Execute 3-item atomic transaction
        # Note: table.meta.client.transact_write_items expects Python native types,
        # not low-level DynamoDB format
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
                },
                {
                    'Put': {
                        'TableName': table.name,
                        'Item': player_item,
                        'ConditionExpression': 'attribute_not_exists(PK) AND attribute_not_exists(SK)'
                    }
                }
            ]
        )
        
        print(json.dumps({
            'level': 'INFO',
            'message': 'Personal stats team created successfully',
            'userId': user_id,
            'teamId': team_id,
            'playerId': player_id
        }))
        
        return (team_id, player_id)
        
    except ClientError as e:
        if e.response['Error']['Code'] == 'TransactionCanceledException':
            print(json.dumps({
                'level': 'ERROR',
                'message': 'Personal team transaction cancelled - records may already exist',
                'userId': user_id,
                'teamId': team_id
            }))
        else:
            print(json.dumps({
                'level': 'ERROR',
                'message': 'Failed to create personal team',
                'userId': user_id,
                'error': str(e)
            }))
        return (None, None)

