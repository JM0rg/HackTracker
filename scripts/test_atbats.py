#!/usr/bin/env python3
"""
Test AtBats Lambda Functions

Test script for at-bat CRUD operations against local DynamoDB or deployed API
"""

import json
import os
import sys
import uuid
from pathlib import Path
from datetime import datetime, timezone

# Set environment variables for local testing BEFORE importing anything
os.environ['DYNAMODB_LOCAL'] = 'true'
os.environ['DYNAMODB_ENDPOINT'] = 'http://localhost:8000'
os.environ['TABLE_NAME'] = 'HackTracker-dev'
os.environ['ENVIRONMENT'] = 'dev'

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent / 'src'))

from utils import get_table


def create_atbat(user_id, game_id, **kwargs):
    """Test create at-bat"""
    print(f"\n⚾ Creating at-bat for game: {game_id[:8]}...")
    print(f"   Requester: {user_id[:8]}...")
    
    # Import handler
    from atbats.create.handler import handler
    
    # Simulate API Gateway event
    body = kwargs.copy()
    
    event = {
        'headers': {'X-User-Id': user_id},
        'pathParameters': {'gameId': game_id},
        'body': json.dumps(body),
        'requestContext': {
            'http': {
                'method': 'POST',
                'path': f'/games/{game_id}/atbats'
            }
        }
    }
    
    response = handler(event, None)
    
    if response['statusCode'] == 201:
        atbat = json.loads(response['body'])
        print(f"   ✅ At-bat created: {atbat['atBatId'][:8]}...")
        print(f"   Player: {atbat['playerId'][:8]}...")
        print(f"   Result: {atbat['result']}")
        print(f"   Inning: {atbat['inning']}, Outs: {atbat['outs']}")
        if 'hitLocation' in atbat:
            print(f"   Hit Location: ({atbat['hitLocation']['x']:.2f}, {atbat['hitLocation']['y']:.2f})")
        if 'hitType' in atbat:
            print(f"   Hit Type: {atbat['hitType']}")
        if 'rbis' in atbat:
            print(f"   RBIs: {atbat['rbis']}")
        return atbat['atBatId']
    else:
        print(f"   ❌ Failed: {response['statusCode']}")
        print(f"   {response['body']}")
        return None


def list_atbats(user_id, game_id):
    """Test list at-bats"""
    print(f"\n📋 Listing at-bats for game: {game_id[:8]}...")
    
    from atbats.list.handler import handler
    
    event = {
        'headers': {'X-User-Id': user_id},
        'pathParameters': {'gameId': game_id},
        'requestContext': {
            'http': {
                'method': 'GET',
                'path': f'/games/{game_id}/atbats'
            }
        }
    }
    
    response = handler(event, None)
    
    if response['statusCode'] == 200:
        atbats = json.loads(response['body'])
        count = len(atbats)
        print(f"   ✅ Found {count} at-bat(s)")
        for idx, atbat in enumerate(atbats, 1):
            result = atbat.get('result', 'UNKNOWN')
            inning = atbat.get('inning', '?')
            outs = atbat.get('outs', '?')
            print(f"   {idx}. {result} (Inning {inning}, {outs} outs)")
        return atbats
    else:
        print(f"   ❌ Failed: {response['statusCode']}")
        print(f"   {response['body']}")
        return []


def get_atbat(user_id, game_id, atbat_id):
    """Test get at-bat"""
    print(f"\n🔍 Getting at-bat: {atbat_id[:8]}...")
    
    from atbats.get.handler import handler
    
    event = {
        'headers': {'X-User-Id': user_id},
        'pathParameters': {'gameId': game_id, 'atBatId': atbat_id},
        'requestContext': {
            'http': {
                'method': 'GET',
                'path': f'/games/{game_id}/atbats/{atbat_id}'
            }
        }
    }
    
    response = handler(event, None)
    
    if response['statusCode'] == 200:
        atbat = json.loads(response['body'])
        print(f"   ✅ At-bat found")
        print(f"   Player: {atbat['playerId'][:8]}...")
        print(f"   Result: {atbat['result']}")
        print(f"   Inning: {atbat['inning']}, Outs: {atbat['outs']}")
        print(f"   Batting Order: {atbat['battingOrder']}")
        return atbat
    else:
        print(f"   ❌ Failed: {response['statusCode']}")
        print(f"   {response['body']}")
        return None


def update_atbat(user_id, game_id, atbat_id, **updates):
    """Test update at-bat"""
    print(f"\n✏️  Updating at-bat: {atbat_id[:8]}...")
    print(f"   Updates: {updates}")
    
    from atbats.update.handler import handler
    
    event = {
        'headers': {'X-User-Id': user_id},
        'pathParameters': {'gameId': game_id, 'atBatId': atbat_id},
        'body': json.dumps(updates),
        'requestContext': {
            'http': {
                'method': 'PUT',
                'path': f'/games/{game_id}/atbats/{atbat_id}'
            }
        }
    }
    
    response = handler(event, None)
    
    if response['statusCode'] == 200:
        atbat = json.loads(response['body'])
        print(f"   ✅ At-bat updated")
        print(f"   Result: {atbat['result']}")
        print(f"   Inning: {atbat['inning']}, Outs: {atbat['outs']}")
        return atbat
    else:
        print(f"   ❌ Failed: {response['statusCode']}")
        print(f"   {response['body']}")
        return None


