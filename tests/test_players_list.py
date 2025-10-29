"""Unit tests for List Players Lambda (GET /teams/{teamId}/players)"""

import json
import pytest
from unittest.mock import patch, MagicMock
from botocore.exceptions import ClientError


@pytest.fixture
def handler():
    with patch('src.players.list.handler.get_table'):
        from src.players.list.handler import handler as lambda_handler
        yield lambda_handler


class TestListPlayersSuccess:
    def test_list_all_players(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id, sample_team_id, sample_player_id, sample_timestamp):
        """Test listing all team players"""
        team = {'PK': f'TEAM#{sample_team_id}', 'SK': 'METADATA', 'teamId': sample_team_id}
        membership = {'PK': f'USER#{sample_user_id}', 'SK': f'TEAM#{sample_team_id}', 'status': 'active'}
        player = {'PK': f'TEAM#{sample_team_id}', 'SK': f'PLAYER#{sample_player_id}', 'playerId': sample_player_id, 'teamId': sample_team_id, 'firstName': 'Test', 'status': 'active', 'createdAt': sample_timestamp, 'updatedAt': sample_timestamp}
        dynamodb_table.put_item(Item=team)
        dynamodb_table.put_item(Item=membership)
        dynamodb_table.put_item(Item=player)
        
        event = api_event_builder(method='GET', path=f'/teams/{sample_team_id}/players', path_parameters={'teamId': sample_team_id}, user_id=sample_user_id)
        
        with patch('src.players.list.handler.get_table', return_value=dynamodb_table):
            result = handler(event, mock_context)
            assert result['statusCode'] == 200
            body = json.loads(result['body'])
            assert 'players' in body
            assert len(body['players']) >= 1


class TestListPlayersAuthorization:
    def test_non_member_cannot_list(self, handler, dynamodb_table, api_event_builder, mock_context, sample_team_id):
        """Test non-members cannot list players"""
        non_member = 'user-outsider'
        team = {'PK': f'TEAM#{sample_team_id}', 'SK': 'METADATA', 'teamId': sample_team_id}
        dynamodb_table.put_item(Item=team)
        
        event = api_event_builder(method='GET', path=f'/teams/{sample_team_id}/players', path_parameters={'teamId': sample_team_id}, user_id=non_member)
        with patch('src.players.list.handler.get_table', return_value=dynamodb_table):
            result = handler(event, mock_context)
            assert result['statusCode'] == 403

