#!/usr/bin/env python3
"""
Test Teams Lambda Functions

Test script for team CRUD operations against local DynamoDB or deployed API
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


def create_team(user_id, name, description=None):
    """Test create team"""
    print(f"\n📝 Creating team: {name}")
    print(f"   Owner: {user_id}")
    
    # Import handler
    from teams.create.handler import handler
    
    # Simulate API Gateway event
    body = {"name": name}
    if description:
        body["description"] = description
    
    event = {
        'headers': {'X-User-Id': user_id},
        'body': json.dumps(body),
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
        print(f"   Name: {team['name']}")
        print(f"   Role: {team['role']}")
        return team['teamId']
    else:
        print(f"   ❌ Failed: {response['statusCode']}")
        print(f"   {response['body']}")
        return None


def get_team(team_id):
    """Test get team"""
    print(f"\n🔍 Getting team: {team_id}")
    
    from teams.get.handler import handler
    
    event = {
        'pathParameters': {'teamId': team_id},
        'requestContext': {
            'http': {
                'method': 'GET',
                'path': f'/teams/{team_id}'
            }
        }
    }
    
    response = handler(event, None)
    
    if response['statusCode'] == 200:
        team = json.loads(response['body'])
        print(f"   ✅ Team found")
        print(f"   Name: {team['name']}")
        print(f"   Owner: {team['ownerId']}")
        print(f"   Status: {team['status']}")
        return team
    else:
        print(f"   ❌ Failed: {response['statusCode']}")
        print(f"   {response['body']}")
        return None


def query_teams(user_id=None, owner_id=None):
    """Test query teams"""
    if user_id:
        print(f"\n📋 Querying teams for user: {user_id}")
    elif owner_id:
        print(f"\n📋 Querying teams owned by: {owner_id}")
    else:
        print(f"\n📋 Querying all teams")
    
    from teams.query.handler import handler
    
    query_params = {}
    if user_id:
        query_params['userId'] = user_id
    elif owner_id:
        query_params['ownerId'] = owner_id
    
    event = {
        'queryStringParameters': query_params if query_params else None,
        'requestContext': {
            'http': {
                'method': 'GET',
                'path': '/teams'
            }
        }
    }
    
    response = handler(event, None)
    
    if response['statusCode'] == 200:
        data = json.loads(response['body'])
        print(f"   ✅ Found {data['count']} team(s)")
        for team in data['teams']:
            role = team.get('role', 'N/A')
            print(f"   - {team['name']} ({team['teamId'][:8]}...) [Role: {role}]")
        return data['teams']
    else:
        print(f"   ❌ Failed: {response['statusCode']}")
        print(f"   {response['body']}")
        return []


def update_team(user_id, team_id, name=None, description=None):
    """Test update team"""
    print(f"\n✏️  Updating team: {team_id}")
    
    from teams.update.handler import handler
    
    body = {}
    if name:
        body['name'] = name
    if description is not None:
        body['description'] = description
    
    event = {
        'pathParameters': {'teamId': team_id},
        'headers': {'X-User-Id': user_id},
        'body': json.dumps(body),
        'requestContext': {
            'http': {
                'method': 'PUT',
                'path': f'/teams/{team_id}'
            }
        }
    }
    
    response = handler(event, None)
    
    if response['statusCode'] == 200:
        team = json.loads(response['body'])
        print(f"   ✅ Team updated")
        print(f"   New name: {team['name']}")
        if 'description' in team:
            print(f"   Description: {team['description']}")
        return team
    else:
        print(f"   ❌ Failed: {response['statusCode']}")
        print(f"   {response['body']}")
        return None


def delete_team(user_id, team_id):
    """Test delete team"""
    print(f"\n🗑️  Deleting team: {team_id}")
    
    from teams.delete.handler import handler
    
    event = {
        'pathParameters': {'teamId': team_id},
        'headers': {'X-User-Id': user_id},
        'requestContext': {
            'http': {
                'method': 'DELETE',
                'path': f'/teams/{team_id}'
            }
        }
    }
    
    response = handler(event, None)
    
    if response['statusCode'] == 204:
        print(f"   ✅ Team deleted (soft delete)")
        return True
    else:
        print(f"   ❌ Failed: {response['statusCode']}")
        if response.get('body'):
            print(f"   {response['body']}")
        return False


def verify_membership(user_id, team_id):
    """Verify team membership exists in DynamoDB"""
    print(f"\n🔐 Verifying membership: User {user_id[:8]}... → Team {team_id[:8]}...")
    
    table = get_table()
    response = table.get_item(
        Key={
            'PK': f'USER#{user_id}',
            'SK': f'TEAM#{team_id}'
        }
    )
    
    if 'Item' in response:
        membership = response['Item']
        print(f"   ✅ Membership found")
        print(f"   Role: {membership.get('role')}")
        print(f"   Status: {membership.get('status')}")
        return membership
    else:
        print(f"   ❌ Membership not found")
        return None


def main():
    """Main test runner"""
    if len(sys.argv) < 2:
        print("Usage: python test_teams.py <command> [args]")
        print("\nCommands:")
        print("  create <userId> <name> [description]  - Create a new team")
        print("  get <teamId>                          - Get team by ID")
        print("  query list                            - List all teams")
        print("  query user <userId>                   - List user's teams")
        print("  query owner <ownerId>                 - List teams by owner")
        print("  update <userId> <teamId> name=<name>  - Update team name")
        print("  update <userId> <teamId> desc=<desc>  - Update description")
        print("  delete <userId> <teamId>              - Delete team (soft)")
        print("  verify <userId> <teamId>              - Verify membership")
        print("  full-test <userId>                    - Run full test suite")
        sys.exit(1)
    
    command = sys.argv[1]
    
    try:
        if command == 'create':
            user_id = sys.argv[2]
            name = sys.argv[3]
            description = sys.argv[4] if len(sys.argv) > 4 else None
            create_team(user_id, name, description)
        
        elif command == 'get':
            team_id = sys.argv[2]
            get_team(team_id)
        
        elif command == 'query':
            subcommand = sys.argv[2]
            if subcommand == 'list':
                query_teams()
            elif subcommand == 'user':
                user_id = sys.argv[3]
                query_teams(user_id=user_id)
            elif subcommand == 'owner':
                owner_id = sys.argv[3]
                query_teams(owner_id=owner_id)
        
        elif command == 'update':
            user_id = sys.argv[2]
            team_id = sys.argv[3]
            updates = {}
            for arg in sys.argv[4:]:
                if '=' in arg:
                    key, value = arg.split('=', 1)
                    if key == 'name':
                        updates['name'] = value
                    elif key in ['desc', 'description']:
                        updates['description'] = value
            update_team(user_id, team_id, **updates)
        
        elif command == 'delete':
            user_id = sys.argv[2]
            team_id = sys.argv[3]
            delete_team(user_id, team_id)
        
        elif command == 'verify':
            user_id = sys.argv[2]
            team_id = sys.argv[3]
            verify_membership(user_id, team_id)
        
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


def run_full_test(user_id):
    """Run complete test suite"""
    print("=" * 60)
    print("🧪 TEAM CRUD - FULL TEST SUITE")
    print("=" * 60)
    print(f"User ID: {user_id}")
    
    # Test 1: Create teams
    print("\n" + "=" * 60)
    print("TEST 1: Create Teams")
    print("=" * 60)
    team1_id = create_team(user_id, "Seattle Sluggers", "Best team in Seattle")
    team2_id = create_team(user_id, "Portland Thunder", "Oregon's finest")
    team3_id = create_team(user_id, "Test Team 123", None)  # No description
    
    if not all([team1_id, team2_id, team3_id]):
        print("\n❌ Failed to create teams")
        return
    
    # Test 2: Verify memberships
    print("\n" + "=" * 60)
    print("TEST 2: Verify Memberships")
    print("=" * 60)
    verify_membership(user_id, team1_id)
    verify_membership(user_id, team2_id)
    
    # Test 3: Get teams
    print("\n" + "=" * 60)
    print("TEST 3: Get Teams by ID")
    print("=" * 60)
    get_team(team1_id)
    get_team(team2_id)
    
    # Test 4: Query teams
    print("\n" + "=" * 60)
    print("TEST 4: Query Operations")
    print("=" * 60)
    query_teams()  # All teams
    query_teams(user_id=user_id)  # User's teams
    query_teams(owner_id=user_id)  # Teams owned by user
    
    # Test 5: Update team
    print("\n" + "=" * 60)
    print("TEST 5: Update Team")
    print("=" * 60)
    update_team(user_id, team1_id, name="Seattle Sluggers Pro")
    update_team(user_id, team2_id, description="Updated description for Thunder")
    
    # Verify updates
    get_team(team1_id)
    get_team(team2_id)
    
    # Test 6: Delete team
    print("\n" + "=" * 60)
    print("TEST 6: Soft Delete Team")
    print("=" * 60)
    delete_team(user_id, team3_id)
    
    # Verify deletion (should return 404)
    print("\n🔍 Attempting to get deleted team (should fail):")
    get_team(team3_id)
    
    # Verify deleted team doesn't show in queries
    print("\n🔍 Querying teams (deleted team should not appear):")
    query_teams(user_id=user_id)
    
    # Test 7: Authorization test (try to update with wrong user)
    print("\n" + "=" * 60)
    print("TEST 7: Authorization Test")
    print("=" * 60)
    fake_user_id = str(uuid.uuid4())
    print(f"Attempting to update team with unauthorized user: {fake_user_id[:8]}...")
    update_team(fake_user_id, team1_id, name="Hacked Name")
    
    # Test 8: Validation tests
    print("\n" + "=" * 60)
    print("TEST 8: Validation Tests")
    print("=" * 60)
    
    print("\n🧪 Test invalid team name (too short):")
    create_team(user_id, "AB", None)
    
    print("\n🧪 Test invalid team name (special chars):")
    create_team(user_id, "Team @#$%", None)
    
    print("\n🧪 Test valid team name with spaces:")
    team4_id = create_team(user_id, "  Test   Team   With   Spaces  ", "Should be cleaned")
    if team4_id:
        team4 = get_team(team4_id)
        print(f"   Cleaned name: '{team4['name']}'")
    
    # Summary
    print("\n" + "=" * 60)
    print("✅ TEST SUITE COMPLETE")
    print("=" * 60)
    print(f"\nCreated teams:")
    print(f"  1. {team1_id} - Seattle Sluggers Pro")
    print(f"  2. {team2_id} - Portland Thunder")
    print(f"  3. {team3_id} - Test Team 123 (deleted)")
    if team4_id:
        print(f"  4. {team4_id} - Test Team With Spaces")
    
    print("\n💡 To clean up, run:")
    print(f"   python scripts/test_teams.py delete {user_id} {team1_id}")
    print(f"   python scripts/test_teams.py delete {user_id} {team2_id}")


if __name__ == '__main__':
    main()

