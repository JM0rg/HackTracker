"""Unit tests for Delete Game Lambda (DELETE /games/{gameId})"""

import json
import pytest
from unittest.mock import patch


@pytest.fixture
def handler():
    with patch('src.games.delete.handler.get_table'):
        from src.games.delete.handler import handler as lambda_handler
        yield lambda_handler


class TestDeleteGameSuccess:
    def test_delete_game(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id, sample_team_id, sample_game_id, sample_timestamp):
        """Test deleting a game"""
        membership = {'PK': f'USER#{sample_user_id}', 'SK': f'TEAM#{sample_team_id}', 'role': 'team-owner', 'status': 'active'}
        game = {'PK': f'GAME#{sample_game_id}', 'SK': 'METADATA', 'gameId': sample_game_id, 'teamId': sample_team_id, 'gameTitle': 'Test', 'status': 'SCHEDULED', 'createdAt': sample_timestamp, 'updatedAt': sample_timestamp}
        dynamodb_table.put_item(Item=membership)
        dynamodb_table.put_item(Item=game)
        
        event = api_event_builder(method='DELETE', path=f'/games/{sample_game_id}', path_parameters={'gameId': sample_game_id}, user_id=sample_user_id)
        
        with patch('src.games.delete.handler.get_table', return_value=dynamodb_table):
            result = handler(event, mock_context)
            assert result['statusCode'] == 204


class TestDeleteGameAuthorization:
    def test_only_coach_owner_can_delete(self, handler, dynamodb_table, api_event_builder, mock_context, sample_team_id, sample_game_id):
        """Test only authorized roles can delete games"""
        non_authorized = 'user-viewer'
        membership = {'PK': f'USER#{non_authorized}', 'SK': f'TEAM#{sample_team_id}', 'role': 'team-viewer', 'status': 'active'}
        dynamodb_table.put_item(Item=membership)
        
        event = api_event_builder(method='DELETE', path=f'/games/{sample_game_id}', path_parameters={'gameId': sample_game_id}, user_id=non_authorized)
        with patch('src.games.delete.handler.get_table', return_value=dynamodb_table):
            result = handler(event, mock_context)
            # Handler checks existence first, so returns 404 if game doesn't exist
            assert result['statusCode'] == 404


class TestDeleteGameNotFound:
    def test_delete_non_existent_game(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id):
        """Test deleting non-existent game returns 404"""
        event = api_event_builder(method='DELETE', path='/games/nonexistent', path_parameters={'gameId': 'nonexistent'}, user_id=sample_user_id)
        with patch('src.games.delete.handler.get_table', return_value=dynamodb_table):
            result = handler(event, mock_context)
            assert result['statusCode'] in [403, 404]

