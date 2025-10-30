# HackTracker Testing Guide

Comprehensive testing guide for HackTracker's Lambda functions and infrastructure.

---

## Overview

**Test Framework:** pytest  
**Mocking:** moto (AWS service mocks)  
**Pattern:** Arrange-Act-Assert (AAA)  
**Coverage:** 72%  
**Total Tests:** 200+ across 21 Lambda functions

---

## Quick Start

### Install Dependencies

```bash
cd tests
pip install -r requirements.txt
```

Or using uv:
```bash
uv pip install -r tests/requirements.txt
```

### Run All Tests

```bash
pytest
```

### Run with Coverage

```bash
pytest --cov=src --cov-report=html --cov-report=term
```

### Run Specific Test File

```bash
pytest tests/test_users_create.py
pytest tests/test_teams_query.py
pytest tests/test_games_list.py
```

### Run Specific Test Class

```bash
pytest tests/test_players_add.py::TestAddPlayerSuccess
```

### Run Specific Test

```bash
pytest tests/test_players_add.py::TestAddPlayerSuccess::test_add_ghost_player
```

---

## Test Structure

### File Organization

```
tests/
├── conftest.py              # Shared fixtures (DynamoDB mocks)
├── requirements.txt         # Test dependencies
├── test_users_*.py          # User Lambda tests (6 files)
├── test_teams_*.py          # Team Lambda tests (5 files)
├── test_players_*.py        # Player Lambda tests (5 files)
├── test_games_*.py          # Game Lambda tests (5 files)
└── test_utils_*.py          # Utility function tests
```

### Test Class Organization

Each test file follows this structure:

```python
class TestFunctionSuccess:
    """Happy path tests"""
    def test_basic_operation(self):
        # Arrange
        # Act
        # Assert
    
    def test_with_optional_fields(self):
        # ...

class TestFunctionValidation:
    """Input validation tests"""
    def test_missing_required_field(self):
        # ...
    
    def test_invalid_field_type(self):
        # ...

class TestFunctionAuthorization:
    """Authorization tests"""
    def test_unauthorized_user(self):
        # ...
    
    def test_insufficient_permissions(self):
        # ...

class TestFunctionDynamoDBErrors:
    """External service error tests"""
    def test_conditional_check_failed(self):
        # ...
    
    def test_internal_server_error(self):
        # ...

class TestFunctionEdgeCases:
    """Edge case tests"""
    def test_empty_results(self):
        # ...
    
    def test_special_characters(self):
        # ...
```

---

## Shared Fixtures

### conftest.py

```python
import pytest
import boto3
from moto import mock_dynamodb

@pytest.fixture
def aws_credentials(monkeypatch):
    """Mock AWS credentials"""
    monkeypatch.setenv('AWS_ACCESS_KEY_ID', 'testing')
    monkeypatch.setenv('AWS_SECRET_ACCESS_KEY', 'testing')
    monkeypatch.setenv('AWS_SECURITY_TOKEN', 'testing')
    monkeypatch.setenv('AWS_SESSION_TOKEN', 'testing')
    monkeypatch.setenv('AWS_DEFAULT_REGION', 'us-east-1')

@pytest.fixture
def dynamodb_resource(aws_credentials):
    """Create mock DynamoDB resource with table"""
    with mock_dynamodb():
        dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
        
        # Create table with GSIs
        table = dynamodb.create_table(
            TableName='hacktracker-test',
            KeySchema=[
                {'AttributeName': 'PK', 'KeyType': 'HASH'},
                {'AttributeName': 'SK', 'KeyType': 'RANGE'}
            ],
            AttributeDefinitions=[
                {'AttributeName': 'PK', 'AttributeType': 'S'},
                {'AttributeName': 'SK', 'AttributeType': 'S'},
                {'AttributeName': 'GSI1PK', 'AttributeType': 'S'},
                {'AttributeName': 'GSI1SK', 'AttributeType': 'S'},
                {'AttributeName': 'GSI2PK', 'AttributeType': 'S'},
                {'AttributeName': 'GSI2SK', 'AttributeType': 'S'},
                {'AttributeName': 'GSI3PK', 'AttributeType': 'S'},
                {'AttributeName': 'GSI3SK', 'AttributeType': 'S'},
            ],
            GlobalSecondaryIndexes=[
                {
                    'IndexName': 'GSI1',
                    'KeySchema': [
                        {'AttributeName': 'GSI1PK', 'KeyType': 'HASH'},
                        {'AttributeName': 'GSI1SK', 'KeyType': 'RANGE'}
                    ],
                    'Projection': {'ProjectionType': 'ALL'}
                },
                {
                    'IndexName': 'GSI2',
                    'KeySchema': [
                        {'AttributeName': 'GSI2PK', 'KeyType': 'HASH'},
                        {'AttributeName': 'GSI2SK', 'KeyType': 'RANGE'}
                    ],
                    'Projection': {'ProjectionType': 'ALL'}
                },
                {
                    'IndexName': 'GSI3',
                    'KeySchema': [
                        {'AttributeName': 'GSI3PK', 'KeyType': 'HASH'},
                        {'AttributeName': 'GSI3SK', 'KeyType': 'RANGE'}
                    ],
                    'Projection': {'ProjectionType': 'ALL'}
                }
            ],
            BillingMode='PAY_PER_REQUEST'
        )
        
        yield table

@pytest.fixture
def dynamodb_client(aws_credentials):
    """Create mock DynamoDB client"""
    with mock_dynamodb():
        yield boto3.client('dynamodb', region_name='us-east-1')
```

