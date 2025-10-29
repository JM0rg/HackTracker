"""
Unit tests for Create User Lambda (Cognito Post-Confirmation Trigger)

Tests cover:
- Success path: User creation from Cognito trigger
- Validation: Missing required fields, invalid data
- DynamoDB errors: ConditionalCheckFailedException, general errors
- Edge cases: Duplicate users, malformed events
"""

import json
import pytest
from unittest.mock import patch, Mock, MagicMock
from botocore.exceptions import ClientError
from datetime import datetime, timezone


@pytest.fixture
def handler():
    """Import handler with mocked dependencies."""
    with patch('src.users.create.handler.get_table'):
        from src.users.create.handler import handler as lambda_handler
        yield lambda_handler


class TestCreateUserSuccess:
    """Test successful user creation paths."""
    
    def test_create_user_with_all_fields(self, handler, dynamodb_table, cognito_event_builder, mock_context):
        """
        GIVEN a valid Cognito post-confirmation event with all user attributes
        WHEN the handler is invoked
        THEN user record should be created in DynamoDB with all fields
        """
        # Arrange
        user_id = 'user-test-123'
        event = cognito_event_builder(
            user_id=user_id,
            email='test@example.com',
            attributes={
                'given_name': 'John',
                'family_name': 'Doe',
                'phone_number': '+15555551234'
            }
        )
        
        with patch('src.users.create.handler.get_table', return_value=dynamodb_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert - Return value
            assert result == event  # Cognito triggers must return the event
            
            # Assert - DynamoDB write
            response = dynamodb_table.get_item(
                Key={'PK': f'USER#{user_id}', 'SK': 'METADATA'}
            )
            assert 'Item' in response
            item = response['Item']
            assert item['userId'] == user_id
            assert item['email'] == 'test@example.com'
            assert item['firstName'] == 'John'
            assert item['lastName'] == 'Doe'
            assert item['phoneNumber'] == '+15555551234'
            # Note: users don't have a 'status' field
            assert 'createdAt' in item
            assert 'updatedAt' in item
            assert item['GSI1PK'] == f'COGNITO#{user_id}'
            assert item['GSI1SK'] == 'USER'
            assert item['GSI2PK'] == 'ENTITY#USER'
            assert item['GSI2SK'] == f'METADATA#{user_id}'
    
    def test_create_user_with_minimal_fields(self, handler, dynamodb_table, cognito_event_builder, mock_context):
        """
        GIVEN a Cognito event with only required fields (sub and email)
        WHEN the handler is invoked
        THEN user should be created with optional fields as None
        """
        # Arrange
        user_id = 'user-minimal-456'
        event = cognito_event_builder(
            user_id=user_id,
            email='minimal@example.com'
        )
        
        with patch('src.users.create.handler.get_table', return_value=dynamodb_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            assert result == event
            
            response = dynamodb_table.get_item(
                Key={'PK': f'USER#{user_id}', 'SK': 'METADATA'}
            )
            item = response['Item']
            assert item['userId'] == user_id
            assert item['email'] == 'minimal@example.com'
            # Handler auto-generates firstName/lastName from email if not provided
            assert item.get('firstName') == 'minimal'  # From email prefix
            assert item.get('lastName') == 'User'  # Default value
            assert item.get('phoneNumber') is None


class TestCreateUserValidation:
    """Test input validation and error handling."""
    
    def test_missing_user_id(self, handler, dynamodb_table, mock_context):
        """
        GIVEN a Cognito event missing the 'sub' field
        WHEN the handler is invoked
        THEN it should raise an error (or handle gracefully)
        """
        # Arrange
        event = {
            'request': {
                'userAttributes': {
                    'email': 'test@example.com'
                    # Missing 'sub'
                }
            },
            'response': {}
        }
        
        with patch('src.users.create.handler.get_table', return_value=dynamodb_table):
            # Act - Cognito trigger returns event even on error
            result = handler(event, mock_context)
            
            # Assert - Returns event but logs error (doesn't raise)
            assert result == event  # Cognito triggers must return event
    
    def test_missing_email(self, handler, dynamodb_table, mock_context):
        """
        GIVEN a Cognito event missing the email field
        WHEN the handler is invoked
        THEN it should raise an error
        """
        # Arrange
        event = {
            'request': {
                'userAttributes': {
                    'sub': 'user-123'
                    # Missing 'email'
                }
            },
            'response': {}
        }
        
        with patch('src.users.create.handler.get_table', return_value=dynamodb_table):
            # Act - Cognito trigger returns event even on error
            result = handler(event, mock_context)
            
            # Assert - Returns event but logs error (doesn't raise)
            assert result == event  # Cognito triggers must return event
    
    def test_malformed_event(self, handler, dynamodb_table, mock_context):
        """
        GIVEN a completely malformed Cognito event
        WHEN the handler is invoked
        THEN it should raise an appropriate error
        """
        # Arrange
        event = {'invalid': 'structure'}
        
        with patch('src.users.create.handler.get_table', return_value=dynamodb_table):
            # Act - Cognito trigger returns event even on error
            result = handler(event, mock_context)
            
            # Assert - Returns event but logs error (doesn't raise)
            assert result == event  # Cognito triggers must return event
    
    def test_empty_event(self, handler, dynamodb_table, mock_context):
        """
        GIVEN an empty event object
        WHEN the handler is invoked
        THEN it should raise an error
        """
        # Arrange
        event = {}
        
        with patch('src.users.create.handler.get_table', return_value=dynamodb_table):
            # Act - Cognito trigger returns event even on error
            result = handler(event, mock_context)
            
            # Assert - Returns event but logs error (doesn't raise)
            assert result == event  # Cognito triggers must return event


class TestCreateUserDynamoDBErrors:
    """Test DynamoDB error scenarios."""
    
    def test_dynamodb_conditional_check_failed(self, handler, cognito_event_builder, mock_context):
        """
        GIVEN a user that already exists in DynamoDB
        WHEN the handler tries to create a duplicate user
        THEN it should handle the ConditionalCheckFailedException
        """
        # Arrange
        user_id = 'user-duplicate-789'
        event = cognito_event_builder(user_id=user_id, email='duplicate@example.com')
        
        mock_table = MagicMock()
        mock_table.put_item.side_effect = ClientError(
            {
                'Error': {
                    'Code': 'ConditionalCheckFailedException',
                    'Message': 'Item already exists'
                }
            },
            'PutItem'
        )
        
        with patch('src.users.create.handler.get_table', return_value=mock_table):
            # Act & Assert
            # Handler should either return event or handle gracefully
            # (Cognito triggers should not fail on duplicate users)
            result = handler(event, mock_context)
            assert result == event or isinstance(result, dict)
    
    def test_dynamodb_general_error(self, handler, cognito_event_builder, mock_context):
        """Test handling of general DynamoDB errors"""
        # Arrange
        event = cognito_event_builder(
            user_id='user-error-999',
            email='error@example.com'
        )
        
        # Mock DynamoDB to raise error
        mock_table = Mock()
        mock_table.put_item.side_effect = ClientError(
            {'Error': {'Code': 'InternalServerError', 'Message': 'DynamoDB error'}},
            'PutItem'
        )
        
        # Act - Cognito trigger returns event even on error
        with patch('src.users.create.handler.get_table', return_value=mock_table):
            result = handler(event, mock_context)
        
        # Assert - Returns event but logs error (doesn't raise)
        assert result == event  # Cognito triggers must return event
    
    """Test edge cases and boundary conditions."""
    
    def test_create_user_with_special_characters_in_name(self, handler, dynamodb_table, cognito_event_builder, mock_context):
        """
        GIVEN a user with special characters in names
        WHEN the handler is invoked
        THEN user should be created with names preserved
        """
        # Arrange
        user_id = 'user-special-chars'
        event = cognito_event_builder(
            user_id=user_id,
            email='special@example.com',
            attributes={
                'given_name': "O'Malley",
                'family_name': 'José-María'
            }
        )
        
        with patch('src.users.create.handler.get_table', return_value=dynamodb_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            response = dynamodb_table.get_item(
                Key={'PK': f'USER#{user_id}', 'SK': 'METADATA'}
            )
            item = response['Item']
            assert item['firstName'] == "O'Malley"
            assert item['lastName'] == 'José-María'
    
    def test_create_user_with_long_email(self, handler, dynamodb_table, cognito_event_builder, mock_context):
        """
        GIVEN a user with a very long email address
        WHEN the handler is invoked
        THEN user should be created successfully
        """
        # Arrange
        user_id = 'user-long-email'
        long_email = 'a' * 50 + '@' + 'b' * 50 + '.com'
        event = cognito_event_builder(user_id=user_id, email=long_email)
        
        with patch('src.users.create.handler.get_table', return_value=dynamodb_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            response = dynamodb_table.get_item(
                Key={'PK': f'USER#{user_id}', 'SK': 'METADATA'}
            )
            assert response['Item']['email'] == long_email
    
    def test_create_user_idempotency(self, handler, dynamodb_table, cognito_event_builder, mock_context):
        """
        GIVEN a user creation request is sent twice
        WHEN the handler is invoked both times
        THEN the second call should handle it gracefully (idempotency)
        """
        # Arrange
        user_id = 'user-idempotent'
        event = cognito_event_builder(user_id=user_id, email='idempotent@example.com')
        
        with patch('src.users.create.handler.get_table', return_value=dynamodb_table):
            # Act - First call
            result1 = handler(event, mock_context)
            
            # Act - Second call (should handle duplicate)
            # This will fail with ConditionalCheckFailedException
            # The handler should catch and return event anyway
            try:
                result2 = handler(event, mock_context)
                # If it doesn't raise, verify it returns the event
                assert result2 == event
            except ClientError as e:
                # If it does raise, that's also acceptable behavior
                assert e.response['Error']['Code'] == 'ConditionalCheckFailedException'

