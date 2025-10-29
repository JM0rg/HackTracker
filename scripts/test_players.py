#!/usr/bin/env python3
"""
Test Players Lambda Functions

Test script for player operations against local DynamoDB or deployed API
"""

import json
import os
import sys
import uuid
from pathlib import Path

# Set environment variables for local testing BEFORE importing anything
os.environ['DYNAMODB_LOCAL'] = 'true'
os.environ['DYNAMODB_ENDPOINT'] = 'http://localhost:8000'
os.environ['TABLE_NAME'] = 'HackTracker-dev'
os.environ['ENVIRONMENT'] = 'dev'

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent / 'src'))

from utils import get_table


def add_player(user_id, team_id, first_name, last_name=None, player_number=None, status=None):
    """Test add player"""
    print(f"\n🎮 Adding player: {first_name} {last_name or ''}")
    print(f"   Team: {team_id}")
    print(f"   Requester: {user_id}")
    
    # Import handler
    from players.add.handler import handler
    
    # Simulate API Gateway event
    body = {"firstName": first_name}
    if last_name:
        body["lastName"] = last_name
    if player_number is not None:
        body["playerNumber"] = player_number
    if status:
        body["status"] = status
    
    event = {
        'headers': {'X-User-Id': user_id},
        'pathParameters': {'teamId': team_id},
        'body': json.dumps(body),
        'requestContext': {
            'http': {
                'method': 'POST',
                'path': f'/teams/{team_id}/players'
            }
        }
    }
    
    response = handler(event, None)
    
    if response['statusCode'] == 201:
        player = json.loads(response['body'])
        print(f"   ✅ Player created: {player['playerId']}")
        print(f"   Name: {player['firstName']} {player.get('lastName', '')}")
        print(f"   Number: {player.get('playerNumber', 'N/A')}")
        print(f"   Status: {player['status']}")
        print(f"   Is Ghost: {player['isGhost']}")
        return player['playerId']
    else:
        print(f"   ❌ Failed: {response['statusCode']}")
        print(f"   {response['body']}")
        return None


def list_players(user_id, team_id, status=None, is_ghost=None):
    """Test list players"""
    print(f"\n📋 Listing players for team: {team_id[:8]}...")
    if status:
        print(f"   Filter: status={status}")
    if is_ghost:
        print(f"   Filter: isGhost={is_ghost}")
    
    from players.list.handler import handler
    
    # Build query parameters
    query_params = {}
    if status:
        query_params['status'] = status
    if is_ghost is not None:
        query_params['isGhost'] = str(is_ghost).lower()
    
    event = {
        'headers': {'X-User-Id': user_id},
        'pathParameters': {'teamId': team_id},
        'queryStringParameters': query_params if query_params else None,
        'requestContext': {
            'http': {
                'method': 'GET',
                'path': f'/teams/{team_id}/players'
            }
        }
    }
    
    response = handler(event, None)
    
    if response['statusCode'] == 200:
        data = json.loads(response['body'])
        players = data['players']
        count = data['count']
        print(f"   ✅ Found {count} player(s)")
        for idx, player in enumerate(players, 1):
            print(f"   {idx}. {player['firstName']} {player.get('lastName', '')} "
                  f"(#{player.get('playerNumber', 'N/A')}) - {player['status']}")
        return players
    else:
        print(f"   ❌ Failed: {response['statusCode']}")
        print(f"   {response['body']}")
        return []


def get_player(user_id, team_id, player_id):
    """Test get player"""
    print(f"\n🔍 Getting player: {player_id[:8]}...")
    
    from players.get.handler import handler
    
    event = {
        'headers': {'X-User-Id': user_id},
        'pathParameters': {'teamId': team_id, 'playerId': player_id},
        'requestContext': {
            'http': {
                'method': 'GET',
                'path': f'/teams/{team_id}/players/{player_id}'
            }
        }
    }
    
    response = handler(event, None)
    
    if response['statusCode'] == 200:
        player = json.loads(response['body'])
        print(f"   ✅ Player found")
        print(f"   Name: {player['firstName']} {player.get('lastName', '')}")
        print(f"   Number: {player.get('playerNumber', 'N/A')}")
        print(f"   Status: {player['status']}")
        print(f"   Is Ghost: {player['isGhost']}")
        return player
    else:
        print(f"   ❌ Failed: {response['statusCode']}")
        print(f"   {response['body']}")
        return None


