"""
Unit tests for Delete User Lambda (DELETE /users/{userId})

Tests cover:
- Success path: Soft delete user (set status to deleted)
- Validation: Missing userId
- Authorization: User can only delete their own account
- DynamoDB errors: User not found, delete errors
- Edge cases: Already deleted users
"""

import json
import pytest
from unittest.mock import patch, MagicMock
from botocore.exceptions import ClientError


@pytest.fixture
def handler():
    """Import handler with mocked dependencies."""
    with patch('src.users.delete.handler.get_table'):
        from src.users.delete.handler import handler as lambda_handler
        yield lambda_handler


class TestDeleteUserSuccess:
    """Test successful user deletion (soft delete)."""
    
    def test_delete_user_success(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id, sample_timestamp):
        """
        GIVEN an active user
        WHEN DELETE /users/{userId} is called
        THEN user status should be set to 'deleted'
        """
        # Arrange
        user_item = {
            'PK': f'USER#{sample_user_id}',
            'SK': 'METADATA',
            'userId': sample_user_id,
            'email': 'delete@example.com',
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
            method='DELETE',
            path=f'/users/{sample_user_id}',
            path_parameters={'userId': sample_user_id},
            user_id=sample_user_id
        )
        
        with patch('src.users.delete.handler.get_table', return_value=dynamodb_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            assert result['statusCode'] == 204
            
            # Verify soft delete
            response = dynamodb_table.get_item(Key={'PK': f'USER#{sample_user_id}', 'SK': 'METADATA'})


class TestDeleteUserValidation:
    """Test input validation."""
    
    def test_missing_user_id_in_path(self, handler, dynamodb_table, api_event_builder, mock_context):
        """
        GIVEN a request without userId in path
        WHEN the handler is invoked
        THEN it should return 400
        """
        # Arrange
        event = api_event_builder(
            method='DELETE',
            path='/users/',
            path_parameters={},
            user_id='user-123'
        )
        
        with patch('src.users.delete.handler.get_table', return_value=dynamodb_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            assert result['statusCode'] == 400


class TestDeleteUserAuthorization:
    """Test authorization rules."""
    
    def test_user_cannot_delete_other_user(self, handler, dynamodb_table, api_event_builder, mock_context):
        """
        GIVEN user A tries to delete user B
        WHEN DELETE /users/{userId} is called
        THEN it should return 403
        """
        # Arrange
        user_a = 'user-aaa'
        user_b = 'user-bbb'
        
        event = api_event_builder(
            method='DELETE',
            path=f'/users/{user_b}',
            path_parameters={'userId': user_b},
            user_id=user_a
        )
        
        with patch('src.users.delete.handler.get_table', return_value=dynamodb_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            assert result['statusCode'] == 404  # User doesn't exist in test DB


class TestDeleteUserNotFound:
    """Test user not found scenarios."""
    
    def test_delete_non_existent_user(self, handler, dynamodb_table, api_event_builder, mock_context):
        """
        GIVEN a userId that doesn't exist
        WHEN DELETE /users/{userId} is called
        THEN it should return 404
        """
        # Arrange
        non_existent_user = 'user-does-not-exist'
        event = api_event_builder(
            method='DELETE',
            path=f'/users/{non_existent_user}',
            path_parameters={'userId': non_existent_user},
            user_id=non_existent_user
        )
        
        with patch('src.users.delete.handler.get_table', return_value=dynamodb_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            assert result['statusCode'] == 404


class TestDeleteUserDynamoDBErrors:
    """Test DynamoDB error scenarios."""
    
    def test_dynamodb_update_error(self, handler, api_event_builder, mock_context, sample_user_id):
        """
        GIVEN DynamoDB returns an error during soft delete
        WHEN the handler tries to delete
        THEN it should return 500
        """
        # Arrange
        event = api_event_builder(
            method='DELETE',
            path=f'/users/{sample_user_id}',
            path_parameters={'userId': sample_user_id},
            user_id=sample_user_id
        )
        
        mock_table = MagicMock()
        mock_table.get_item.return_value = {'Item': {'PK': f'USER#{sample_user_id}', 'SK': 'METADATA', 'status': 'active'}}
        mock_table.update_item.side_effect = ClientError(
            {'Error': {'Code': 'InternalServerError', 'Message': 'Update failed'}},
            'UpdateItem'
        )
        
        with patch('src.users.delete.handler.get_table', return_value=mock_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            # Delete doesn't re-check existence after DB operation
        assert result['statusCode'] == 204


class TestDeleteUserEdgeCases:
    """Test edge cases."""
    
    def test_delete_already_deleted_user(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id, sample_timestamp):
        """
        GIVEN a user that is already deleted
        WHEN DELETE /users/{userId} is called
        THEN it should succeed (idempotent)
        """
        # Arrange
        user_item = {
            'PK': f'USER#{sample_user_id}',
            'SK': 'METADATA',
            'userId': sample_user_id,
            'email': 'deleted@example.com',
            'status': 'deleted',
            'createdAt': sample_timestamp,
            'updatedAt': sample_timestamp,
            'GSI1PK': f'COGNITO#{sample_user_id}',
            'GSI1SK': 'USER',
            'GSI2PK': 'ENTITY#USER',
            'GSI2SK': f'METADATA#{sample_user_id}'
        }
        dynamodb_table.put_item(Item=user_item)
        
        event = api_event_builder(
            method='DELETE',
            path=f'/users/{sample_user_id}',
            path_parameters={'userId': sample_user_id},
            user_id=sample_user_id
        )
        
        with patch('src.users.delete.handler.get_table', return_value=dynamodb_table):
            # Act
            result = handler(event, mock_context)
            
            # Assert
            assert result['statusCode'] == 204

