"""Unit tests for Get Player Lambda (GET /teams/{teamId}/players/{playerId})"""

import json
import pytest
from unittest.mock import patch


@pytest.fixture
def handler():
    with patch('src.players.get.handler.get_table'):
        from src.players.get.handler import handler as lambda_handler
        yield lambda_handler


class TestGetPlayerSuccess:
    def test_get_player_success(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id, sample_team_id, sample_player_id, sample_timestamp):
        """Test getting a specific player"""
        membership = {'PK': f'USER#{sample_user_id}', 'SK': f'TEAM#{sample_team_id}', 'status': 'active'}
        player = {'PK': f'TEAM#{sample_team_id}', 'SK': f'PLAYER#{sample_player_id}', 'playerId': sample_player_id, 'teamId': sample_team_id, 'firstName': 'John', 'lastName': 'Doe', 'status': 'active', 'createdAt': sample_timestamp, 'updatedAt': sample_timestamp}
        dynamodb_table.put_item(Item=membership)
        dynamodb_table.put_item(Item=player)
        
        event = api_event_builder(method='GET', path=f'/teams/{sample_team_id}/players/{sample_player_id}', path_parameters={'teamId': sample_team_id, 'playerId': sample_player_id}, user_id=sample_user_id)
        
        with patch('src.players.get.handler.get_table', return_value=dynamodb_table):
            result = handler(event, mock_context)
            assert result['statusCode'] == 200
            body = json.loads(result['body'])
            assert body['playerId'] == sample_player_id
            assert body['firstName'] == 'John'


class TestGetPlayerNotFound:
    def test_player_not_found(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id, sample_team_id):
        """Test player not found returns 404"""
        membership = {'PK': f'USER#{sample_user_id}', 'SK': f'TEAM#{sample_team_id}', 'status': 'active'}
        dynamodb_table.put_item(Item=membership)
        
        event = api_event_builder(method='GET', path=f'/teams/{sample_team_id}/players/nonexistent', path_parameters={'teamId': sample_team_id, 'playerId': 'nonexistent'}, user_id=sample_user_id)
        with patch('src.players.get.handler.get_table', return_value=dynamodb_table):
            result = handler(event, mock_context)
            assert result['statusCode'] == 404