def update_player(user_id, team_id, player_id, **updates):
    """Test update player"""
    print(f"\n✏️  Updating player: {player_id[:8]}...")
    print(f"   Updates: {updates}")
    
    from players.update.handler import handler
    
    event = {
        'headers': {'X-User-Id': user_id},
        'pathParameters': {'teamId': team_id, 'playerId': player_id},
        'body': json.dumps(updates),
        'requestContext': {
            'http': {
                'method': 'PUT',
                'path': f'/teams/{team_id}/players/{player_id}'
            }
        }
    }
    
    response = handler(event, None)
    
    if response['statusCode'] == 200:
        player = json.loads(response['body'])
        print(f"   ✅ Player updated")
        print(f"   Name: {player['firstName']} {player.get('lastName', '')}")
        print(f"   Number: {player.get('playerNumber', 'N/A')}")
        print(f"   Status: {player['status']}")
        return player
    else:
        print(f"   ❌ Failed: {response['statusCode']}")
        print(f"   {response['body']}")
        return None


def remove_player(user_id, team_id, player_id):
    """Test remove player"""
    print(f"\n🗑️  Removing player: {player_id[:8]}...")
    
    from players.remove.handler import handler
    
    event = {
        'headers': {'X-User-Id': user_id},
        'pathParameters': {'teamId': team_id, 'playerId': player_id},
        'requestContext': {
            'http': {
                'method': 'DELETE',
                'path': f'/teams/{team_id}/players/{player_id}'
            }
        }
    }
    
    response = handler(event, None)
    
    if response['statusCode'] == 204:
        print(f"   ✅ Player removed successfully")
        return True
    else:
        print(f"   ❌ Failed: {response['statusCode']}")
        if response.get('body'):
            print(f"   {response['body']}")
        return False


def verify_player(team_id, player_id):
    """Verify player exists in DynamoDB"""
    print(f"\n🔍 Verifying player: {player_id[:8]}... in Team {team_id[:8]}...")
    
    table = get_table()
    response = table.get_item(
        Key={
            'PK': f'TEAM#{team_id}',
            'SK': f'PLAYER#{player_id}'
        }
    )
    
    if 'Item' in response:
        player = response['Item']
        print(f"   ✅ Player found")
        print(f"   Name: {player.get('firstName')} {player.get('lastName', '')}")
        print(f"   Number: {player.get('playerNumber', 'N/A')}")
        print(f"   Status: {player.get('status')}")
        print(f"   Is Ghost: {player.get('isGhost')}")
        print(f"   User ID: {player.get('userId', 'None (ghost)')}")
        return player
    else:
        print(f"   ❌ Player not found")
        return None


def create_test_team(user_id, name):
    """Helper: Create a test team"""
    print(f"\n📝 Creating test team: {name}")
    
    from teams.create.handler import handler
    
    event = {
        'headers': {'X-User-Id': user_id},
        'body': json.dumps({"name": name, "teamType": "MANAGED"}),
        'requestContext': {
            'http': {
                'method': 'POST',
                'path': '/teams'
            }
        }
    }
    
    response = handler(event, None)
    
    if response['statusCode'] == 201:
        team = json.loads(response['body'])
        print(f"   ✅ Team created: {team['teamId']}")
        return team['teamId']
    else:
        print(f"   ❌ Failed to create team: {response['statusCode']}")
        print(f"   {response['body']}")
        return None


