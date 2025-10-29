"""Unit tests for Add Player Lambda (POST /teams/{teamId}/players)"""

import json
import pytest
from unittest.mock import patch, MagicMock
from botocore.exceptions import ClientError


@pytest.fixture
def handler():
    with patch('src.players.add.handler.get_table'):
        from src.players.add.handler import handler as lambda_handler
        yield lambda_handler


class TestAddPlayerSuccess:
    def test_add_ghost_player(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id, sample_team_id, sample_timestamp):
        """Test adding a ghost player to roster"""
        team = {'PK': f'TEAM#{sample_team_id}', 'SK': 'METADATA', 'teamId': sample_team_id, 'name': 'Test', 'ownerId': sample_user_id, 'team_type': 'MANAGED', 'status': 'active'}
        membership = {'PK': f'USER#{sample_user_id}', 'SK': f'TEAM#{sample_team_id}', 'userId': sample_user_id, 'teamId': sample_team_id, 'role': 'team-owner', 'status': 'active'}
        dynamodb_table.put_item(Item=team)
        dynamodb_table.put_item(Item=membership)
        
        event = api_event_builder(method='POST', path=f'/teams/{sample_team_id}/players', path_parameters={'teamId': sample_team_id}, body={'firstName': 'John', 'lastName': 'Doe', 'playerNumber': 42}, user_id=sample_user_id)
        
        with patch('src.players.add.handler.get_table', return_value=dynamodb_table):
            result = handler(event, mock_context)
            assert result['statusCode'] == 201
            body = json.loads(result['body'])
            assert body['firstName'] == 'John'
            assert body['isGhost'] is True


class TestAddPlayerValidation:
    def test_missing_first_name(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id, sample_team_id):
        """Test missing firstName returns 400"""
        event = api_event_builder(method='POST', path=f'/teams/{sample_team_id}/players', path_parameters={'teamId': sample_team_id}, body={'lastName': 'Doe'}, user_id=sample_user_id)
        with patch('src.players.add.handler.get_table', return_value=dynamodb_table):
            result = handler(event, mock_context)
            assert result['statusCode'] == 400
    
    def test_cannot_add_to_personal_team(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id, sample_team_id):
        """Test cannot add players to PERSONAL teams"""
        team = {'PK': f'TEAM#{sample_team_id}', 'SK': 'METADATA', 'teamId': sample_team_id, 'team_type': 'PERSONAL', 'status': 'active'}
        dynamodb_table.put_item(Item=team)
        
        event = api_event_builder(method='POST', path=f'/teams/{sample_team_id}/players', path_parameters={'teamId': sample_team_id}, body={'firstName': 'Test'}, user_id=sample_user_id)
        with patch('src.players.add.handler.get_table', return_value=dynamodb_table):
            result = handler(event, mock_context)
            assert result['statusCode'] == 400


class TestAddPlayerAuthorization:
    def test_only_coach_owner_can_add(self, handler, dynamodb_table, api_event_builder, mock_context, sample_team_id):
        """Test only coaches/owners can add players"""
        non_coach = 'user-player'
        team = {'PK': f'TEAM#{sample_team_id}', 'SK': 'METADATA', 'teamId': sample_team_id, 'team_type': 'MANAGED', 'status': 'active'}
        membership = {'PK': f'USER#{non_coach}', 'SK': f'TEAM#{sample_team_id}', 'userId': non_coach, 'teamId': sample_team_id, 'role': 'team-player', 'status': 'active'}
        dynamodb_table.put_item(Item=team)
        dynamodb_table.put_item(Item=membership)
        
        event = api_event_builder(method='POST', path=f'/teams/{sample_team_id}/players', path_parameters={'teamId': sample_team_id}, body={'firstName': 'Test'}, user_id=non_coach)
        with patch('src.players.add.handler.get_table', return_value=dynamodb_table):
            result = handler(event, mock_context)
            assert result['statusCode'] == 403

