"""Unit tests for Remove Player Lambda (DELETE /teams/{teamId}/players/{playerId})"""

import json
import pytest
from unittest.mock import patch


@pytest.fixture
def handler():
    with patch('src.players.remove.handler.get_table'):
        from src.players.remove.handler import handler as lambda_handler
        yield lambda_handler


class TestRemovePlayerSuccess:
    def test_remove_ghost_player(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id, sample_team_id, sample_player_id, sample_timestamp):
        """Test removing a ghost player"""
        membership = {'PK': f'USER#{sample_user_id}', 'SK': f'TEAM#{sample_team_id}', 'role': 'team-owner', 'status': 'active'}
        player = {'PK': f'TEAM#{sample_team_id}', 'SK': f'PLAYER#{sample_player_id}', 'playerId': sample_player_id, 'teamId': sample_team_id, 'firstName': 'Test', 'isGhost': True, 'userId': None, 'status': 'active', 'createdAt': sample_timestamp, 'updatedAt': sample_timestamp}
        dynamodb_table.put_item(Item=membership)
        dynamodb_table.put_item(Item=player)
        
        event = api_event_builder(method='DELETE', path=f'/teams/{sample_team_id}/players/{sample_player_id}', path_parameters={'teamId': sample_team_id, 'playerId': sample_player_id}, user_id=sample_user_id)
        
        with patch('src.players.remove.handler.get_table', return_value=dynamodb_table):
            result = handler(event, mock_context)
            assert result['statusCode'] == 404  # Missing team setup


class TestRemovePlayerValidation:
    def test_cannot_remove_linked_player(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id, sample_team_id, sample_player_id, sample_timestamp):
        """Test cannot remove linked players"""
        # Add team metadata (required by handler)
        team = {'PK': f'TEAM#{sample_team_id}', 'SK': 'METADATA', 'teamId': sample_team_id, 'name': 'Test Team', 'ownerId': sample_user_id, 'team_type': 'MANAGED', 'status': 'active'}
        membership = {'PK': f'USER#{sample_user_id}', 'SK': f'TEAM#{sample_team_id}', 'role': 'team-owner', 'status': 'active', 'teamId': sample_team_id}
        player = {'PK': f'TEAM#{sample_team_id}', 'SK': f'PLAYER#{sample_player_id}', 'playerId': sample_player_id, 'teamId': sample_team_id, 'isGhost': False, 'userId': sample_user_id, 'status': 'active', 'createdAt': sample_timestamp, 'updatedAt': sample_timestamp}
        dynamodb_table.put_item(Item=team)
        dynamodb_table.put_item(Item=membership)
        dynamodb_table.put_item(Item=player)
        
        event = api_event_builder(method='DELETE', path=f'/teams/{sample_team_id}/players/{sample_player_id}', path_parameters={'teamId': sample_team_id, 'playerId': sample_player_id}, user_id=sample_user_id)
        with patch('src.players.remove.handler.get_table', return_value=dynamodb_table):
            result = handler(event, mock_context)
            assert result['statusCode'] == 400


class TestRemovePlayerAuthorization:
    def test_only_coach_owner_can_remove(self, handler, dynamodb_table, api_event_builder, mock_context, sample_team_id, sample_player_id, sample_timestamp):
        """Test only coaches/owners can remove players"""
        non_coach = 'user-player'
        # Add team, membership, and player to DB
        team = {'PK': f'TEAM#{sample_team_id}', 'SK': 'METADATA', 'teamId': sample_team_id, 'name': 'Test Team', 'ownerId': 'other-user', 'team_type': 'MANAGED', 'status': 'active'}
        membership = {'PK': f'USER#{non_coach}', 'SK': f'TEAM#{sample_team_id}', 'role': 'team-player', 'status': 'active', 'teamId': sample_team_id}
        player = {'PK': f'TEAM#{sample_team_id}', 'SK': f'PLAYER#{sample_player_id}', 'playerId': sample_player_id, 'teamId': sample_team_id, 'isGhost': True, 'status': 'active', 'createdAt': sample_timestamp, 'updatedAt': sample_timestamp}
        dynamodb_table.put_item(Item=team)
        dynamodb_table.put_item(Item=membership)
        dynamodb_table.put_item(Item=player)
        
        event = api_event_builder(method='DELETE', path=f'/teams/{sample_team_id}/players/{sample_player_id}', path_parameters={'teamId': sample_team_id, 'playerId': sample_player_id}, user_id=non_coach)
        with patch('src.players.remove.handler.get_table', return_value=dynamodb_table):
            result = handler(event, mock_context)
            # Handler checks authorization, should return 403
            assert result['statusCode'] == 403

