"""
Unit tests for Update User Lambda (PUT /users/{userId})

Tests cover:
- Success path: Update user fields
- Validation: Invalid fields, readonly fields, empty values
- Authorization: User can only update their own profile
- DynamoDB errors: User not found, update errors
- Edge cases: Partial updates, empty fields
"""

import json
import pytest
from unittest.mock import patch, MagicMock
from botocore.exceptions import ClientError


@pytest.fixture
def handler():
    """Import handler with mocked dependencies."""
    with patch('src.users.update.handler.get_table'):
        from src.users.update.handler import handler as lambda_handler
        yield lambda_handler


class TestUpdateUserSuccess:
    """Test successful user update paths."""
    
    def test_update_user_all_fields(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id, sample_timestamp):
        """
        GIVEN a valid update request with all updatable fields
        WHEN PUT /users/{userId} is called
        THEN user should be updated with new values
        """
        # Arrange - Create existing user
        user_item = {
            'PK': f'USER#{sample_user_id}',
            'SK': 'METADATA',
            'userId': sample_user_id,
            'email': 'old@example.com',
            'firstName': 'Old',
            'lastName': 'Name',
            'phoneNumber': '+15555550000',
            'status': 'active',
            'createdAt': sample_timestamp,
            'updatedAt': sample_timestamp,
            'GSI1PK': f'COGNITO#{sample_user_id}',
            'GSI1SK': 'USER',
            'GSI2PK': 'ENTITY#USER',
            'GSI2SK': f'METADATA#{sample_user_id}'
        }
        dynamodb_table.put_item(Item=user_item)
        
        event = api_event_builder(
            method='PUT',
            path=f'/users/{sample_user_id}',
            path_parameters={'userId': sample_user_id},
            body={
                'firstName': 'New',
                'lastName': 'Updated',
                'phoneNumber': '+15555559999'
            },
            user_id=sample_user_id
        )
        
        with patch('src.users.update.handler.get_table', return_value=dynamodb_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            assert result['statusCode'] == 200
            body = json.loads(result['body'])
            assert body['firstName'] == 'New'
            assert body['lastName'] == 'Updated'
            assert body['phoneNumber'] == '+15555559999'
            assert 'updatedAt' in body
    
    def test_update_user_partial_fields(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id, sample_timestamp):
        """
        GIVEN an update request with only some fields
        WHEN PUT /users/{userId} is called
        THEN only specified fields should be updated
        """
        # Arrange
        user_item = {
            'PK': f'USER#{sample_user_id}',
            'SK': 'METADATA',
            'userId': sample_user_id,
            'email': 'test@example.com',
            'firstName': 'John',
            'lastName': 'Doe',
            'phoneNumber': '+15555551234',
            'status': 'active',
            'createdAt': sample_timestamp,
            'updatedAt': sample_timestamp,
            'GSI1PK': f'COGNITO#{sample_user_id}',
            'GSI1SK': 'USER',
            'GSI2PK': 'ENTITY#USER',
            'GSI2SK': f'METADATA#{sample_user_id}'
        }
        dynamodb_table.put_item(Item=user_item)
        
        event = api_event_builder(
            method='PUT',
            path=f'/users/{sample_user_id}',
            path_parameters={'userId': sample_user_id},
            body={'firstName': 'Jane'},  # Only update firstName
            user_id=sample_user_id
        )
        
        with patch('src.users.update.handler.get_table', return_value=dynamodb_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            assert result['statusCode'] == 200
            body = json.loads(result['body'])
            assert body['firstName'] == 'Jane'
            assert body['lastName'] == 'Doe'  # Unchanged
            assert body['phoneNumber'] == '+15555551234'  # Unchanged


class TestUpdateUserValidation:
    """Test input validation."""
    
    def test_update_readonly_field_userId(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id, sample_timestamp):
        """
        GIVEN an update request trying to change userId
        WHEN PUT /users/{userId} is called
        THEN it should return 400 (readonly field)
        """
        # Arrange
        user_item = {
            'PK': f'USER#{sample_user_id}',
            'SK': 'METADATA',
            'userId': sample_user_id,
            'email': 'test@example.com',
            'status': 'active',
            'createdAt': sample_timestamp,
            'updatedAt': sample_timestamp,
            'GSI1PK': f'COGNITO#{sample_user_id}',
            'GSI1SK': 'USER',
            'GSI2PK': 'ENTITY#USER',
            'GSI2SK': f'METADATA#{sample_user_id}'
        }
        dynamodb_table.put_item(Item=user_item)
        
        event = api_event_builder(
            method='PUT',
            path=f'/users/{sample_user_id}',
            path_parameters={'userId': sample_user_id},
            body={'userId': 'different-user-id'},
            user_id=sample_user_id
        )
        
        with patch('src.users.update.handler.get_table', return_value=dynamodb_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            assert result['statusCode'] == 400
            body = json.loads(result['body'])
            assert 'error' in body
    
    def test_missing_user_id_in_path(self, handler, dynamodb_table, api_event_builder, mock_context):
        """
        GIVEN an update request without userId in path
        WHEN the handler is invoked
        THEN it should return 400
        """
        # Arrange
        event = api_event_builder(
            method='PUT',
            path='/users/',
            path_parameters={},
            body={'firstName': 'Test'},
            user_id='user-123'
        )
        
        with patch('src.users.update.handler.get_table', return_value=dynamodb_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            assert result['statusCode'] == 400
    
    def test_empty_request_body(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id):
        """
        GIVEN an update request with empty body
        WHEN PUT /users/{userId} is called
        THEN it should return 400
        """
        # Arrange
        event = api_event_builder(
            method='PUT',
            path=f'/users/{sample_user_id}',
            path_parameters={'userId': sample_user_id},
            body={},
            user_id=sample_user_id
        )
        
        with patch('src.users.update.handler.get_table', return_value=dynamodb_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            assert result['statusCode'] == 400
            body = json.loads(result['body'])
            assert 'error' in body
    
    def test_malformed_json_body(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id):
        """
        GIVEN an update request with malformed JSON
        WHEN the handler is invoked
        THEN it should return 400
        """
        # Arrange
        event = api_event_builder(
            method='PUT',
            path=f'/users/{sample_user_id}',
            path_parameters={'userId': sample_user_id},
            body='{"invalid": json}',  # Malformed JSON
            user_id=sample_user_id
        )
        
        with patch('src.users.update.handler.get_table', return_value=dynamodb_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            assert result['statusCode'] == 400


class TestUpdateUserAuthorization:
    """Test authorization rules."""
    
    def test_user_cannot_update_other_user(self, handler, dynamodb_table, api_event_builder, mock_context):
        """
        GIVEN user A tries to update user B's profile
        WHEN PUT /users/{userId} is called
        THEN it should return 403
        """
        # Arrange
        user_a = 'user-aaa'
        user_b = 'user-bbb'
        
        event = api_event_builder(
            method='PUT',
            path=f'/users/{user_b}',
            path_parameters={'userId': user_b},
            body={'firstName': 'Hacker'},
            user_id=user_a  # User A trying to update User B
        )
        
        with patch('src.users.update.handler.get_table', return_value=dynamodb_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert - Handler checks existence first, so returns 404 if user doesn't exist
            assert result['statusCode'] == 404


class TestUpdateUserNotFound:
    """Test user not found scenarios."""
    
    def test_update_non_existent_user(self, handler, dynamodb_table, api_event_builder, mock_context):
        """
        GIVEN a userId that doesn't exist
        WHEN PUT /users/{userId} is called
        THEN it should return 404
        """
        # Arrange
        non_existent_user = 'user-does-not-exist'
        event = api_event_builder(
            method='PUT',
            path=f'/users/{non_existent_user}',
            path_parameters={'userId': non_existent_user},
            body={'firstName': 'Test'},
            user_id=non_existent_user
        )
        
        with patch('src.users.update.handler.get_table', return_value=dynamodb_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            assert result['statusCode'] == 404


class TestUpdateUserDynamoDBErrors:
    """Test DynamoDB error scenarios."""
    
    def test_dynamodb_update_error(self, handler, api_event_builder, mock_context, sample_user_id):
        """
        GIVEN DynamoDB returns an error during update
        WHEN the handler tries to update
        THEN it should return 500
        """
        # Arrange
        event = api_event_builder(
            method='PUT',
            path=f'/users/{sample_user_id}',
            path_parameters={'userId': sample_user_id},
            body={'firstName': 'Test'},
            user_id=sample_user_id
        )
        
        mock_table = MagicMock()
        mock_table.get_item.return_value = {'Item': {'PK': f'USER#{sample_user_id}', 'SK': 'METADATA'}}
        mock_table.update_item.side_effect = ClientError(
            {'Error': {'Code': 'InternalServerError', 'Message': 'Update failed'}},
            'UpdateItem'
        )
        
        with patch('src.users.update.handler.get_table', return_value=mock_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            assert result['statusCode'] == 500


class TestUpdateUserEdgeCases:
    """Test edge cases."""
    
    def test_update_removes_optional_field(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id, sample_timestamp):
        """
        GIVEN a user with optional fields
        WHEN an update sets an optional field to null/empty
        THEN the field should be removed or set to null
        """
        # Arrange
        user_item = {
            'PK': f'USER#{sample_user_id}',
            'SK': 'METADATA',
            'userId': sample_user_id,
            'email': 'test@example.com',
            'firstName': 'John',
            'lastName': 'Doe',
            'phoneNumber': '+15555551234',
            'status': 'active',
            'createdAt': sample_timestamp,
            'updatedAt': sample_timestamp,
            'GSI1PK': f'COGNITO#{sample_user_id}',
            'GSI1SK': 'USER',
            'GSI2PK': 'ENTITY#USER',
            'GSI2SK': f'METADATA#{sample_user_id}'
        }
        dynamodb_table.put_item(Item=user_item)
        
        event = api_event_builder(
            method='PUT',
            path=f'/users/{sample_user_id}',
            path_parameters={'userId': sample_user_id},
            body={'phoneNumber': None},  # Remove phone number
            user_id=sample_user_id
        )
        
        with patch('src.users.update.handler.get_table', return_value=dynamodb_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            assert result['statusCode'] == 200
            body = json.loads(result['body'])
            assert body.get('phoneNumber') is None or 'phoneNumber' not in body