---

## Test Coverage Areas

### 1. Success Paths ✅

**Goal:** Verify happy path scenarios with valid inputs

**Example:**
```python
class TestAddPlayerSuccess:
    def test_add_ghost_player(self, dynamodb_resource, mocker):
        # Arrange: Set up test data
        team_id = str(uuid.uuid4())
        user_id = str(uuid.uuid4())
        
        # Mock authorization
        mocker.patch('src.players.add.handler.authorize')
        
        # Create team
        dynamodb_resource.put_item(Item={
            'PK': f'TEAM#{team_id}',
            'SK': 'METADATA',
            'teamId': team_id,
            'name': 'Test Team',
            'team_type': 'MANAGED'
        })
        
        # Act: Call handler
        event = {
            'pathParameters': {'teamId': team_id},
            'body': json.dumps({
                'firstName': 'John',
                'lastName': 'Doe',
                'playerNumber': 12
            }),
            'requestContext': {
                'authorizer': {'jwt': {'claims': {'sub': user_id}}}
            }
        }
        
        result = handler(event, {})
        
        # Assert: Verify response
        assert result['statusCode'] == 201
        body = json.loads(result['body'])
        assert body['firstName'] == 'John'
        assert body['playerNumber'] == 12
        assert body['isGhost'] is True
```

---

### 2. Input Validation ⚠️

**Goal:** Test handling of invalid, missing, or malformed inputs

**Common Tests:**
- Missing required fields → 400
- Invalid data types → 400
- Malformed JSON → 400
- Invalid field values → 400
- Empty request bodies → 400

**Example:**
```python
class TestAddPlayerValidation:
    def test_missing_first_name(self, dynamodb_resource, mocker):
        # Arrange
        mocker.patch('src.players.add.handler.authorize')
        
        event = {
            'body': json.dumps({
                'lastName': 'Doe',
                'playerNumber': 12
            })
        }
        
        # Act
        result = handler(event, {})
        
        # Assert
        assert result['statusCode'] == 400
        body = json.loads(result['body'])
        assert 'firstName' in body['error'].lower()
```

---

### 3. Authorization 🔒

**Goal:** Verify role-based access control

**Common Tests:**
- Non-members blocked → 403
- Insufficient permissions → 403
- Cross-user access blocked → 403
- Role requirements enforced

**Example:**
```python
class TestAddPlayerAuthorization:
    def test_only_owner_manager_can_add(self, dynamodb_resource, mocker):
        # Arrange: Mock authorization to raise PermissionError
        mocker.patch(
            'src.players.add.handler.authorize',
            side_effect=PermissionError('User does not have required role')
        )
        
        event = {'body': json.dumps({'firstName': 'John'})}
        
        # Act
        result = handler(event, {})
        
        # Assert
        assert result['statusCode'] == 403
```

---

### 4. DynamoDB Errors 💥

**Goal:** Handle external service failures gracefully

**Common Tests:**
- ConditionalCheckFailed → 409 or 400
- InternalServerError → 500
- ResourceNotFound → 404
- Transaction failures → 500

**Example:**
```python
class TestAddPlayerDynamoDBErrors:
    def test_duplicate_player_number(self, dynamodb_resource, mocker):
        # Arrange: Add player with number 12
        team_id = str(uuid.uuid4())
        dynamodb_resource.put_item(Item={
            'PK': f'TEAM#{team_id}',
            'SK': 'PLAYER#existing',
            'playerNumber': 12
        })
        
        mocker.patch('src.players.add.handler.authorize')
        
        # Act: Try to add another player with number 12
        event = {
            'pathParameters': {'teamId': team_id},
            'body': json.dumps({'playerNumber': 12})
        }
        result = handler(event, {})
        
        # Assert
        assert result['statusCode'] == 409
```