def test_validation_errors(user_id, team_id):
    """Test validation error handling"""
    print("\n" + "=" * 60)
    print("TEST: Validation Errors")
    print("=" * 60)
    
    # Test 1: Missing firstName
    print("\n📋 Test: Missing firstName")
    from players.add.handler import handler
    event = {
        'headers': {'X-User-Id': user_id},
        'pathParameters': {'teamId': team_id},
        'body': json.dumps({"lastName": "Doe"}),
        'requestContext': {'http': {'method': 'POST', 'path': f'/teams/{team_id}/players'}}
    }
    response = handler(event, None)
    if response['statusCode'] == 400:
        print(f"   ✅ Correctly rejected: {response['statusCode']}")
    else:
        print(f"   ❌ Should have been 400, got: {response['statusCode']}")
    
    # Test 2: Invalid firstName (numbers)
    print("\n📋 Test: Invalid firstName (numbers)")
    event['body'] = json.dumps({"firstName": "John123"})
    response = handler(event, None)
    if response['statusCode'] == 400:
        print(f"   ✅ Correctly rejected: {response['statusCode']}")
    else:
        print(f"   ❌ Should have been 400, got: {response['statusCode']}")
    
    # Test 3: Invalid firstName (spaces)
    print("\n📋 Test: Invalid firstName (spaces)")
    event['body'] = json.dumps({"firstName": "John Doe"})
    response = handler(event, None)
    if response['statusCode'] == 400:
        print(f"   ✅ Correctly rejected: {response['statusCode']}")
    else:
        print(f"   ❌ Should have been 400, got: {response['statusCode']}")
    
    # Test 4: Invalid playerNumber (too high)
    print("\n📋 Test: Invalid playerNumber (100)")
    event['body'] = json.dumps({"firstName": "John", "playerNumber": 100})
    response = handler(event, None)
    if response['statusCode'] == 400:
        print(f"   ✅ Correctly rejected: {response['statusCode']}")
    else:
        print(f"   ❌ Should have been 400, got: {response['statusCode']}")
    
    # Test 5: Invalid playerNumber (negative)
    print("\n📋 Test: Invalid playerNumber (-1)")
    event['body'] = json.dumps({"firstName": "John", "playerNumber": -1})
    response = handler(event, None)
    if response['statusCode'] == 400:
        print(f"   ✅ Correctly rejected: {response['statusCode']}")
    else:
        print(f"   ❌ Should have been 400, got: {response['statusCode']}")
    
    # Test 6: Invalid status
    print("\n📋 Test: Invalid status")
    event['body'] = json.dumps({"firstName": "John", "status": "invalid"})
    response = handler(event, None)
    if response['statusCode'] == 400:
        print(f"   ✅ Correctly rejected: {response['statusCode']}")
    else:
        print(f"   ❌ Should have been 400, got: {response['statusCode']}")


def test_authorization(user_id, team_id):
    """Test authorization requirements"""
    print("\n" + "=" * 60)
    print("TEST: Authorization")
    print("=" * 60)
    
    # Test 1: Non-member cannot add player
    print("\n📋 Test: Non-member cannot add player")
    random_user = str(uuid.uuid4())
    from players.add.handler import handler
    event = {
        'headers': {'X-User-Id': random_user},
        'pathParameters': {'teamId': team_id},
        'body': json.dumps({"firstName": "John"}),
        'requestContext': {'http': {'method': 'POST', 'path': f'/teams/{team_id}/players'}}
    }
    response = handler(event, None)
    if response['statusCode'] == 403:
        print(f"   ✅ Correctly rejected: {response['statusCode']}")
    else:
        print(f"   ❌ Should have been 403, got: {response['statusCode']}")
    
    # Test 2: Team owner CAN add player
    print("\n📋 Test: Team owner can add player")
    player_id = add_player(user_id, team_id, "AuthTest", "Owner")
    if player_id:
        print(f"   ✅ Owner successfully added player")
    else:
        print(f"   ❌ Owner should be able to add player")