def delete_atbat(user_id, game_id, atbat_id):
    """Test delete at-bat"""
    print(f"\n🗑️  Deleting at-bat: {atbat_id[:8]}...")
    
    from atbats.delete.handler import handler
    
    event = {
        'headers': {'X-User-Id': user_id},
        'pathParameters': {'gameId': game_id, 'atBatId': atbat_id},
        'requestContext': {
            'http': {
                'method': 'DELETE',
                'path': f'/games/{game_id}/atbats/{atbat_id}'
            }
        }
    }
    
    response = handler(event, None)
    
    if response['statusCode'] == 204:
        print(f"   ✅ At-bat deleted successfully")
        return True
    else:
        print(f"   ❌ Failed: {response['statusCode']}")
        if response.get('body'):
            print(f"   {response['body']}")
        return False


def verify_atbat(game_id, atbat_id):
    """Verify at-bat exists in DynamoDB"""
    print(f"\n🔍 Verifying at-bat: {atbat_id[:8]}...")
    
    table = get_table()
    response = table.get_item(
        Key={
            'PK': f'GAME#{game_id}',
            'SK': f'ATBAT#{atbat_id}'
        }
    )
    
    if 'Item' in response:
        atbat = response['Item']
        print(f"   ✅ At-bat found")
        print(f"   Player: {atbat['playerId']}")
        print(f"   Result: {atbat.get('result')}")
        print(f"   Inning: {atbat.get('inning')}, Outs: {atbat.get('outs')}")
        return atbat
    else:
        print(f"   ❌ At-bat not found")
        return None


def main():
    """Main test runner"""
    if len(sys.argv) < 2:
        print("Usage: python test_atbats.py <command> [args]")
        print("\nCommands:")
        print("  create <userId> <gameId> <playerId> <result> <inning> <outs> <battingOrder> [hitLocationX] [hitLocationY] [hitType] [rbis]")
        print("  list <userId> <gameId>")
        print("  get <userId> <gameId> <atBatId>")
        print("  update <userId> <gameId> <atBatId> <field> <value>")
        print("  delete <userId> <gameId> <atBatId>")
        print("  verify <gameId> <atBatId>")
        sys.exit(1)
    
    command = sys.argv[1]
    
    try:
        if command == 'create':
            user_id = sys.argv[2]
            game_id = sys.argv[3]
            player_id = sys.argv[4]
            result = sys.argv[5]
            inning = int(sys.argv[6])
            outs = int(sys.argv[7])
            batting_order = int(sys.argv[8])
            
            kwargs = {
                'playerId': player_id,
                'result': result,
                'inning': inning,
                'outs': outs,
                'battingOrder': batting_order
            }
            
            # Optional fields
            if len(sys.argv) > 9 and sys.argv[9]:
                hit_x = float(sys.argv[9])
                hit_y = float(sys.argv[10]) if len(sys.argv) > 10 else 0.5
                kwargs['hitLocation'] = {'x': hit_x, 'y': hit_y}
            
            if len(sys.argv) > 11 and sys.argv[11]:
                kwargs['hitType'] = sys.argv[11]
            
            if len(sys.argv) > 12 and sys.argv[12]:
                kwargs['rbis'] = int(sys.argv[12])
            
            create_atbat(user_id, game_id, **kwargs)
        
        elif command == 'list':
            user_id = sys.argv[2]
            game_id = sys.argv[3]
            list_atbats(user_id, game_id)
        
        elif command == 'get':
            user_id = sys.argv[2]
            game_id = sys.argv[3]
            atbat_id = sys.argv[4]
            get_atbat(user_id, game_id, atbat_id)
        
        elif command == 'update':
            user_id = sys.argv[2]
            game_id = sys.argv[3]
            atbat_id = sys.argv[4]
            field = sys.argv[5]
            value = sys.argv[6] if len(sys.argv) > 6 else None
            
            # Handle special values
            if value == 'null':
                value = None
            elif field in ['inning', 'outs', 'rbis'] and value:
                value = int(value)
            elif field == 'hitLocation' and value:
                value = json.loads(value)
            
            update_atbat(user_id, game_id, atbat_id, **{field: value})
        
        elif command == 'delete':
            user_id = sys.argv[2]
            game_id = sys.argv[3]
            atbat_id = sys.argv[4]
            delete_atbat(user_id, game_id, atbat_id)
        
        elif command == 'verify':
            game_id = sys.argv[2]
            atbat_id = sys.argv[3]
            verify_atbat(game_id, atbat_id)
        
        else:
            print(f"Unknown command: {command}")
            sys.exit(1)
    
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()