---

### 5. Edge Cases 🎯

**Goal:** Test boundary conditions and special scenarios

**Common Tests:**
- Empty result sets
- Special characters in strings
- Boundary values (min/max)
- Large data sets
- Concurrent operations

---

## Mocking Best Practices

### Mock Authorization

```python
# Allow all authorization checks
mocker.patch('src.players.add.handler.authorize')

# Simulate permission error
mocker.patch(
    'src.players.add.handler.authorize',
    side_effect=PermissionError('Insufficient permissions')
)
```

### Mock User ID Extraction

```python
# Return specific user ID
mocker.patch(
    'src.players.add.handler.get_user_id_from_event',
    return_value='specific-user-id'
)
```

### Mock DynamoDB Errors

```python
from botocore.exceptions import ClientError

# Simulate ConditionalCheckFailed
mocker.patch.object(
    dynamodb_resource,
    'put_item',
    side_effect=ClientError(
        {'Error': {'Code': 'ConditionalCheckFailedException'}},
        'PutItem'
    )
)
```

---

## Coverage Goals

### Current Coverage: 72%

**High Priority (>90%):**
- ✅ Authorization utilities: 94%
- ✅ Validation utilities: 94%
- ✅ Core Lambda handlers: 85%+

**Medium Priority (>70%):**
- ✅ Player operations: 80%
- ✅ Team operations: 75%
- ✅ User operations: 78%

**Lower Priority (>50%):**
- ✅ Game operations: 72%
- Future: At-bat operations (not yet implemented)

---

## Running Tests in CI/CD

### GitLab CI Configuration

```yaml
test:
  stage: test
  image: python:3.13
  before_script:
    - pip install -r tests/requirements.txt
  script:
    - pytest --cov=src --cov-report=xml --cov-report=term
  coverage: '/TOTAL.*\s+(\d+%)$/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml
```

---

## Common Test Patterns

### Testing Atomic Transactions

```python
def test_create_team_transaction(self, dynamodb_resource, mocker):
    """Verify team + membership created atomically"""
    # Act
    result = handler(event, {})
    
    # Assert: Both items exist
    team = dynamodb_resource.get_item(
        Key={'PK': f'TEAM#{team_id}', 'SK': 'METADATA'}
    )
    membership = dynamodb_resource.get_item(
        Key={'PK': f'USER#{user_id}', 'SK': f'TEAM#{team_id}'}
    )
    
    assert 'Item' in team
    assert 'Item' in membership
```

### Testing Pagination

```python
def test_pagination(self, dynamodb_resource):
    """Verify pagination works correctly"""
    # Arrange: Add 100 items
    for i in range(100):
        dynamodb_resource.put_item(Item={...})
    
    # Act: Get first page
    event = {'queryStringParameters': {'limit': '50'}}
    result = handler(event, {})
    
    # Assert
    body = json.loads(result['body'])
    assert len(body['items']) == 50
    assert 'nextToken' in body
    
    # Get second page
    event['queryStringParameters']['nextToken'] = body['nextToken']
    result = handler(event, {})
    body = json.loads(result['body'])
    assert len(body['items']) == 50
```

---

## Troubleshooting

### Mock Not Working

**Problem:** Test fails because mock isn't applied

**Solution:** Ensure correct import path
```python
# Wrong: Mock where it's defined
mocker.patch('utils.authorization.authorize')

# Right: Mock where it's used
mocker.patch('src.players.add.handler.authorize')
```

### Fixture Not Found

**Problem:** `fixture 'xyz' not found`

**Solution:** Check conftest.py is in tests/ directory

### DynamoDB Table Not Found

**Problem:** `Table not found` error in tests

**Solution:** Verify `dynamodb_resource` fixture creates table correctly

---

## See Also

- **[DATA_MODEL.md](./DATA_MODEL.md)** - Current implementation
- **[api/lambda-functions.md](./api/lambda-functions.md)** - Lambda function catalog
- **[pytest documentation](https://docs.pytest.org/)** - pytest framework
- **[moto documentation](https://docs.getmoto.org/)** - AWS mocking

---

**Testing Philosophy:** Write tests that document expected behavior, catch regressions early, and give confidence in deployments.

