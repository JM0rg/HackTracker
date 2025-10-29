"""Unit tests for Create Game Lambda (POST /games)"""

import json
import pytest
from unittest.mock import patch, MagicMock
from botocore.exceptions import ClientError


@pytest.fixture
def handler():
    with patch('src.games.create.handler.get_table'):
        from src.games.create.handler import handler as lambda_handler
        yield lambda_handler


class TestCreateGameSuccess:
    def test_create_game_with_team_id(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id, sample_team_id, sample_timestamp):
        """Test creating a game for a team"""
        team = {'PK': f'TEAM#{sample_team_id}', 'SK': 'METADATA', 'teamId': sample_team_id, 'team_type': 'MANAGED', 'status': 'active'}
        membership = {'PK': f'USER#{sample_user_id}', 'SK': f'TEAM#{sample_team_id}', 'role': 'team-owner', 'status': 'active'}
        dynamodb_table.put_item(Item=team)
        dynamodb_table.put_item(Item=membership)
        
        event = api_event_builder(method='POST', path='/games', body={'gameTitle': 'Test Game', 'teamId': sample_team_id, 'opponentName': 'Rivals'}, user_id=sample_user_id)
        
        with patch('src.games.create.handler.get_table', return_value=dynamodb_table):
            result = handler(event, mock_context)
            assert result['statusCode'] == 201
            body = json.loads(result['body'])
            assert body['gameTitle'] == 'Test Game'
            assert 'gameId' in body
    
    def test_create_game_with_default_personal_team(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id, sample_timestamp):
        """Test creating game without teamId uses Default personal team"""
        personal_team_id = 'team-personal-default'
        membership = {'PK': f'USER#{sample_user_id}', 'SK': f'TEAM#{personal_team_id}', 'teamId': personal_team_id, 'role': 'team-owner', 'status': 'active'}
        team = {'PK': f'TEAM#{personal_team_id}', 'SK': 'METADATA', 'teamId': personal_team_id, 'name': 'Default', 'team_type': 'PERSONAL', 'status': 'active'}
        dynamodb_table.put_item(Item=membership)
        dynamodb_table.put_item(Item=team)
        
        event = api_event_builder(method='POST', path='/games', body={'gameTitle': 'Personal Game'}, user_id=sample_user_id)
        
        with patch('src.games.create.handler.get_table', return_value=dynamodb_table):
            result = handler(event, mock_context)
            assert result['statusCode'] == 201


class TestCreateGameValidation:
    def test_missing_game_title(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id, sample_team_id):
        """Test missing gameTitle returns 400"""
        event = api_event_builder(method='POST', path='/games', body={'teamId': sample_team_id}, user_id=sample_user_id)
        with patch('src.games.create.handler.get_table', return_value=dynamodb_table):
            result = handler(event, mock_context)
            assert result['statusCode'] == 400
    
    def test_invalid_game_title_too_short(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id, sample_team_id):
        """Test game title too short returns 400"""
        event = api_event_builder(method='POST', path='/games', body={'gameTitle': 'AB', 'teamId': sample_team_id}, user_id=sample_user_id)
        with patch('src.games.create.handler.get_table', return_value=dynamodb_table):
            result = handler(event, mock_context)
            assert result['statusCode'] == 400


class TestCreateGameAuthorization:
    def test_only_coach_owner_scorekeeper_can_create(self, handler, dynamodb_table, api_event_builder, mock_context, sample_team_id):
        """Test only authorized roles can create games"""
        non_authorized = 'user-viewer'
        membership = {'PK': f'USER#{non_authorized}', 'SK': f'TEAM#{sample_team_id}', 'role': 'team-viewer', 'status': 'active'}
        dynamodb_table.put_item(Item=membership)
        
        event = api_event_builder(method='POST', path='/games', body={'gameTitle': 'Test Game', 'teamId': sample_team_id}, user_id=non_authorized)
        with patch('src.games.create.handler.get_table', return_value=dynamodb_table):
            result = handler(event, mock_context)
            assert result['statusCode'] == 403

