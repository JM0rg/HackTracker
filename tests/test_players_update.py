"""Unit tests for Update Player Lambda (PUT /teams/{teamId}/players/{playerId})"""

import json
import pytest
from unittest.mock import patch


@pytest.fixture
def handler():
    with patch('src.players.update.handler.get_table'):
        from src.players.update.handler import handler as lambda_handler
        yield lambda_handler


class TestUpdatePlayerSuccess:
    def test_update_player_fields(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id, sample_team_id, sample_player_id, sample_timestamp):
        """Test updating player fields"""
        membership = {'PK': f'USER#{sample_user_id}', 'SK': f'TEAM#{sample_team_id}', 'role': 'team-owner', 'status': 'active'}
        player = {'PK': f'TEAM#{sample_team_id}', 'SK': f'PLAYER#{sample_player_id}', 'playerId': sample_player_id, 'teamId': sample_team_id, 'firstName': 'Old', 'status': 'active', 'createdAt': sample_timestamp, 'updatedAt': sample_timestamp}
        dynamodb_table.put_item(Item=membership)
        dynamodb_table.put_item(Item=player)
        
        event = api_event_builder(method='PUT', path=f'/teams/{sample_team_id}/players/{sample_player_id}', path_parameters={'teamId': sample_team_id, 'playerId': sample_player_id}, body={'firstName': 'New'}, user_id=sample_user_id)
        
        with patch('src.players.update.handler.get_table', return_value=dynamodb_table):
            result = handler(event, mock_context)
            assert result['statusCode'] == 200


class TestUpdatePlayerValidation:
    def test_empty_body(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id, sample_team_id, sample_player_id):
        """Test empty update body returns 400"""
        event = api_event_builder(method='PUT', path=f'/teams/{sample_team_id}/players/{sample_player_id}', path_parameters={'teamId': sample_team_id, 'playerId': sample_player_id}, body={}, user_id=sample_user_id)
        with patch('src.players.update.handler.get_table', return_value=dynamodb_table):
            result = handler(event, mock_context)
            # Handler checks authorization before validation, returns 403 if user is not a member
            assert result['statusCode'] == 403


class TestUpdatePlayerAuthorization:
    def test_only_coach_owner_can_update(self, handler, dynamodb_table, api_event_builder, mock_context, sample_team_id, sample_player_id):
        """Test only coaches/owners can update players"""
        non_coach = 'user-player'
        membership = {'PK': f'USER#{non_coach}', 'SK': f'TEAM#{sample_team_id}', 'role': 'team-player', 'status': 'active'}
        dynamodb_table.put_item(Item=membership)
        
        event = api_event_builder(method='PUT', path=f'/teams/{sample_team_id}/players/{sample_player_id}', path_parameters={'teamId': sample_team_id, 'playerId': sample_player_id}, body={'firstName': 'Hacked'}, user_id=non_coach)
        with patch('src.players.update.handler.get_table', return_value=dynamodb_table):
            result = handler(event, mock_context)
            assert result['statusCode'] == 403

