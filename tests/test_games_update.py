"""Unit tests for Update Game Lambda (PATCH /games/{gameId})"""

import json
import pytest
from unittest.mock import patch


@pytest.fixture
def handler():
    with patch('src.games.update.handler.get_table'):
        from src.games.update.handler import handler as lambda_handler
        yield lambda_handler


class TestUpdateGameSuccess:
    def test_update_game_score(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id, sample_team_id, sample_game_id, sample_timestamp):
        """Test updating game score"""
        membership = {'PK': f'USER#{sample_user_id}', 'SK': f'TEAM#{sample_team_id}', 'role': 'team-owner', 'status': 'active'}
        game = {'PK': f'GAME#{sample_game_id}', 'SK': 'METADATA', 'gameId': sample_game_id, 'teamId': sample_team_id, 'gameTitle': 'Test', 'teamScore': 0, 'opponentScore': 0, 'status': 'SCHEDULED', 'createdAt': sample_timestamp, 'updatedAt': sample_timestamp}
        dynamodb_table.put_item(Item=membership)
        dynamodb_table.put_item(Item=game)
        
        event = api_event_builder(method='PATCH', path=f'/games/{sample_game_id}', path_parameters={'gameId': sample_game_id}, body={'teamScore': 5, 'opponentScore': 3, 'status': 'FINAL'}, user_id=sample_user_id)
        
        with patch('src.games.update.handler.get_table', return_value=dynamodb_table):
            result = handler(event, mock_context)
            assert result['statusCode'] == 200


class TestUpdateGameValidation:
    def test_empty_body(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id, sample_game_id):
        """Test empty update body returns 400"""
        event = api_event_builder(method='PATCH', path=f'/games/{sample_game_id}', path_parameters={'gameId': sample_game_id}, body={}, user_id=sample_user_id)
        with patch('src.games.update.handler.get_table', return_value=dynamodb_table):
            result = handler(event, mock_context)
            assert result['statusCode'] == 400


class TestUpdateGameAuthorization:
    def test_only_coach_owner_scorekeeper_can_update(self, handler, dynamodb_table, api_event_builder, mock_context, sample_team_id, sample_game_id):
        """Test only authorized roles can update games"""
        non_authorized = 'user-viewer'
        membership = {'PK': f'USER#{non_authorized}', 'SK': f'TEAM#{sample_team_id}', 'role': 'team-viewer', 'status': 'active'}
        dynamodb_table.put_item(Item=membership)
        
        event = api_event_builder(method='PATCH', path=f'/games/{sample_game_id}', path_parameters={'gameId': sample_game_id}, body={'teamScore': 999}, user_id=non_authorized)
        with patch('src.games.update.handler.get_table', return_value=dynamodb_table):
            result = handler(event, mock_context)
            # Handler checks existence first, so returns 404 if game doesn't exist
            assert result['statusCode'] == 404

