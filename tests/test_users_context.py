"""
Unit tests for User Context Lambda (GET /users/context)

Tests cover:
- Success path: Get user context (has_personal_context, has_managed_context)
- Validation: Missing auth
- DynamoDB errors: Query failures
- Edge cases: No teams, only personal teams, only managed teams
"""

import json
import pytest
from unittest.mock import patch, MagicMock
from botocore.exceptions import ClientError


@pytest.fixture
def handler():
    """Import handler with mocked dependencies."""
    with patch('src.users.context.handler.get_table'):
        from src.users.context.handler import handler as lambda_handler
        yield lambda_handler


class TestUserContextSuccess:
    """Test successful user context retrieval."""
    
    def test_user_with_personal_and_managed_teams(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id, sample_timestamp):
        """
        GIVEN a user with both PERSONAL and MANAGED teams
        WHEN GET /users/context is called
        THEN both flags should be true
        """
        # Arrange - Create user memberships
        memberships = [
            {
                'PK': f'USER#{sample_user_id}',
                'SK': 'TEAM#team-personal',
                'userId': sample_user_id,
                'teamId': 'team-personal',
                'role': 'team-owner',
                'status': 'active'
            },
            {
                'PK': f'USER#{sample_user_id}',
                'SK': 'TEAM#team-managed',
                'userId': sample_user_id,
                'teamId': 'team-managed',
                'role': 'team-owner',
                'status': 'active'
            }
        ]
        teams = [
            {
                'PK': 'TEAM#team-personal',
                'SK': 'METADATA',
                'teamId': 'team-personal',
                'name': 'Default',
                'team_type': 'PERSONAL',
                'status': 'active'
            },
            {
                'PK': 'TEAM#team-managed',
                'SK': 'METADATA',
                'teamId': 'team-managed',
                'name': 'Real Team',
                'team_type': 'MANAGED',
                'status': 'active'
            }
        ]
        for item in memberships + teams:
            dynamodb_table.put_item(Item=item)
        
        event = api_event_builder(
            method='GET',
            path='/users/context',
            user_id=sample_user_id
        )
        
        with patch('src.users.context.handler.get_table', return_value=dynamodb_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            assert result['statusCode'] == 200
            body = json.loads(result['body'])
            assert body['has_personal_context'] is True
            assert body['has_managed_context'] is True
    
    def test_user_with_only_personal_team(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id):
        """
        GIVEN a user with only PERSONAL team
        WHEN GET /users/context is called
        THEN only has_personal_context should be true
        """
        # Arrange
        membership = {
            'PK': f'USER#{sample_user_id}',
            'SK': 'TEAM#team-personal',
            'userId': sample_user_id,
            'teamId': 'team-personal',
            'role': 'team-owner',
            'status': 'active'
        }
        team = {
            'PK': 'TEAM#team-personal',
            'SK': 'METADATA',
            'teamId': 'team-personal',
            'name': 'Default',
            'team_type': 'PERSONAL',
            'status': 'active'
        }
        dynamodb_table.put_item(Item=membership)
        dynamodb_table.put_item(Item=team)
        
        event = api_event_builder(
            method='GET',
            path='/users/context',
            user_id=sample_user_id
        )
        
        with patch('src.users.context.handler.get_table', return_value=dynamodb_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            assert result['statusCode'] == 200
            body = json.loads(result['body'])
            assert body['has_personal_context'] is True
            assert body['has_managed_context'] is False
    
    def test_user_with_no_teams(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id):
        """
        GIVEN a user with no teams
        WHEN GET /users/context is called
        THEN both flags should be false
        """
        # Arrange
        event = api_event_builder(
            method='GET',
            path='/users/context',
            user_id=sample_user_id
        )
        
        with patch('src.users.context.handler.get_table', return_value=dynamodb_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            assert result['statusCode'] == 200
            body = json.loads(result['body'])
            assert body['has_personal_context'] is False
            assert body['has_managed_context'] is False


class TestUserContextValidation:
    """Test input validation."""
    
    def test_missing_auth(self, handler, dynamodb_table, api_event_builder, mock_context):
        """
        GIVEN a request without authentication
        WHEN GET /users/context is called
        THEN it should return 401
        """
        # Arrange
        event = api_event_builder(
            method='GET',
            path='/users/context',
            user_id=None
        )
        
        with patch('src.users.context.handler.get_table', return_value=dynamodb_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            assert result['statusCode'] == 401


class TestUserContextDynamoDBErrors:
    """Test DynamoDB error scenarios."""
    
    def test_dynamodb_query_error(self, handler, api_event_builder, mock_context, sample_user_id):
        """
        GIVEN DynamoDB returns an error
        WHEN GET /users/context is called
        THEN it should return 500
        """
        # Arrange
        event = api_event_builder(
            method='GET',
            path='/users/context',
            user_id=sample_user_id
        )
        
        mock_table = MagicMock()
        mock_table.query.side_effect = ClientError(
            {'Error': {'Code': 'InternalServerError', 'Message': 'Query failed'}},
            'Query'
        )
        
        with patch('src.users.context.handler.get_table', return_value=mock_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            assert result['statusCode'] == 500

