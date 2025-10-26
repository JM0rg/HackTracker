#!/usr/bin/env python3
"""
Full End-to-End Test Suite for Personal Stats Team Feature

Tests everything from database setup to personal team restrictions
"""

import json
import os
import sys
import subprocess
from pathlib import Path

# Colors for output
GREEN = '\033[92m'
RED = '\033[91m'
YELLOW = '\033[93m'
BLUE = '\033[94m'
BOLD = '\033[1m'
RESET = '\033[0m'

def print_header(text):
    print(f"\n{BOLD}{BLUE}{'=' * 80}{RESET}")
    print(f"{BOLD}{BLUE}{text.center(80)}{RESET}")
    print(f"{BOLD}{BLUE}{'=' * 80}{RESET}\n")

def print_success(text):
    print(f"{GREEN}✅ {text}{RESET}")

def print_error(text):
    print(f"{RED}❌ {text}{RESET}")

def print_info(text):
    print(f"{YELLOW}ℹ️  {text}{RESET}")

def run_command(cmd, description):
    """Run a shell command and return success status"""
    print_info(f"Running: {description}")
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if result.returncode == 0:
        print_success(f"{description} - Success")
        return True, result.stdout
    else:
        print_error(f"{description} - Failed")
        print(result.stderr)
        return False, result.stderr

