#!/bin/bash
# Comprehensive test script for all Lambda functions
# Tests: User → Team → Player → Game CRUD operations

set -e

USER_ID="12345678-1234-1234-1234-123456789012"

echo "🧪 ========================================"
echo "🧪 HACKTRACKER COMPREHENSIVE TEST SUITE"
echo "🧪 ========================================"
echo ""

# Step 1: Create User
echo "📝 STEP 1: Creating User..."
uv run python scripts/test_users.py create
echo ""

# Step 2: Create Teams
echo "📝 STEP 2: Creating Teams..."
TEAM1_ID=$(uv run python scripts/test_teams.py create $USER_ID "Test Team 1" "First test team" MANAGED | grep -oP 'Team created: \K[a-f0-9-]+' || echo "")
TEAM2_ID=$(uv run python scripts/test_teams.py create $USER_ID "Test Team 2" "Second test team" MANAGED | grep -oP 'Team created: \K[a-f0-9-]+' || echo "")
PERSONAL_TEAM_ID=$(uv run python scripts/test_teams.py create $USER_ID "Personal Stats" "Personal team" PERSONAL | grep -oP 'Team created: \K[a-f0-9-]+' || echo "")

if [ -z "$TEAM1_ID" ]; then
    echo "❌ Failed to create team 1"
    exit 1
fi
echo "✅ Created teams: $TEAM1_ID, $TEAM2_ID, $PERSONAL_TEAM_ID"
echo ""

# Step 3: Query Teams
echo "📝 STEP 3: Querying Teams..."
uv run python scripts/test_teams.py query user $USER_ID
echo ""

# Step 4: Get Team
echo "📝 STEP 4: Getting Team..."
uv run python scripts/test_teams.py get $TEAM1_ID
echo ""

# Step 5: Add Players
echo "📝 STEP 5: Adding Players..."
PLAYER1_ID=$(uv run python scripts/test_players.py add $USER_ID $TEAM1_ID "John" "Doe" 12 active | grep -oP 'Player created: \K[a-f0-9-]+' || echo "")
PLAYER2_ID=$(uv run python scripts/test_players.py add $USER_ID $TEAM1_ID "Jane" "Smith" 7 active | grep -oP 'Player created: \K[a-f0-9-]+' || echo "")
PLAYER3_ID=$(uv run python scripts/test_players.py add $USER_ID $TEAM1_ID "Bob" "Johnson" 99 sub | grep -oP 'Player created: \K[a-f0-9-]+' || echo "")

if [ -z "$PLAYER1_ID" ]; then
    echo "❌ Failed to create player 1"
    exit 1
fi
echo "✅ Created players: $PLAYER1_ID, $PLAYER2_ID, $PLAYER3_ID"
echo ""

# Step 6: List Players
echo "📝 STEP 6: Listing Players..."
uv run python scripts/test_players.py list $USER_ID $TEAM1_ID
echo ""

# Step 7: Get Player
echo "📝 STEP 7: Getting Player..."
uv run python scripts/test_players.py get $USER_ID $TEAM1_ID $PLAYER1_ID
echo ""

# Step 8: Update Player
echo "📝 STEP 8: Updating Player..."
uv run python scripts/test_players.py update $USER_ID $TEAM1_ID $PLAYER1_ID firstName "Johnny"
echo ""

# Step 9: Create Games
echo "📝 STEP 9: Creating Games..."
GAME1_ID=$(uv run python scripts/test_games.py create $USER_ID $TEAM1_ID "Tigers" | grep -oP 'Game created: \K[a-f0-9-]+' || echo "")
GAME2_ID=$(uv run python scripts/test_games.py create $USER_ID $TEAM1_ID "Eagles" "Home Field" | grep -oP 'Game created: \K[a-f0-9-]+' || echo "")

if [ -z "$GAME1_ID" ]; then
    echo "❌ Failed to create game 1"
    exit 1
fi
echo "✅ Created games: $GAME1_ID, $GAME2_ID"
echo ""

# Step 10: List Games
echo "📝 STEP 10: Listing Games..."
uv run python scripts/test_games.py list $USER_ID $TEAM1_ID
echo ""

# Step 11: Get Game
echo "📝 STEP 11: Getting Game..."
uv run python scripts/test_games.py get $USER_ID $GAME1_ID
echo ""

# Step 12: Update Game
echo "📝 STEP 12: Updating Game..."
uv run python scripts/test_games.py update $USER_ID $GAME1_ID opponentName "Tigers (Updated)"
echo ""

# Step 13: Update Team
echo "📝 STEP 13: Updating Team..."
uv run python scripts/test_teams.py update $USER_ID $TEAM1_ID name="Updated Team Name"
echo ""

# Step 14: User Context
echo "📝 STEP 14: Getting User Context..."
uv run python scripts/test_users.py context $USER_ID
echo ""

# Step 15: Query Users
echo "📝 STEP 15: Querying Users..."
uv run python scripts/test_users.py query list
echo ""

# Step 16: Update User
echo "📝 STEP 16: Updating User..."
uv run python scripts/test_users.py update $USER_ID firstName="Updated" lastName="Name"
echo ""

# Step 17: Get User
echo "📝 STEP 17: Getting Updated User..."
uv run python scripts/test_users.py get $USER_ID
echo ""

echo "✅ ========================================"
echo "✅ ALL TESTS COMPLETED SUCCESSFULLY!"
echo "✅ ========================================"
echo ""
echo "Test Summary:"
echo "  ✅ User: Create, Get, Query, Update, Context"
echo "  ✅ Teams: Create (MANAGED & PERSONAL), Get, Query, Update"
echo "  ✅ Players: Add, List, Get, Update"
echo "  ✅ Games: Create, List, Get, Update"
echo ""
echo "Created Resources:"
echo "  User ID: $USER_ID"
echo "  Teams: $TEAM1_ID, $TEAM2_ID, $PERSONAL_TEAM_ID"
echo "  Players: $PLAYER1_ID, $PLAYER2_ID, $PLAYER3_ID"
echo "  Games: $GAME1_ID, $GAME2_ID"
