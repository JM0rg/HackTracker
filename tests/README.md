# HackTracker Lambda Function Tests

Comprehensive unit tests for all 21 Lambda functions in the HackTracker application.

## Test Coverage

### User Lambda Functions (6 functions)
- ✅ `test_users_create.py` - Create User (Cognito trigger)
- ✅ `test_users_get.py` - Get User by ID
- ✅ `test_users_query.py` - Query/List Users
- ✅ `test_users_update.py` - Update User
- ✅ `test_users_delete.py` - Delete User (soft delete)
- ✅ `test_users_context.py` - Get User Context

### Team Lambda Functions (5 functions)
- ✅ `test_teams_create.py` - Create Team (atomic with membership + player)
- ✅ `test_teams_get.py` - Get Team by ID
- ✅ `test_teams_query.py` - Query/List Teams
- ✅ `test_teams_update.py` - Update Team
- ✅ `test_teams_delete.py` - Delete Team (soft delete)

### Player Lambda Functions (5 functions)
- ✅ `test_players_add.py` - Add Player to Roster
- ✅ `test_players_list.py` - List Team Roster
- ✅ `test_players_get.py` - Get Player by ID
- ✅ `test_players_update.py` - Update Player
- ✅ `test_players_remove.py` - Remove Player (ghost players only)

### Game Lambda Functions (5 functions)
- ✅ `test_games_create.py` - Create Game
- ✅ `test_games_list.py` - List Games by Team
- ✅ `test_games_get.py` - Get Game by ID
- ✅ `test_games_update.py` - Update Game
- ✅ `test_games_delete.py` - Delete Game

## Test Coverage Areas

Each test file covers:

1. **Success Paths** - Happy path scenarios with valid inputs
2. **Input Validation** - Missing fields, invalid data types, malformed requests
3. **Authorization** - User permissions and role-based access control
4. **DynamoDB Errors** - ConditionalCheckFailed, InternalServerError, ResourceNotFound
5. **Edge Cases** - Empty results, special characters, boundary conditions

## Installation

```bash
cd tests
pip install -r requirements.txt
```

## Running Tests

### Run All Tests
```bash
pytest
```

### Run with Coverage Report
```bash
pytest --cov=src --cov-report=html --cov-report=term
```

### Run Specific Test File
```bash
pytest test_users_create.py
```

### Run Specific Test Class
```bash
pytest test_users_create.py::TestCreateUserSuccess
```

### Run Specific Test
```bash
pytest test_users_create.py::TestCreateUserSuccess::test_create_user_with_all_fields
```

### Run Tests with Verbose Output
```bash
pytest -v
```

### Run Tests and Stop on First Failure
```bash
pytest -x
```

## Test Structure

All tests follow the **Arrange-Act-Assert (AAA)** pattern:

```python
def test_example(self, handler, dynamodb_table, api_event_builder, mock_context):
    """
    GIVEN a specific scenario
    WHEN the handler is invoked
    THEN the expected outcome should occur
    """
    # Arrange - Set up test data and mocks
    event = api_event_builder(...)
    
    # Act - Call the handler
    result = handler(event, mock_context)
    
    # Assert - Verify the outcome
    assert result['statusCode'] == 200
```

## Fixtures

Shared fixtures from `conftest.py`:

- `dynamodb_table` - Mocked DynamoDB table with full schema
- `api_event_builder` - Function to create API Gateway events
- `cognito_event_builder` - Function to create Cognito trigger events
- `mock_context` - Mock Lambda context object
- `sample_user_id` - Test user ID
- `sample_team_id` - Test team ID
- `sample_player_id` - Test player ID
- `sample_game_id` - Test game ID
- `sample_timestamp` - Test timestamp

## Mocking Strategy

- **AWS SDK**: All DynamoDB calls are mocked using `moto`
- **Isolation**: Each test is isolated with `pytest` fixtures
- **No Network Calls**: All external dependencies are mocked
- **Deterministic**: Tests produce consistent results

## CI/CD Integration

Add to your CI/CD pipeline:

```yaml
# GitHub Actions example
- name: Run Lambda Tests
  run: |
    cd tests
    pip install -r requirements.txt
    pytest --cov=src --cov-report=xml
```

## Troubleshooting

### Import Errors

If you see import errors, ensure the `src/` directory is in your Python path:

```bash
export PYTHONPATH="${PYTHONPATH}:$(pwd)"
```

### DynamoDB Table Creation Fails

Ensure `moto` is installed and AWS credentials are mocked in `conftest.py`.

### Tests are Slow

Use pytest-xdist for parallel execution:

```bash
pip install pytest-xdist
pytest -n auto
```

## Best Practices

1. **Reset Mocks**: All mocks are reset before each test
2. **Isolated Data**: Test data is created per-test, not shared
3. **Descriptive Names**: Test names describe what they test
4. **GIVEN-WHEN-THEN**: Docstrings follow GWT format
5. **Comprehensive Coverage**: Success, failure, and edge cases all tested

## Maintenance

When adding new Lambda functions:

1. Create a new test file following the naming convention: `test_{module}_{function}.py`
2. Import the handler with mocked dependencies
3. Create test classes for each category (Success, Validation, Authorization, Errors, EdgeCases)
4. Ensure all code paths are covered
5. Update this README with the new test file

## Contact

For questions about the test suite, see the main project README or architecture documentation.