def run_full_test(user_id):
    """Run complete test suite"""
    print("=" * 60)
    print("🧪 PLAYER OPERATIONS - FULL TEST SUITE")
    print("=" * 60)
    print(f"Test User ID: {user_id}")
    
    # Setup: Create test team
    print("\n" + "=" * 60)
    print("SETUP: Create Test Team")
    print("=" * 60)
    team_id = create_test_team(user_id, f"Test Team {uuid.uuid4().hex[:8]}")
    
    if not team_id:
        print("\n❌ Failed to create test team")
        return
    
    # Test 1: Add players with various configurations
    print("\n" + "=" * 60)
    print("TEST 1: Add Players (Valid)")
    print("=" * 60)
    
    # Player 1: All fields
    player1_id = add_player(user_id, team_id, "John", "Doe", 12, "active")
    
    # Player 2: Minimal (firstName only)
    player2_id = add_player(user_id, team_id, "Jane")
    
    # Player 3: With status
    player3_id = add_player(user_id, team_id, "Bob", status="sub")
    
    # Player 4: With number but no last name
    player4_id = add_player(user_id, team_id, "Alice", player_number=7)
    
    # Player 5: Hyphenated name
    player5_id = add_player(user_id, team_id, "Jean-Paul", "Smith-Jones", 99)
    
    # Player 6: Number 0 (edge case)
    player6_id = add_player(user_id, team_id, "Zero", player_number=0)
    
    if not all([player1_id, player2_id, player3_id, player4_id, player5_id, player6_id]):
        print("\n❌ Failed to create all players")
        return
    
    # Test 2: Verify players in database
    print("\n" + "=" * 60)
    print("TEST 2: Verify Players in DynamoDB")
    print("=" * 60)
    verify_player(team_id, player1_id)
    verify_player(team_id, player2_id)
    verify_player(team_id, player3_id)
    
    # Test 3: Validation errors
    test_validation_errors(user_id, team_id)
    
    # Test 4: Authorization
    test_authorization(user_id, team_id)
    
    # Test 5: Duplicate names (should be allowed)
    print("\n" + "=" * 60)
    print("TEST 5: Duplicate Names (Should Allow)")
    print("=" * 60)
    player7_id = add_player(user_id, team_id, "John", "Doe", 13)  # Same name, different number
    if player7_id:
        print(f"   ✅ Duplicate name allowed (different player)")
    else:
        print(f"   ❌ Should allow duplicate names")
    
    # Test 6: Different statuses
    print("\n" + "=" * 60)
    print("TEST 6: Different Player Statuses")
    print("=" * 60)
    add_player(user_id, team_id, "Active", status="active")
    add_player(user_id, team_id, "Inactive", status="inactive")
    add_player(user_id, team_id, "Sub", status="sub")
    
    # Test 7: List Players
    print("\n" + "=" * 60)
    print("TEST 7: List Players")
    print("=" * 60)
    all_players = list_players(user_id, team_id)
    print(f"   Total players on roster: {len(all_players)}")
    
    # Test 7a: List with status filter
    print("\n📋 Test: List active players only")
    active_players = list_players(user_id, team_id, status="active")
    
    # Test 7b: List ghost players only
    print("\n📋 Test: List ghost players only")
    ghost_players = list_players(user_id, team_id, is_ghost=True)
    
    # Test 8: Get Player
    print("\n" + "=" * 60)
    print("TEST 8: Get Single Player")
    print("=" * 60)
    retrieved_player = get_player(user_id, team_id, player1_id)
    if retrieved_player:
        print(f"   ✅ Successfully retrieved player")
    else:
        print(f"   ❌ Failed to retrieve player")
    
    # Test 8a: Get non-existent player (should 404)
    print("\n📋 Test: Get non-existent player")
    fake_id = str(uuid.uuid4())
    get_player(user_id, team_id, fake_id)
    
    # Test 9: Update Player
    print("\n" + "=" * 60)
    print("TEST 9: Update Player")
    print("=" * 60)
    
    # Test 9a: Update firstName
    print("\n📋 Test: Update firstName")
    updated = update_player(user_id, team_id, player2_id, firstName="Janet")
    if updated and updated['firstName'] == 'Janet':
        print(f"   ✅ firstName updated successfully")
    
    # Test 9b: Add lastName
    print("\n📋 Test: Add lastName")
    updated = update_player(user_id, team_id, player2_id, lastName="Smith")
    if updated and updated.get('lastName') == 'Smith':
        print(f"   ✅ lastName added successfully")
    
    # Test 9c: Update playerNumber
    print("\n📋 Test: Update playerNumber")
    updated = update_player(user_id, team_id, player2_id, playerNumber=22)
    if updated and updated.get('playerNumber') == 22:
        print(f"   ✅ playerNumber updated successfully")
    
    # Test 9d: Update status
    print("\n📋 Test: Update status")
    updated = update_player(user_id, team_id, player3_id, status="inactive")
    if updated and updated['status'] == 'inactive':
        print(f"   ✅ status updated successfully")
    
    # Test 9e: Remove lastName (set to null)
    print("\n📋 Test: Remove lastName")
    updated = update_player(user_id, team_id, player1_id, lastName=None)
    if updated and updated.get('lastName') is None:
        print(f"   ✅ lastName removed successfully")
    
    # Test 9f: Try to update read-only field (should fail)
    print("\n📋 Test: Update read-only field (should fail)")
    updated = update_player(user_id, team_id, player1_id, playerId="fake-id")
    if not updated:
        print(f"   ✅ Correctly rejected read-only field")
    
    # Test 10: Remove Player
    print("\n" + "=" * 60)
    print("TEST 10: Remove Player")
    print("=" * 60)
    
    # Remove a ghost player (should succeed)
    print("\n📋 Test: Remove ghost player")
    removed = remove_player(user_id, team_id, player6_id)
    if removed:
        print(f"   ✅ Ghost player removed successfully")
        # Verify it's gone
        if not verify_player(team_id, player6_id):
            print(f"   ✅ Verified player is deleted")
    
    # Test 10a: Try to remove non-existent player (should 404)
    print("\n📋 Test: Remove non-existent player")
    remove_player(user_id, team_id, str(uuid.uuid4()))
    
    # Summary
    print("\n" + "=" * 60)
    print("✅ TEST SUITE COMPLETE")
    print("=" * 60)
    print(f"Team ID: {team_id}")
    print(f"Total Players Created: {len(all_players)}")
    print(f"Players Remaining: {len(all_players) - 1} (1 removed)")
    print("\nOperations Tested:")
    print("  ✅ Add players (various configurations)")
    print("  ✅ List players (with filters)")
    print("  ✅ Get single player")
    print("  ✅ Update player (all fields)")
    print("  ✅ Remove player")
    print("  ✅ Validation errors")
    print("  ✅ Authorization checks")


