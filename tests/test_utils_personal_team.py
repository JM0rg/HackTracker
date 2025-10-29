"""
Unit tests for src/utils/personal_team.py

Tests the personal team creation utility functions.
"""

import pytest
from unittest.mock import Mock, MagicMock
from datetime import datetime, timezone
from botocore.exceptions import ClientError

from src.utils.personal_team import create_personal_team


@pytest.fixture
def mock_table():
    """Mock DynamoDB table"""
    table = Mock()
    table.name = 'HackTracker-test'
    table.meta = Mock()
    table.meta.client = Mock()
    return table


@pytest.fixture
def sample_timestamp():
    """Sample timestamp"""
    return datetime.now(timezone.utc).isoformat()


class TestCreatePersonalTeam:
    """Test create_personal_team function"""
    
    def test_create_personal_team_success(self, mock_table, sample_timestamp):
        """Test successful personal team creation"""
        # Arrange
        user_id = 'user-123'
        first_name = 'John'
        mock_table.meta.client.transact_write_items.return_value = {}
        
        # Act
        team_id, player_id = create_personal_team(mock_table, user_id, first_name, sample_timestamp)
        
        # Assert
        assert team_id is not None
        assert player_id is not None
        assert isinstance(team_id, str)
        assert isinstance(player_id, str)
        
        # Verify transaction was called with correct structure
        mock_table.meta.client.transact_write_items.assert_called_once()
        call_args = mock_table.meta.client.transact_write_items.call_args[1]
        assert 'TransactItems' in call_args
        assert len(call_args['TransactItems']) == 3
        
        # Verify team item
        team_put = call_args['TransactItems'][0]['Put']
        assert team_put['Item']['name'] == 'Personal Stats'
        assert team_put['Item']['ownerId'] == user_id
        assert team_put['Item']['isPersonal'] is True
        
        # Verify membership item
        membership_put = call_args['TransactItems'][1]['Put']
        assert membership_put['Item']['userId'] == user_id
        assert membership_put['Item']['role'] == 'team-owner'
        
        # Verify player item
        player_put = call_args['TransactItems'][2]['Put']
        assert player_put['Item']['firstName'] == first_name
        assert player_put['Item']['userId'] == user_id
        assert player_put['Item']['isGhost'] is False
    
    def test_create_personal_team_transaction_cancelled(self, mock_table, sample_timestamp):
        """Test personal team creation when transaction is cancelled"""
        # Arrange
        user_id = 'user-456'
        first_name = 'Jane'
        mock_table.meta.client.transact_write_items.side_effect = ClientError(
            {'Error': {'Code': 'TransactionCanceledException', 'Message': 'Transaction cancelled'}},
            'TransactWriteItems'
        )
        
        # Act
        team_id, player_id = create_personal_team(mock_table, user_id, first_name, sample_timestamp)
        
        # Assert
        assert team_id is None
        assert player_id is None
    
    def test_create_personal_team_dynamodb_error(self, mock_table, sample_timestamp):
        """Test personal team creation with general DynamoDB error"""
        # Arrange
        user_id = 'user-789'
        first_name = 'Bob'
        mock_table.meta.client.transact_write_items.side_effect = ClientError(
            {'Error': {'Code': 'InternalServerError', 'Message': 'DynamoDB error'}},
            'TransactWriteItems'
        )
        
        # Act
        team_id, player_id = create_personal_team(mock_table, user_id, first_name, sample_timestamp)
        
        # Assert
        assert team_id is None
        assert player_id is None
    
    def test_create_personal_team_generates_unique_ids(self, mock_table, sample_timestamp):
        """Test that team_id and player_id are different"""
        # Arrange
        user_id = 'user-unique'
        first_name = 'Alice'
        mock_table.meta.client.transact_write_items.return_value = {}
        
        # Act
        team_id, player_id = create_personal_team(mock_table, user_id, first_name, sample_timestamp)
        
        # Assert
        assert team_id != player_id
    
    def test_create_personal_team_with_special_characters_in_name(self, mock_table, sample_timestamp):
        """Test personal team creation with special characters in first name"""
        # Arrange
        user_id = 'user-special'
        first_name = "O'Brien"
        mock_table.meta.client.transact_write_items.return_value = {}
        
        # Act
        team_id, player_id = create_personal_team(mock_table, user_id, first_name, sample_timestamp)
        
        # Assert
        assert team_id is not None
        assert player_id is not None
        
        # Verify player has the special character name
        call_args = mock_table.meta.client.transact_write_items.call_args[1]
        player_put = call_args['TransactItems'][2]['Put']
        assert player_put['Item']['firstName'] == first_name

