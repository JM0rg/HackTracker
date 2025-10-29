"""Unit tests for List Games Lambda (GET /teams/{teamId}/games)"""

import json
import pytest
from unittest.mock import patch


@pytest.fixture
def handler():
    with patch('src.games.list.handler.get_table'):
        from src.games.list.handler import handler as lambda_handler
        yield lambda_handler


class TestListGamesSuccess:
    def test_list_team_games(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id, sample_team_id, sample_game_id, sample_timestamp):
        """Test listing games for a team"""
        membership = {'PK': f'USER#{sample_user_id}', 'SK': f'TEAM#{sample_team_id}', 'status': 'active'}
        game = {'PK': f'GAME#{sample_game_id}', 'SK': 'METADATA', 'gameId': sample_game_id, 'teamId': sample_team_id, 'gameTitle': 'Test Game', 'status': 'SCHEDULED', 'createdAt': sample_timestamp, 'updatedAt': sample_timestamp, 'GSI3PK': f'TEAM#{sample_team_id}', 'GSI3SK': f'GAME#{sample_game_id}'}
        dynamodb_table.put_item(Item=membership)
        dynamodb_table.put_item(Item=game)
        
        event = api_event_builder(method='GET', path=f'/teams/{sample_team_id}/games', path_parameters={'teamId': sample_team_id}, user_id=sample_user_id)
        
        with patch('src.games.list.handler.get_table', return_value=dynamodb_table):
            result = handler(event, mock_context)
            assert result['statusCode'] == 200
            body = json.loads(result['body'])
            assert isinstance(body, list)


class TestListGamesAuthorization:
    def test_non_member_cannot_list_games(self, handler, dynamodb_table, api_event_builder, mock_context, sample_team_id):
        """Test non-members cannot list games"""
        non_member = 'user-outsider'
        event = api_event_builder(method='GET', path=f'/teams/{sample_team_id}/games', path_parameters={'teamId': sample_team_id}, user_id=non_member)
        with patch('src.games.list.handler.get_table', return_value=dynamodb_table):
            result = handler(event, mock_context)
            assert result['statusCode'] == 403

