"""Unit tests for Get Game Lambda (GET /games/{gameId})"""

import json
import pytest
from unittest.mock import patch


@pytest.fixture
def handler():
    with patch('src.games.get.handler.get_table'):
        from src.games.get.handler import handler as lambda_handler
        yield lambda_handler


class TestGetGameSuccess:
    def test_get_game_by_id(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id, sample_team_id, sample_game_id, sample_timestamp):
        """Test getting a game by ID"""
        membership = {'PK': f'USER#{sample_user_id}', 'SK': f'TEAM#{sample_team_id}', 'status': 'active'}
        game = {'PK': f'GAME#{sample_game_id}', 'SK': 'METADATA', 'gameId': sample_game_id, 'teamId': sample_team_id, 'gameTitle': 'Test Game', 'status': 'SCHEDULED', 'teamScore': 0, 'opponentScore': 0, 'createdAt': sample_timestamp, 'updatedAt': sample_timestamp}
        dynamodb_table.put_item(Item=membership)
        dynamodb_table.put_item(Item=game)
        
        event = api_event_builder(method='GET', path=f'/games/{sample_game_id}', path_parameters={'gameId': sample_game_id}, user_id=sample_user_id)
        
        with patch('src.games.get.handler.get_table', return_value=dynamodb_table):
            result = handler(event, mock_context)
            assert result['statusCode'] == 200
            body = json.loads(result['body'])
            assert body['gameId'] == sample_game_id


class TestGetGameNotFound:
    def test_game_not_found(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id):
        """Test game not found returns 404"""
        event = api_event_builder(method='GET', path='/games/nonexistent', path_parameters={'gameId': 'nonexistent'}, user_id=sample_user_id)
        with patch('src.games.get.handler.get_table', return_value=dynamodb_table):
            result = handler(event, mock_context)
            assert result['statusCode'] in [403, 404]