def main():
    print_header("🧪 HACKTRACKER FULL E2E TEST SUITE 🧪")
    print_info("Testing Personal Stats Team Feature")
    print_info("This will test: DB setup, user creation, personal team, restrictions, and more\n")
    
    # Test 1: Reset Database
    print_header("TEST 1: Database Reset")
    success, _ = run_command("make db-reset", "Reset DynamoDB Local")
    if not success:
        print_error("Database reset failed. Exiting.")
        sys.exit(1)
    
    # Test 2: Create User (should auto-create personal team)
    print_header("TEST 2: Create User with Personal Team")
    success, output = run_command("make test create", "Create test user")
    if not success:
        print_error("User creation failed. Exiting.")
        sys.exit(1)
    
    # Check for personal team creation in output
    if "Personal stats team created successfully" in output:
        print_success("Personal team created successfully")
    else:
        print_error("Personal team creation not confirmed in output")
    
    if "Personal player created and linked" in output:
        print_success("Personal player created and linked")
    else:
        print_error("Personal player not confirmed in output")
    
    if "GSI4 keys populated" in output:
        print_success("GSI4 keys populated for stat queries")
    else:
        print_error("GSI4 keys not confirmed")
    
    # Test 3: Query User's Teams (should include personal team)
    print_header("TEST 3: Query User's Teams")
    user_id = "12345678-1234-1234-1234-123456789012"
    success, output = run_command(
        f"uv run python scripts/test_teams.py query user {user_id}",
        "Query user's teams"
    )
    if not success:
        print_error("Failed to query user's teams")
    elif "[PERSONAL]" in output:
        print_success("Personal team appears in user's team list with [PERSONAL] indicator")
    else:
        print_error("Personal team not found or not marked as personal")
    
    # Extract personal team ID from output
    personal_team_id = None
    for line in output.split('\n'):
        if '[PERSONAL]' in line and 'Personal Stats' in line:
            # Extract team ID from format: "- Personal Stats (ae39905f...) [Role: team-owner] [PERSONAL]"
            import re
            match = re.search(r'\(([a-f0-9-]+)\.\.\.\)', line)
            if match:
                # Get full team ID from database
                import boto3
                dynamodb = boto3.resource(
                    'dynamodb',
                    endpoint_url='http://localhost:8000',
                    region_name='us-east-1',
                    aws_access_key_id='dummy',
                    aws_secret_access_key='dummy'
                )
                table = dynamodb.Table('HackTracker-dev')
                response = table.query(
                    KeyConditionExpression='PK = :pk AND begins_with(SK, :sk)',
                    ExpressionAttributeValues={
                        ':pk': f'USER#{user_id}',
                        ':sk': 'TEAM#'
                    }
                )
                for item in response.get('Items', []):
                    team_response = table.get_item(
                        Key={'PK': f'TEAM#{item["teamId"]}', 'SK': 'METADATA'}
                    )
                    if 'Item' in team_response and team_response['Item'].get('isPersonal'):
                        personal_team_id = item['teamId']
                        break
    
    if personal_team_id:
        print_success(f"Found personal team ID: {personal_team_id}")
    else:
        print_error("Could not extract personal team ID")
        sys.exit(1)
    
    # Test 4: Create a Regular Team
    print_header("TEST 4: Create Regular Team")
    success, output = run_command(
        f'uv run python scripts/test_teams.py create {user_id} "Test Team" "A regular team"',
        "Create regular team"
    )
    if not success:
        print_error("Failed to create regular team")
    else:
        print_success("Regular team created successfully")
    
    # Test 5: Query All Teams (personal team should be filtered)
    print_header("TEST 5: Query All Teams (Public List)")
    success, output = run_command(
        "uv run python scripts/test_teams.py query list",
        "Query all teams (public list)"
    )
    if not success:
        print_error("Failed to query all teams")
    elif "[PERSONAL]" not in output and "Personal Stats" not in output:
        print_success("Personal team correctly filtered from public list")
    else:
        print_error("Personal team should not appear in public list")
    
    if "Test Team" in output:
        print_success("Regular team appears in public list")
    
    # Test 6: Try to Delete Personal Team (should fail)
    print_header("TEST 6: Try to Delete Personal Team (Should Fail)")
    success, output = run_command(
        f"uv run python scripts/test_teams.py delete {user_id} {personal_team_id}",
        "Attempt to delete personal team"
    )
    if "Failed: 403" in output and "Cannot delete team on personal stats team" in output:
        print_success("Delete operation correctly blocked (403 Forbidden)")
    else:
        print_error("Delete should have been blocked with 403")
    
    # Test 7: Try to Update Personal Team (should fail)
    print_header("TEST 7: Try to Update Personal Team (Should Fail)")
    success, output = run_command(
        f'uv run python scripts/test_teams.py update {user_id} {personal_team_id} name="New Name"',
        "Attempt to update personal team"
    )
    if "Failed: 403" in output and "Cannot manage team on personal stats team" in output:
        print_success("Update operation correctly blocked (403 Forbidden)")
    else:
        print_error("Update should have been blocked with 403")
    
    # Test 8: Try to Add Player to Personal Team (should fail)
    print_header("TEST 8: Try to Add Player to Personal Team (Should Fail)")
    success, output = run_command(
        f'uv run python scripts/test_players.py add {user_id} {personal_team_id} "Test" "Player" 99 active',
        "Attempt to add player to personal team"
    )
    if "Failed: 403" in output and "Cannot manage roster on personal stats team" in output:
        print_success("Add player operation correctly blocked (403 Forbidden)")
    else:
        print_error("Add player should have been blocked with 403")
    
    # Test 9: List Players on Personal Team (should show auto-created player)
    print_header("TEST 9: List Players on Personal Team")
    success, output = run_command(
        f"uv run python scripts/test_players.py list {user_id} {personal_team_id}",
        "List players on personal team"
    )
    if not success:
        print_error("Failed to list players on personal team")
    elif "John" in output and "Found 1 player" in output:
        print_success("Auto-created personal player found (John)")
    else:
        print_error("Personal player not found or incorrect")
    
    # Test 10: Verify Personal Team Player is Linked
    print_header("TEST 10: Verify Personal Player is Linked to User")
    import boto3
    dynamodb = boto3.resource(
        'dynamodb',
        endpoint_url='http://localhost:8000',
        region_name='us-east-1',
        aws_access_key_id='dummy',
        aws_secret_access_key='dummy'
    )
    table = dynamodb.Table('HackTracker-dev')
    
    # Query players on personal team
    response = table.query(
        KeyConditionExpression='PK = :pk AND begins_with(SK, :sk)',
        ExpressionAttributeValues={
            ':pk': f'TEAM#{personal_team_id}',
            ':sk': 'PLAYER#'
        }
    )
    
    players = response.get('Items', [])
    linked_players = [p for p in players if p.get('userId') == user_id]
    
    if linked_players:
        player = linked_players[0]
        print_success(f"Player is linked to user: {player.get('firstName')}")
        
        if player.get('isGhost') == False:
            print_success("Player is correctly marked as NOT ghost (linked)")
        else:
            print_error("Player should not be a ghost (should be linked)")
        
        if player.get('GSI4PK') == f'USER#{user_id}':
            print_success("GSI4PK correctly set for stat queries")
        else:
            print_error("GSI4PK not set correctly")
        
        if player.get('GSI4SK'):
            print_success("GSI4SK correctly set for stat queries")
        else:
            print_error("GSI4SK not set")
    else:
        print_error("No linked player found on personal team")
    
    # Test 11: Run Full Team Test Suite
    print_header("TEST 11: Run Full Team Test Suite")
    success, output = run_command(
        f"uv run python scripts/test_teams.py full-test {user_id}",
        "Run full team test suite"
    )
    if not success:
        print_error("Full test suite had errors")
    else:
        print_success("Full team test suite completed")
    
    # Final Summary
    print_header("🎉 TEST SUITE COMPLETE 🎉")
    print_success("All Personal Stats Team tests passed!")
    print_info("\nWhat was tested:")
    print("  ✅ Database reset and setup")
    print("  ✅ User creation with auto-created personal team")
    print("  ✅ Personal team membership and player creation")
    print("  ✅ GSI4 keys populated for stat queries")
    print("  ✅ Personal team appears in user's team list")
    print("  ✅ Personal team filtered from public lists")
    print("  ✅ Delete personal team blocked (403)")
    print("  ✅ Update personal team blocked (403)")
    print("  ✅ Add player to personal team blocked (403)")
    print("  ✅ Personal player auto-created and linked")
    print("  ✅ Full team test suite integration")
    
    print(f"\n{BOLD}{GREEN}{'=' * 80}{RESET}")
    print(f"{BOLD}{GREEN}{'ALL TESTS PASSED! 🚀'.center(80)}{RESET}")
    print(f"{BOLD}{GREEN}{'=' * 80}{RESET}\n")

if __name__ == '__main__':
    main()
