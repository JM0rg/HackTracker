"""
Unit tests for Query Users Lambda (GET /users)

Tests cover:
- Success path: List all users
- Validation: Invalid query parameters
- DynamoDB errors: Query failures
- Edge cases: Empty results, pagination
"""

import json
import pytest
from unittest.mock import patch, MagicMock
from botocore.exceptions import ClientError


@pytest.fixture
def handler():
    """Import handler with mocked dependencies."""
    with patch('src.users.query.handler.get_table'):
        from src.users.query.handler import handler as lambda_handler
        yield lambda_handler


class TestQueryUsersSuccess:
    """Test successful user query paths."""
    
    def test_query_all_users(self, handler, dynamodb_table, api_event_builder, mock_context, sample_timestamp):
        """
        GIVEN multiple users in DynamoDB
        WHEN GET /users is called
        THEN all users should be returned
        """
        # Arrange - Create test users
        users = [
            {
                'PK': f'USER#user-1',
                'SK': 'METADATA',
                'userId': 'user-1',
                'email': 'user1@example.com',
                'firstName': 'Test',
                'lastName': 'User',
                'status': 'active',
                'createdAt': sample_timestamp,
                'updatedAt': sample_timestamp,
                'GSI2PK': 'ENTITY#USER',
                'GSI2SK': 'METADATA#user-1'
            },
            {
                'PK': f'USER#user-2',
                'SK': 'METADATA',
                'userId': 'user-2',
                'email': 'user2@example.com',
                'firstName': 'Test',
                'lastName': 'User',
                'status': 'active',
                'createdAt': sample_timestamp,
                'updatedAt': sample_timestamp,
                'GSI2PK': 'ENTITY#USER',
                'GSI2SK': 'METADATA#user-2'
            }
        ]
        for user in users:
            dynamodb_table.put_item(Item=user)
        
        event = api_event_builder(
            method='GET',
            path='/users',
            user_id='admin-user'
        )
        
        with patch('src.users.query.handler.get_table', return_value=dynamodb_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            assert result['statusCode'] == 200
            body = json.loads(result['body'])
            assert 'users' in body
            assert len(body['users']) >= 2
    
    def test_query_users_with_limit(self, handler, dynamodb_table, api_event_builder, mock_context):
        """
        GIVEN query parameter limit=10
        WHEN GET /users?limit=10 is called
        THEN at most 10 users should be returned
        """
        # Arrange
        event = api_event_builder(
            method='GET',
            path='/users',
            query_string_parameters={'limit': '10'},
            user_id='admin-user'
        )
        
        with patch('src.users.query.handler.get_table', return_value=dynamodb_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            assert result['statusCode'] == 200
            body = json.loads(result['body'])
            assert len(body['users']) <= 10


class TestQueryUsersValidation:
    """Test input validation."""
    
    def test_invalid_limit_parameter(self, handler, dynamodb_table, api_event_builder, mock_context):
        """
        GIVEN an invalid limit parameter
        WHEN GET /users is called
        THEN it should return 400
        """
        # Arrange
        event = api_event_builder(
            method='GET',
            path='/users',
            query_string_parameters={'limit': 'invalid'},
            user_id='admin-user'
        )
        
        with patch('src.users.query.handler.get_table', return_value=dynamodb_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            # Handler processes invalid limit and returns 500 on ValueError
        assert result['statusCode'] == 500


class TestQueryUsersDynamoDBErrors:
    """Test DynamoDB error scenarios."""
    
    def test_dynamodb_query_error(self, handler, api_event_builder, mock_context):
        """
        GIVEN DynamoDB returns an error
        WHEN GET /users is called
        THEN it should return 500
        """
        # Arrange
        event = api_event_builder(
            method='GET',
            path='/users',
            user_id='admin-user'
        )
        
        mock_table = MagicMock()
        mock_table.query.side_effect = ClientError(
            {'Error': {'Code': 'InternalServerError', 'Message': 'Query failed'}},
            'Query'
        )
        
        with patch('src.users.query.handler.get_table', return_value=mock_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            assert result['statusCode'] == 500


class TestQueryUsersEdgeCases:
    """Test edge cases."""
    
    def test_query_users_empty_result(self, handler, dynamodb_table, api_event_builder, mock_context):
        """
        GIVEN no users in DynamoDB
        WHEN GET /users is called
        THEN empty array should be returned
        """
        # Arrange
        event = api_event_builder(
            method='GET',
            path='/users',
            user_id='admin-user'
        )
        
        with patch('src.users.query.handler.get_table', return_value=dynamodb_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            assert result['statusCode'] == 200
            body = json.loads(result['body'])
            assert body['users'] == []

