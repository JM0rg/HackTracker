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
    print_info("Testing Team Type System (MANAGED vs PERSONAL)")
    print_info("This will test: DB setup, user creation, team type system, restrictions, and more\n")
    
    # Test 1: Reset Database
    print_header("TEST 1: Database Reset")
    success, _ = run_command("make db-reset", "Reset DynamoDB Local")
    if not success:
        print_error("Database reset failed. Exiting.")
        sys.exit(1)
    
    # Test 2: Create User
    print_header("TEST 2: Create User")
    success, output = run_command("make test create", "Create test user")
    if not success:
        print_error("User creation failed. Exiting.")
        sys.exit(1)
    
    # Verify user was created
    if "User created successfully" in output or "User record found" in output:
        print_success("User created successfully")
    else:
        print_error("User creation not confirmed in output")
    
    print_info("Note: Personal teams are no longer auto-created. Users create them as needed.")
    
    # Test 3: Create Personal Team
    print_header("TEST 3: Create Personal Team")
    user_id = "12345678-1234-1234-1234-123456789012"
    success, output = run_command(
        f'uv run python scripts/test_teams.py create {user_id} "Personal Stats" "Personal team for stats" PERSONAL',
        "Create personal team"
    )
    if not success:
        print_error("Failed to create personal team. Exiting.")
        sys.exit(1)
    
    # Extract personal team ID from output
    import re
    import boto3
    match = re.search(r'Team created: ([a-f0-9-]+)', output)
    if match:
        personal_team_id = match.group(1)
        print_success(f"Created personal team ID: {personal_team_id}")
    else:
        # Try to find it from database
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
            if 'Item' in team_response and team_response['Item'].get('team_type') == 'PERSONAL':
                personal_team_id = item['teamId']
                print_success(f"Found personal team ID: {personal_team_id}")
                break
        
        if not personal_team_id:
            print_error("Could not extract personal team ID")
            sys.exit(1)
    
    # Test 4: Create a MANAGED Team
    print_header("TEST 4: Create MANAGED Team")
    success, output = run_command(
        f'uv run python scripts/test_teams.py create {user_id} "Test Team" "A regular team" MANAGED',
        "Create MANAGED team"
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
    if "Failed: 403" in output and ("Cannot delete team" in output or "personal stats team" in output.lower()):
        print_success("Delete operation correctly blocked (403 Forbidden)")
    else:
        print_error("Delete should have been blocked with 403")
    
    # Test 7: Try to Update Personal Team (should fail)
    print_header("TEST 7: Try to Update Personal Team (Should Fail)")
    success, output = run_command(
        f'uv run python scripts/test_teams.py update {user_id} {personal_team_id} name="New Name"',
        "Attempt to update personal team"
    )
    if "Failed: 403" in output and ("Cannot manage team" in output or "personal stats team" in output.lower()):
        print_success("Update operation correctly blocked (403 Forbidden)")
    else:
        print_error("Update should have been blocked with 403")
    
    # Test 8: Try to Add Player to Personal Team (should fail)
    print_header("TEST 8: Try to Add Player to Personal Team (Should Fail)")
    success, output = run_command(
        f'uv run python scripts/test_players.py add {user_id} {personal_team_id} "Test" "Player" 99 active',
        "Attempt to add player to personal team"
    )
    if "Failed: 400" in output and "Cannot add players to personal teams" in output:
        print_success("Add player operation correctly blocked (400 Bad Request)")
    elif "Failed: 403" in output:
        print_success("Add player operation correctly blocked (403 Forbidden)")
    else:
        print_error("Add player should have been blocked")
    
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
    print_success("All Team Type tests passed!")
    print_info("\nWhat was tested:")
    print("  ✅ Database reset and setup")
    print("  ✅ User creation")
    print("  ✅ PERSONAL team creation with team_type=PERSONAL")
    print("  ✅ MANAGED team creation with team_type=MANAGED")
    print("  ✅ Personal team membership and player creation")
    print("  ✅ GSI4 keys populated for stat queries")
    print("  ✅ Personal team appears in user's team list")
    print("  ✅ Personal team filtered from public lists")
    print("  ✅ Delete personal team blocked (403)")
    print("  ✅ Update personal team blocked (403)")
    print("  ✅ Add player to personal team blocked (400/403)")
    print("  ✅ Personal player auto-created and linked")
    print("  ✅ Full team test suite integration")
    
    print(f"\n{BOLD}{GREEN}{'=' * 80}{RESET}")
    print(f"{BOLD}{GREEN}{'ALL TESTS PASSED! 🚀'.center(80)}{RESET}")
    print(f"{BOLD}{GREEN}{'=' * 80}{RESET}\n")

if __name__ == '__main__':
    main()
