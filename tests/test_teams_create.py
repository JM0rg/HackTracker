"""
Unit tests for Create Team Lambda (POST /teams)

Tests cover:
- Success path: Create team with atomic transaction (team + membership + player)
- Validation: Missing/invalid name, description, team type
- DynamoDB errors: Conditional check failures, transaction errors
- Edge cases: MANAGED vs PERSONAL teams, special characters
"""

import json
import pytest
from unittest.mock import patch, MagicMock
from botocore.exceptions import ClientError


@pytest.fixture
def handler():
    """Import handler with mocked dependencies."""
    with patch('src.teams.create.handler.get_table'):
        from src.teams.create.handler import handler as lambda_handler
        yield lambda_handler


class TestCreateTeamSuccess:
    """Test successful team creation paths."""
    
    def test_create_managed_team_success(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id, sample_timestamp):
        """
        GIVEN a valid MANAGED team creation request
        WHEN POST /teams is called
        THEN team, membership, and owner player should be created atomically
        """
        # Arrange - Create user first
        user_item = {
            'PK': f'USER#{sample_user_id}',
            'SK': 'METADATA',
            'userId': sample_user_id,
            'email': 'owner@example.com',
            'firstName': 'Team',
            'lastName': 'Owner',
            'status': 'active',
            'createdAt': sample_timestamp,
            'updatedAt': sample_timestamp
        }
        dynamodb_table.put_item(Item=user_item)
        
        event = api_event_builder(
            method='POST',
            path='/teams',
            body={
                'name': 'Seattle Sluggers',
                'description': 'Best team in Seattle',
                'teamType': 'MANAGED'
            },
            user_id=sample_user_id
        )
        
        with patch('src.teams.create.handler.get_table', return_value=dynamodb_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            assert result['statusCode'] == 201
            body = json.loads(result['body'])
            assert body['name'] == 'Seattle Sluggers'
            assert body['description'] == 'Best team in Seattle'
            assert body['team_type'] == 'MANAGED'
            assert body['ownerId'] == sample_user_id
            assert 'teamId' in body
            
            # Verify team record
            team_id = body['teamId']
            team_response = dynamodb_table.get_item(Key={'PK': f'TEAM#{team_id}', 'SK': 'METADATA'})
            assert 'Item' in team_response
            assert team_response['Item']['name'] == 'Seattle Sluggers'
            
            # Verify membership record
            membership_response = dynamodb_table.get_item(Key={'PK': f'USER#{sample_user_id}', 'SK': f'TEAM#{team_id}'})
            assert 'Item' in membership_response
            assert membership_response['Item']['role'] == 'team-owner'
            
            # Verify owner player record
            from boto3.dynamodb.conditions import Key
            player_response = dynamodb_table.query(
                KeyConditionExpression=Key('PK').eq(f'TEAM#{team_id}') & Key('SK').begins_with('PLAYER#')
            )
            assert len(player_response['Items']) == 1
            player = player_response['Items'][0]
            assert player['userId'] == sample_user_id
            assert player['isGhost'] is False
    
    def test_create_personal_team_success(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id, sample_timestamp):
        """
        GIVEN a valid PERSONAL team creation request
        WHEN POST /teams is called
        THEN team, membership, and linked player should be created
        """
        # Arrange
        user_item = {
            'PK': f'USER#{sample_user_id}',
            'SK': 'METADATA',
            'userId': sample_user_id,
            'email': 'personal@example.com',
            'firstName': 'John',
            'status': 'active',
            'createdAt': sample_timestamp,
            'updatedAt': sample_timestamp
        }
        dynamodb_table.put_item(Item=user_item)
        
        event = api_event_builder(
            method='POST',
            path='/teams',
            body={
                'name': 'Personal Stats',
                'teamType': 'PERSONAL'
            },
            user_id=sample_user_id
        )
        
        with patch('src.teams.create.handler.get_table', return_value=dynamodb_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            assert result['statusCode'] == 201
            body = json.loads(result['body'])
            assert body['team_type'] == 'PERSONAL'
    
    def test_create_team_without_description(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id, sample_timestamp):
        """
        GIVEN a team creation request without description
        WHEN POST /teams is called
        THEN team should be created without description field
        """
        # Arrange
        user_item = {
            'PK': f'USER#{sample_user_id}',
            'SK': 'METADATA',
            'userId': sample_user_id,
            'email': 'test@example.com',
            'firstName': 'Test',
            'status': 'active',
            'createdAt': sample_timestamp,
            'updatedAt': sample_timestamp
        }
        dynamodb_table.put_item(Item=user_item)
        
        event = api_event_builder(
            method='POST',
            path='/teams',
            body={'name': 'Minimal Team', 'teamType': 'MANAGED'},
            user_id=sample_user_id
        )
        
        with patch('src.teams.create.handler.get_table', return_value=dynamodb_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            assert result['statusCode'] == 201
            body = json.loads(result['body'])
            assert 'description' not in body or body.get('description') is None


class TestCreateTeamValidation:
    """Test input validation."""
    
    def test_missing_team_name(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id):
        """
        GIVEN a request without team name
        WHEN POST /teams is called
        THEN it should return 400
        """
        # Arrange
        event = api_event_builder(
            method='POST',
            path='/teams',
            body={'teamType': 'MANAGED'},  # Missing name
            user_id=sample_user_id
        )
        
        with patch('src.teams.create.handler.get_table', return_value=dynamodb_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            assert result['statusCode'] == 400
            body = json.loads(result['body'])
            assert 'error' in body
    
    def test_missing_team_type(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id):
        """
        GIVEN a request without team type
        WHEN POST /teams is called
        THEN it should return 400
        """
        # Arrange
        event = api_event_builder(
            method='POST',
            path='/teams',
            body={'name': 'Test Team'},  # Missing teamType
            user_id=sample_user_id
        )
        
        with patch('src.teams.create.handler.get_table', return_value=dynamodb_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            assert result['statusCode'] == 400
    
    def test_invalid_team_name_too_short(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id):
        """
        GIVEN a team name shorter than 3 characters
        WHEN POST /teams is called
        THEN it should return 400
        """
        # Arrange
        event = api_event_builder(
            method='POST',
            path='/teams',
            body={'name': 'AB', 'teamType': 'MANAGED'},  # Too short
            user_id=sample_user_id
        )
        
        with patch('src.teams.create.handler.get_table', return_value=dynamodb_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            assert result['statusCode'] == 400
    
    def test_invalid_team_name_too_long(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id):
        """
        GIVEN a team name longer than 50 characters
        WHEN POST /teams is called
        THEN it should return 400
        """
        # Arrange
        event = api_event_builder(
            method='POST',
            path='/teams',
            body={'name': 'A' * 51, 'teamType': 'MANAGED'},  # Too long
            user_id=sample_user_id
        )
        
        with patch('src.teams.create.handler.get_table', return_value=dynamodb_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            assert result['statusCode'] == 400
    
    def test_invalid_team_type(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id):
        """
        GIVEN an invalid team type
        WHEN POST /teams is called
        THEN it should return 400
        """
        # Arrange
        event = api_event_builder(
            method='POST',
            path='/teams',
            body={'name': 'Test Team', 'teamType': 'INVALID'},
            user_id=sample_user_id
        )
        
        with patch('src.teams.create.handler.get_table', return_value=dynamodb_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            assert result['statusCode'] == 400
    
    def test_malformed_json_body(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id):
        """
        GIVEN a malformed JSON request body
        WHEN POST /teams is called
        THEN it should return 400
        """
        # Arrange
        event = api_event_builder(
            method='POST',
            path='/teams',
            body='{"invalid": json}',  # Malformed
            user_id=sample_user_id
        )
        
        with patch('src.teams.create.handler.get_table', return_value=dynamodb_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            assert result['statusCode'] == 400


class TestCreateTeamDynamoDBErrors:
    """Test DynamoDB error scenarios."""
    
    def test_dynamodb_transaction_cancelled(self, handler, api_event_builder, mock_context, sample_user_id):
        """
        GIVEN DynamoDB transaction is cancelled (conflict)
        WHEN POST /teams is called
        THEN it should return 409
        """
        # Arrange
        event = api_event_builder(
            method='POST',
            path='/teams',
            body={'name': 'Test Team', 'teamType': 'MANAGED'},
            user_id=sample_user_id
        )
        
        mock_table = MagicMock()
        mock_table.get_item.return_value = {'Item': {'firstName': 'Test'}}
        mock_table.meta.client.transact_write_items.side_effect = ClientError(
            {'Error': {'Code': 'TransactionCanceledException', 'Message': 'Transaction cancelled'}},
            'TransactWriteItems'
        )
        
        with patch('src.teams.create.handler.get_table', return_value=mock_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            assert result['statusCode'] == 409
    
    def test_dynamodb_general_error(self, handler, api_event_builder, mock_context, sample_user_id):
        """
        GIVEN DynamoDB returns a general error
        WHEN POST /teams is called
        THEN it should return 500
        """
        # Arrange
        event = api_event_builder(
            method='POST',
            path='/teams',
            body={'name': 'Test Team', 'teamType': 'MANAGED'},
            user_id=sample_user_id
        )
        
        mock_table = MagicMock()
        mock_table.get_item.return_value = {'Item': {'firstName': 'Test'}}
        mock_table.meta.client.transact_write_items.side_effect = ClientError(
            {'Error': {'Code': 'InternalServerError', 'Message': 'DynamoDB error'}},
            'TransactWriteItems'
        )
        
        with patch('src.teams.create.handler.get_table', return_value=mock_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            assert result['statusCode'] == 500


class TestCreateTeamEdgeCases:
    """Test edge cases."""
    
    def test_create_team_with_special_characters(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id, sample_timestamp):
        """
        GIVEN a team name with numbers and spaces
        WHEN POST /teams is called
        THEN team should be created successfully
        """
        # Arrange
        user_item = {
            'PK': f'USER#{sample_user_id}',
            'SK': 'METADATA',
            'userId': sample_user_id,
            'email': 'test@example.com',
            'firstName': 'Test',
            'status': 'active',
            'createdAt': sample_timestamp,
            'updatedAt': sample_timestamp
        }
        dynamodb_table.put_item(Item=user_item)
        
        event = api_event_builder(
            method='POST',
            path='/teams',
            body={'name': 'Team 123 ABC', 'teamType': 'MANAGED'},
            user_id=sample_user_id
        )
        
        with patch('src.teams.create.handler.get_table', return_value=dynamodb_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            assert result['statusCode'] == 201
            body = json.loads(result['body'])
            assert body['name'] == 'Team 123 ABC'
    
    def test_create_team_trims_whitespace(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id, sample_timestamp):
        """
        GIVEN a team name with leading/trailing whitespace
        WHEN POST /teams is called
        THEN whitespace should be trimmed
        """
        # Arrange
        user_item = {
            'PK': f'USER#{sample_user_id}',
            'SK': 'METADATA',
            'userId': sample_user_id,
            'email': 'test@example.com',
            'firstName': 'Test',
            'status': 'active',
            'createdAt': sample_timestamp,
            'updatedAt': sample_timestamp
        }
        dynamodb_table.put_item(Item=user_item)
        
        event = api_event_builder(
            method='POST',
            path='/teams',
            body={'name': '  Trimmed Team  ', 'teamType': 'MANAGED'},
            user_id=sample_user_id
        )
        
        with patch('src.teams.create.handler.get_table', return_value=dynamodb_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            assert result['statusCode'] == 201
            body = json.loads(result['body'])
            assert body['name'] == 'Trimmed Team'

