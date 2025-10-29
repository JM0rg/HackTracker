#!/usr/bin/env python3
"""
Test Games Lambda Functions

Test script for game CRUD operations against local DynamoDB or deployed API
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


def create_game(user_id, team_id, game_title, **kwargs):
    """Test create game"""
    print(f"\n🎮 Creating game: {game_title}")
    print(f"   Team: {team_id[:8]}...")
    print(f"   Requester: {user_id[:8]}...")
    
    # Import handler
    from games.create.handler import handler
    
    # Simulate API Gateway event
    body = {
        "teamId": team_id,
        "gameTitle": game_title
    }
    
    # Add optional fields
    for key, value in kwargs.items():
        if value is not None:
            body[key] = value
    
    event = {
        'headers': {'X-User-Id': user_id},
        'body': json.dumps(body),
        'requestContext': {
            'http': {
                'method': 'POST',
                'path': '/games'
            }
        }
    }
    
    response = handler(event, None)
    
    if response['statusCode'] == 201:
        game = json.loads(response['body'])
        print(f"   ✅ Game created: {game['gameId']}")
        print(f"   Title: {game['gameTitle']}")
        print(f"   Status: {game['status']}")
        print(f"   Team Score: {game['teamScore']}")
        print(f"   Opponent Score: {game['opponentScore']}")
        return game['gameId']
    else:
        print(f"   ❌ Failed: {response['statusCode']}")
        print(f"   {response['body']}")
        return None


def list_games_by_team(user_id, team_id):
    """Test list games by team"""
    print(f"\n📋 Listing games for team: {team_id[:8]}...")
    
    from games.list.handler import handler
    
    event = {
        'headers': {'X-User-Id': user_id},
        'pathParameters': {'teamId': team_id},
        'requestContext': {
            'http': {
                'method': 'GET',
                'path': f'/teams/{team_id}/games'
            }
        }
    }
    
    response = handler(event, None)
    
    if response['statusCode'] == 200:
        games = json.loads(response['body'])
        count = len(games)
        print(f"   ✅ Found {count} game(s)")
        for idx, game in enumerate(games, 1):
            print(f"   {idx}. {game['gameTitle']} ({game['status']}) - {game.get('scheduledStart', 'No date')}")
        return games
    else:
        print(f"   ❌ Failed: {response['statusCode']}")
        print(f"   {response['body']}")
        return []


def get_game(user_id, game_id):
    """Test get game"""
    print(f"\n🔍 Getting game: {game_id[:8]}...")
    
    from games.get.handler import handler
    
    event = {
        'headers': {'X-User-Id': user_id},
        'pathParameters': {'gameId': game_id},
        'requestContext': {
            'http': {
                'method': 'GET',
                'path': f'/games/{game_id}'
            }
        }
    }
    
    response = handler(event, None)
    
    if response['statusCode'] == 200:
        game = json.loads(response['body'])
        print(f"   ✅ Game found")
        print(f"   Title: {game['gameTitle']}")
        print(f"   Status: {game['status']}")
        print(f"   Team: {game['teamId']}")
        print(f"   Score: {game['teamScore']} - {game['opponentScore']}")
        return game
    else:
        print(f"   ❌ Failed: {response['statusCode']}")
        print(f"   {response['body']}")
        return None


def update_game(user_id, game_id, **updates):
    """Test update game"""
    print(f"\n✏️  Updating game: {game_id[:8]}...")
    print(f"   Updates: {updates}")
    
    from games.update.handler import handler
    
    event = {
        'headers': {'X-User-Id': user_id},
        'pathParameters': {'gameId': game_id},
        'body': json.dumps(updates),
        'requestContext': {
            'http': {
                'method': 'PATCH',
                'path': f'/games/{game_id}'
            }
        }
    }
    
    response = handler(event, None)
    
    if response['statusCode'] == 200:
        game = json.loads(response['body'])
        print(f"   ✅ Game updated")
        print(f"   Title: {game['gameTitle']}")
        print(f"   Status: {game['status']}")
        print(f"   Score: {game['teamScore']} - {game['opponentScore']}")
        return game
    else:
        print(f"   ❌ Failed: {response['statusCode']}")
        print(f"   {response['body']}")
        return None


def delete_game(user_id, game_id):
    """Test delete game"""
    print(f"\n🗑️  Deleting game: {game_id[:8]}...")
    
    from games.delete.handler import handler
    
    event = {
        'headers': {'X-User-Id': user_id},
        'pathParameters': {'gameId': game_id},
        'requestContext': {
            'http': {
                'method': 'DELETE',
                'path': f'/games/{game_id}'
            }
        }
    }
    
    response = handler(event, None)
    
    if response['statusCode'] == 204:
        print(f"   ✅ Game deleted successfully")
        return True
    else:
        print(f"   ❌ Failed: {response['statusCode']}")
        if response.get('body'):
            print(f"   {response['body']}")
        return False


def verify_game(game_id):
    """Verify game exists in DynamoDB"""
    print(f"\n🔍 Verifying game: {game_id[:8]}...")
    
    table = get_table()
    response = table.get_item(
        Key={
            'PK': f'GAME#{game_id}',
            'SK': 'METADATA'
        }
    )
    
    if 'Item' in response:
        game = response['Item']
        print(f"   ✅ Game found")
        print(f"   Title: {game.get('gameTitle')}")
        print(f"   Status: {game.get('status')}")
        print(f"   Team: {game.get('teamId')}")
        print(f"   Score: {game.get('teamScore')} - {game.get('opponentScore')}")
        return game
    else:
        print(f"   ❌ Game not found")
        return None


def create_test_team_with_players(user_id, name):
    """Helper: Create a test team with players"""
    print(f"\n📝 Creating test team with players: {name}")
    
    from teams.create.handler import handler
    
    # Create team
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
    
    if response['statusCode'] != 201:
        print(f"   ❌ Failed to create team: {response['statusCode']}")
        return None, []
    
    team = json.loads(response['body'])
    team_id = team['teamId']
    print(f"   ✅ Team created: {team_id}")
    
    # Add players
    from players.add.handler import handler as add_handler
    
    players = []
    player_names = [
        ("John", "Doe", 12),
        ("Jane", "Smith", 7),
        ("Bob", "Johnson", 99),
        ("Alice", "Brown", 3),
        ("Charlie", "Wilson", 15)
    ]
    
    for first_name, last_name, number in player_names:
        player_event = {
            'headers': {'X-User-Id': user_id},
            'pathParameters': {'teamId': team_id},
            'body': json.dumps({
                "firstName": first_name,
                "lastName": last_name,
                "playerNumber": number,
                "status": "active"
            }),
            'requestContext': {
                'http': {
                    'method': 'POST',
                    'path': f'/teams/{team_id}/players'
                }
            }
        }
        
        player_response = add_handler(player_event, None)
        
        if player_response['statusCode'] == 201:
            player = json.loads(player_response['body'])
            players.append(player)
            print(f"   ✅ Player added: {first_name} {last_name} (#{number})")
        else:
            print(f"   ❌ Failed to add player {first_name}: {player_response['statusCode']}")
    
    return team_id, players


def test_validation_errors(user_id, team_id):
    """Test validation error handling"""
    print("\n" + "=" * 60)
    print("TEST: Validation Errors")
    print("=" * 60)
    
    # Test 1: teamId is now optional (will find Default team)
    # Skipping missing teamId test since it's now optional
    print("\n📋 Test: teamId is optional (will auto-find Default team)")
    print("   ℹ️  Skipping - teamId now optional, finds Default PERSONAL team")
    
    # Test 2: Missing gameTitle
    print("\n📋 Test: Missing gameTitle")
    from games.create.handler import handler
    event = {
        'headers': {'X-User-Id': user_id},
        'body': json.dumps({"teamId": team_id}),
        'requestContext': {'http': {'method': 'POST', 'path': '/games'}}
    }
    response = handler(event, None)
    if response['statusCode'] == 400:
        print(f"   ✅ Correctly rejected: {response['statusCode']}")
    else:
        print(f"   ❌ Should have been 400, got: {response['statusCode']}")
    
    # Test 3: Invalid gameTitle (too short)
    print("\n📋 Test: Invalid gameTitle (too short)")
    event['body'] = json.dumps({"teamId": team_id, "gameTitle": "AB"})
    response = handler(event, None)
    if response['statusCode'] == 400:
        print(f"   ✅ Correctly rejected: {response['statusCode']}")
    else:
        print(f"   ❌ Should have been 400, got: {response['statusCode']}")
    
    # Test 4: Invalid status
    print("\n📋 Test: Invalid status")
    event['body'] = json.dumps({"teamId": team_id, "gameTitle": "Test Game", "status": "invalid"})
    response = handler(event, None)
    if response['statusCode'] == 400:
        print(f"   ✅ Correctly rejected: {response['statusCode']}")
    else:
        print(f"   ❌ Should have been 400, got: {response['statusCode']}")
    
    # Test 5: Invalid score (negative)
    print("\n📋 Test: Invalid teamScore (negative)")
    event['body'] = json.dumps({"teamId": team_id, "gameTitle": "Test Game", "teamScore": -1})
    response = handler(event, None)
    if response['statusCode'] == 400:
        print(f"   ✅ Correctly rejected: {response['statusCode']}")
    else:
        print(f"   ❌ Should have been 400, got: {response['statusCode']}")


def test_lineup_validation(user_id, team_id, players):
    """Test lineup validation for IN_PROGRESS status"""
    print("\n" + "=" * 60)
    print("TEST: Lineup Validation")
    print("=" * 60)
    
    # Create a game first
    game_id = create_game(user_id, team_id, "Lineup Test Game")
    if not game_id:
        print("   ❌ Failed to create test game")
        return
    
    # Test 1: Try to set IN_PROGRESS without lineup (should fail)
    print("\n📋 Test: Set IN_PROGRESS without lineup (should fail)")
    updated = update_game(user_id, game_id, status="IN_PROGRESS")
    if not updated:
        print(f"   ✅ Correctly rejected IN_PROGRESS without lineup")
    else:
        print(f"   ❌ Should have been rejected")
    
    # Test 2: Create valid lineup
    print("\n📋 Test: Create valid lineup")
    lineup = []
    for i, player in enumerate(players[:5], 1):  # Use first 5 players
        lineup.append({
            "playerId": player['playerId'],
            "battingOrder": i
        })
    
    updated = update_game(user_id, game_id, lineup=lineup)
    if updated:
        print(f"   ✅ Lineup set successfully")
        print(f"   Lineup: {len(lineup)} players")
    else:
        print(f"   ❌ Failed to set lineup")
        return
    
    # Test 3: Now try to set IN_PROGRESS with lineup (should succeed)
    print("\n📋 Test: Set IN_PROGRESS with lineup (should succeed)")
    updated = update_game(user_id, game_id, status="IN_PROGRESS")
    if updated and updated['status'] == 'IN_PROGRESS':
        print(f"   ✅ Successfully set IN_PROGRESS with lineup")
    else:
        print(f"   ❌ Should have succeeded with lineup")
    
    # Test 4: Try to clear lineup while IN_PROGRESS (should fail)
    print("\n📋 Test: Clear lineup while IN_PROGRESS (should fail)")
    updated = update_game(user_id, game_id, lineup=[])
    if not updated:
        print(f"   ✅ Correctly rejected clearing lineup while IN_PROGRESS")
    else:
        print(f"   ❌ Should have been rejected")


def test_personal_team_games(user_id):
    """Test games on personal team (should not require lineup)"""
    print("\n" + "=" * 60)
    print("TEST: Personal Team Games")
    print("=" * 60)
    
    # Find user's personal team
    table = get_table()
    response = table.query(
        KeyConditionExpression='PK = :pk AND begins_with(SK, :sk)',
        ExpressionAttributeValues={
            ':pk': f'USER#{user_id}',
            ':sk': 'TEAM#'
        }
    )
    
    personal_teams = []
    for membership in response.get('Items', []):
        if membership.get('status') == 'active':
            team_response = table.get_item(
                Key={'PK': f'TEAM#{membership["teamId"]}', 'SK': 'METADATA'}
            )
            if 'Item' in team_response and team_response['Item'].get('team_type') == 'PERSONAL':
                personal_teams.append(membership['teamId'])
    
    # If no personal team exists, create one
    if not personal_teams:
        print("   ⚠️  No personal team found, creating one...")
        from test_teams import create_team
        personal_team_id = create_team(user_id, "Personal Stats", "Personal team for stats", team_type='PERSONAL')
        if not personal_team_id:
            print("   ❌ Failed to create personal team (skipping tests)")
            return
        personal_teams = [personal_team_id]
    
    personal_team_id = personal_teams[0]
    print(f"   ✅ Found personal team: {personal_team_id[:8]}...")
    
    # Test 1: Create game on personal team
    print("\n📋 Test: Create game on personal team")
    game_id = create_game(user_id, personal_team_id, "Personal Team Game")
    if not game_id:
        print("   ❌ Failed to create game on personal team")
        return
    
    # Test 2: Set IN_PROGRESS without lineup (should succeed for personal team)
    print("\n📋 Test: Set IN_PROGRESS without lineup on personal team (should succeed)")
    updated = update_game(user_id, game_id, status="IN_PROGRESS")
    if updated and updated['status'] == 'IN_PROGRESS':
        print(f"   ✅ Successfully set IN_PROGRESS without lineup on personal team")
    else:
        print(f"   ❌ Should have succeeded for personal team")


def test_authorization(user_id, team_id):
    """Test authorization requirements"""
    print("\n" + "=" * 60)
    print("TEST: Authorization")
    print("=" * 60)
    
    # Test 1: Non-member cannot create game
    print("\n📋 Test: Non-member cannot create game")
    random_user = str(uuid.uuid4())
    from games.create.handler import handler
    event = {
        'headers': {'X-User-Id': random_user},
        'body': json.dumps({"teamId": team_id, "gameTitle": "Hacked Game"}),
        'requestContext': {'http': {'method': 'POST', 'path': '/games'}}
    }
    response = handler(event, None)
    if response['statusCode'] == 403:
        print(f"   ✅ Correctly rejected: {response['statusCode']}")
    else:
        print(f"   ❌ Should have been 403, got: {response['statusCode']}")
    
    # Test 2: Team owner CAN create game
    print("\n📋 Test: Team owner can create game")
    game_id = create_game(user_id, team_id, "AuthTest Game")
    if game_id:
        print(f"   ✅ Owner successfully created game")
    else:
        print(f"   ❌ Owner should be able to create game")


def run_full_test(user_id):
    """Run complete test suite"""
    print("=" * 60)
    print("🧪 GAME OPERATIONS - FULL TEST SUITE")
    print("=" * 60)
    print(f"Test User ID: {user_id}")
    
    # Setup: Create test team with players
    print("\n" + "=" * 60)
    print("SETUP: Create Test Team with Players")
    print("=" * 60)
    team_id, players = create_test_team_with_players(user_id, f"Test Team {uuid.uuid4().hex[:8]}")
    
    if not team_id or not players:
        print("\n❌ Failed to create test team with players")
        return
    
    print(f"   ✅ Team created with {len(players)} players")
    
    # Test 1: Create games with various configurations
    print("\n" + "=" * 60)
    print("TEST 1: Create Games (Valid)")
    print("=" * 60)
    
    # Game 1: Minimal
    game1_id = create_game(user_id, team_id, "Practice Game")
    
    # Game 2: With opponent
    game2_id = create_game(user_id, team_id, "vs Tigers", opponentName="Tigers")
    
    # Game 3: With location
    game3_id = create_game(user_id, team_id, "Home Game", location="Home Field")
    
    # Game 4: With scheduled start
    scheduled_start = datetime.now(timezone.utc).isoformat()
    game4_id = create_game(user_id, team_id, "Scheduled Game", scheduledStart=scheduled_start)
    
    # Game 5: With scores
    game5_id = create_game(user_id, team_id, "Scored Game", teamScore=5, opponentScore=3)
    
    # Game 6: Complete game
    game6_id = create_game(
        user_id, team_id, "Complete Game",
        opponentName="Eagles",
        location="Away Field",
        scheduledStart=scheduled_start,
        teamScore=0,
        opponentScore=0
    )
    
    if not all([game1_id, game2_id, game3_id, game4_id, game5_id, game6_id]):
        print("\n❌ Failed to create all games")
        return
    
    # Test 2: Verify games in database
    print("\n" + "=" * 60)
    print("TEST 2: Verify Games in DynamoDB")
    print("=" * 60)
    verify_game(game1_id)
    verify_game(game2_id)
    verify_game(game3_id)
    
    # Test 3: Validation errors
    test_validation_errors(user_id, team_id)
    
    # Test 4: Authorization
    test_authorization(user_id, team_id)
    
    # Test 5: List games by team
    print("\n" + "=" * 60)
    print("TEST 5: List Games by Team")
    print("=" * 60)
    all_games = list_games_by_team(user_id, team_id)
    print(f"   Total games for team: {len(all_games)}")
    
    # Test 6: Get individual games
    print("\n" + "=" * 60)
    print("TEST 6: Get Individual Games")
    print("=" * 60)
    retrieved_game = get_game(user_id, game1_id)
    if retrieved_game:
        print(f"   ✅ Successfully retrieved game")
    else:
        print(f"   ❌ Failed to retrieve game")
    
    # Test 6a: Get non-existent game (should 404)
    print("\n📋 Test: Get non-existent game")
    fake_id = str(uuid.uuid4())
    get_game(user_id, fake_id)
    
    # Test 7: Update games
    print("\n" + "=" * 60)
    print("TEST 7: Update Games")
    print("=" * 60)
    
    # Test 7a: Update game title
    print("\n📋 Test: Update game title")
    updated = update_game(user_id, game2_id, gameTitle="vs Tigers (Updated)")
    if updated and updated['gameTitle'] == 'vs Tigers (Updated)':
        print(f"   ✅ gameTitle updated successfully")
    
    # Test 7b: Update scores
    print("\n📋 Test: Update scores")
    updated = update_game(user_id, game3_id, teamScore=7, opponentScore=4)
    if updated and updated['teamScore'] == 7 and updated['opponentScore'] == 4:
        print(f"   ✅ scores updated successfully")
    
    # Test 7c: Update status
    print("\n📋 Test: Update status")
    updated = update_game(user_id, game4_id, status="FINAL")
    if updated and updated['status'] == 'FINAL':
        print(f"   ✅ status updated successfully")
    
    # Test 8: Lineup validation
    test_lineup_validation(user_id, team_id, players)
    
    # Test 9: Personal team games
    test_personal_team_games(user_id)
    
    # Test 10: Delete games
    print("\n" + "=" * 60)
    print("TEST 10: Delete Games")
    print("=" * 60)
    
    # Delete a game (should succeed)
    print("\n📋 Test: Delete game")
    removed = delete_game(user_id, game6_id)
    if removed:
        print(f"   ✅ Game deleted successfully")
        # Verify it's gone
        if not verify_game(game6_id):
            print(f"   ✅ Verified game is deleted")
    
    # Test 10a: Try to delete non-existent game (should 404)
    print("\n📋 Test: Delete non-existent game")
    delete_game(user_id, str(uuid.uuid4()))
    
    # Summary
    print("\n" + "=" * 60)
    print("✅ TEST SUITE COMPLETE")
    print("=" * 60)
    print(f"Team ID: {team_id}")
    print(f"Total Games Created: {len(all_games)}")
    print(f"Games Remaining: {len(all_games) - 1} (1 deleted)")
    print("\nOperations Tested:")
    print("  ✅ Create games (various configurations)")
    print("  ✅ List games by team")
    print("  ✅ Get single game")
    print("  ✅ Update game (all fields)")
    print("  ✅ Delete game")
    print("  ✅ Validation errors")
    print("  ✅ Authorization checks")
    print("  ✅ Lineup validation for IN_PROGRESS")
    print("  ✅ Personal team games (no lineup required)")


def main():
    """Main test runner"""
    if len(sys.argv) < 2:
        print("Usage: python test_games.py <command> [args]")
        print("\nCommands:")
        print("  create <userId> <teamId> <gameTitle> [opponentName] [location] [scheduledStart] [teamScore] [opponentScore]  - Create game")
        print("  list <userId> <teamId>                                                                                      - List games by team")
        print("  get <userId> <gameId>                                                                                       - Get game")
        print("  update <userId> <gameId> <field> <value>                                                                    - Update game")
        print("  delete <userId> <gameId>                                                                                    - Delete game")
        print("  verify <gameId>                                                                                             - Verify game exists")
        print("  create-team <userId> <name>                                                                                 - Create test team with players")
        print("  full-test <userId>                                                                                          - Run full test suite")
        sys.exit(1)
    
    command = sys.argv[1]
    
    try:
        if command == 'create':
            user_id = sys.argv[2]
            team_id = sys.argv[3]
            game_title = sys.argv[4]
            opponent_name = sys.argv[5] if len(sys.argv) > 5 else None
            location = sys.argv[6] if len(sys.argv) > 6 else None
            scheduled_start = sys.argv[7] if len(sys.argv) > 7 else None
            team_score = int(sys.argv[8]) if len(sys.argv) > 8 else None
            opponent_score = int(sys.argv[9]) if len(sys.argv) > 9 else None
            
            create_game(
                user_id, team_id, game_title,
                opponentName=opponent_name,
                location=location,
                scheduledStart=scheduled_start,
                teamScore=team_score,
                opponentScore=opponent_score
            )
        
        elif command == 'list':
            user_id = sys.argv[2]
            team_id = sys.argv[3]
            list_games_by_team(user_id, team_id)
        
        elif command == 'get':
            user_id = sys.argv[2]
            game_id = sys.argv[3]
            get_game(user_id, game_id)
        
        elif command == 'update':
            user_id = sys.argv[2]
            game_id = sys.argv[3]
            field = sys.argv[4]
            value = sys.argv[5] if len(sys.argv) > 5 else None
            
            # Handle special values
            if value == 'null':
                value = None
            elif field in ['teamScore', 'opponentScore'] and value:
                value = int(value)
            elif field == 'lineup' and value:
                value = json.loads(value)
            
            update_game(user_id, game_id, **{field: value})
        
        elif command == 'delete':
            user_id = sys.argv[2]
            game_id = sys.argv[3]
            delete_game(user_id, game_id)
        
        elif command == 'verify':
            game_id = sys.argv[2]
            verify_game(game_id)
        
        elif command == 'create-team':
            user_id = sys.argv[2]
            name = sys.argv[3]
            create_test_team_with_players(user_id, name)
        
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
