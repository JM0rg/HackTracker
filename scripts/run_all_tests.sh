#!/bin/bash
# Comprehensive Test Suite - Runs ALL tests
# Tests failure cases before success cases where applicable

set -e  # Exit on first error

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Activate venv
source "$PROJECT_ROOT/.venv/bin/activate"

echo -e "${BLUE}======================================================================${NC}"
echo -e "${BLUE}                   COMPREHENSIVE TEST SUITE                          ${NC}"
echo -e "${BLUE}======================================================================${NC}"
echo ""
echo -e "${YELLOW}🧪 Testing ALL Lambda functions${NC}"
echo -e "${YELLOW}📋 Strategy: Test failure cases BEFORE success cases${NC}"
echo ""

# Clear database
echo -e "${BLUE}======================================================================${NC}"
echo -e "${BLUE}                      CLEARING DATABASE                              ${NC}"
echo -e "${BLUE}======================================================================${NC}"
python "$SCRIPT_DIR/db.py" clear
echo ""

# Store test user ID
TEST_USER_ID="12345678-1234-1234-1234-123456789012"
TEST_TEAM_ID=""
TEST_PLAYER_ID=""

# ============================================================================
# USER TESTS
# ============================================================================

echo -e "${BLUE}======================================================================${NC}"
echo -e "${BLUE}                          USER TESTS                                  ${NC}"
echo -e "${BLUE}======================================================================${NC}"
echo ""

echo -e "${YELLOW}🧪 TEST: Get non-existent user (FAILURE CASE)${NC}"
if python "$SCRIPT_DIR/test_users.py" get "nonexistent-id" 2>&1 | grep -q "404\|not found"; then
    echo -e "${GREEN}✅ Correctly returned 404 for non-existent user${NC}"
else
    echo -e "${RED}❌ Failed to return 404${NC}"
    exit 1
fi
echo ""

echo -e "${YELLOW}🧪 TEST: Create user (SUCCESS CASE)${NC}"
python "$SCRIPT_DIR/test_users.py" create
echo ""

echo -e "${YELLOW}🧪 TEST: Get user context - no teams (SUCCESS CASE)${NC}"
if python "$SCRIPT_DIR/test_users.py" context "$TEST_USER_ID" 2>&1 | grep -q '"has_personal_context": false'; then
    echo -e "${GREEN}✅ User context correct: no teams${NC}"
else
    echo -e "${RED}❌ User context incorrect${NC}"
    exit 1
fi
echo ""

echo -e "${YELLOW}🧪 TEST: Get user by ID (SUCCESS CASE)${NC}"
python "$SCRIPT_DIR/test_users.py" get "$TEST_USER_ID"
echo ""

# ============================================================================
# TEAM TESTS
# ============================================================================

echo -e "${BLUE}======================================================================${NC}"
echo -e "${BLUE}                          TEAM TESTS                                  ${NC}"
echo -e "${BLUE}======================================================================${NC}"
echo ""

echo -e "${YELLOW}🧪 TEST: Create team without teamType (FAILURE CASE)${NC}"
echo -e "${YELLOW}   (Note: This needs manual Lambda invocation - skipping)${NC}"
echo ""

echo -e "${YELLOW}🧪 TEST: Run full team tests (includes MANAGED and PERSONAL)${NC}"
python "$SCRIPT_DIR/test_teams.py" full-test "$TEST_USER_ID"
echo ""

# Extract team ID from the output for later tests
TEST_TEAM_ID=$(python -c "
import boto3
import os
os.environ['DYNAMODB_LOCAL'] = 'true'
dynamodb = boto3.resource('dynamodb', endpoint_url='http://localhost:8000', region_name='us-east-1')
table = dynamodb.Table('HackTracker-dev')
response = table.query(
    KeyConditionExpression='PK = :pk AND begins_with(SK, :sk)',
    ExpressionAttributeValues={':pk': 'USER#$TEST_USER_ID', ':sk': 'TEAM#'}
)
if response['Items']:
    print(response['Items'][0]['teamId'])
")

if [ -n "$TEST_TEAM_ID" ]; then
    echo -e "${GREEN}✅ Test team ID: $TEST_TEAM_ID${NC}"
else
    echo -e "${RED}❌ Failed to get test team ID${NC}"
    exit 1
fi
echo ""

echo -e "${YELLOW}🧪 TEST: Verify user context has teams${NC}"
if python "$SCRIPT_DIR/test_users.py" context "$TEST_USER_ID" 2>&1 | grep -q '"has_managed_context": true\|"has_personal_context": true'; then
    echo -e "${GREEN}✅ User context shows teams${NC}"
else
    echo -e "${RED}❌ User context doesn't show teams${NC}"
    exit 1
fi
echo ""

# ============================================================================
# PLAYER TESTS
# ============================================================================

echo -e "${BLUE}======================================================================${NC}"
echo -e "${BLUE}                         PLAYER TESTS                                 ${NC}"
echo -e "${BLUE}======================================================================${NC}"
echo ""

echo -e "${YELLOW}🧪 TEST: Run full player tests${NC}"
python "$SCRIPT_DIR/test_players.py" full-test "$TEST_USER_ID"
echo ""

# ============================================================================
# GAME TESTS
# ============================================================================

echo -e "${BLUE}======================================================================${NC}"
echo -e "${BLUE}                          GAME TESTS                                  ${NC}"
echo -e "${BLUE}======================================================================${NC}"
echo ""

echo -e "${YELLOW}🧪 TEST: Run full game tests${NC}"
python "$SCRIPT_DIR/test_games.py" full-test "$TEST_USER_ID"
echo ""

# ============================================================================
# SUMMARY
# ============================================================================

echo -e "${BLUE}======================================================================${NC}"
echo -e "${BLUE}                       TEST SUITE COMPLETE                            ${NC}"
echo -e "${BLUE}======================================================================${NC}"
echo ""
echo -e "${GREEN}✅ All tests passed! ✨${NC}"
echo ""
echo -e "${YELLOW}Summary:${NC}"
echo -e "  ${GREEN}✅ User CRUD operations${NC}"
echo -e "  ${GREEN}✅ User context (dynamic UI support)${NC}"
echo -e "  ${GREEN}✅ Team CRUD operations (MANAGED & PERSONAL)${NC}"
echo -e "  ${GREEN}✅ Team type validation & restrictions${NC}"
echo -e "  ${GREEN}✅ Player CRUD operations${NC}"
echo -e "  ${GREEN}✅ Player validation & authorization${NC}"
echo -e "  ${GREEN}✅ Game CRUD operations${NC}"
echo -e "  ${GREEN}✅ Game lineup validation${NC}"
echo -e "  ${GREEN}✅ Personal team restrictions (no lineup required)${NC}"
echo ""