def main():
    """Main test runner"""
    if len(sys.argv) < 2:
        print("Usage: python test_players.py <command> [args]")
        print("\nCommands:")
        print("  add <userId> <teamId> <firstName> [lastName] [number] [status]  - Add player")
        print("  list <userId> <teamId> [status] [isGhost]                       - List players")
        print("  get <userId> <teamId> <playerId>                                - Get player")
        print("  update <userId> <teamId> <playerId> <field> <value>             - Update player")
        print("  remove <userId> <teamId> <playerId>                             - Remove player")
        print("  verify <teamId> <playerId>                                      - Verify player exists")
        print("  create-team <userId> <name>                                     - Create test team")
        print("  full-test <userId>                                              - Run full test suite")
        sys.exit(1)
    
    command = sys.argv[1]
    
    try:
        if command == 'add':
            user_id = sys.argv[2]
            team_id = sys.argv[3]
            first_name = sys.argv[4]
            last_name = sys.argv[5] if len(sys.argv) > 5 else None
            player_number = int(sys.argv[6]) if len(sys.argv) > 6 else None
            status = sys.argv[7] if len(sys.argv) > 7 else None
            add_player(user_id, team_id, first_name, last_name, player_number, status)
        
        elif command == 'list':
            user_id = sys.argv[2]
            team_id = sys.argv[3]
            status = sys.argv[4] if len(sys.argv) > 4 else None
            is_ghost = sys.argv[5] if len(sys.argv) > 5 else None
            list_players(user_id, team_id, status, is_ghost)
        
        elif command == 'get':
            user_id = sys.argv[2]
            team_id = sys.argv[3]
            player_id = sys.argv[4]
            get_player(user_id, team_id, player_id)
        
        elif command == 'update':
            user_id = sys.argv[2]
            team_id = sys.argv[3]
            player_id = sys.argv[4]
            field = sys.argv[5]
            value = sys.argv[6] if len(sys.argv) > 6 else None
            # Handle special values
            if value == 'null':
                value = None
            elif field == 'playerNumber' and value:
                value = int(value)
            update_player(user_id, team_id, player_id, **{field: value})
        
        elif command == 'remove':
            user_id = sys.argv[2]
            team_id = sys.argv[3]
            player_id = sys.argv[4]
            remove_player(user_id, team_id, player_id)
        
        elif command == 'verify':
            team_id = sys.argv[2]
            player_id = sys.argv[3]
            verify_player(team_id, player_id)
        
        elif command == 'create-team':
            user_id = sys.argv[2]
            name = sys.argv[3]
            create_test_team(user_id, name)
        
        elif command == 'full-test':
            user_id = sys.argv[2]
            run_full_test(user_id)
        
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

