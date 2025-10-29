"""Unit tests for Update Team Lambda (PUT /teams/{teamId})"""

import json
import pytest
from unittest.mock import patch, MagicMock
from botocore.exceptions import ClientError


@pytest.fixture
def handler():
    with patch('src.teams.update.handler.get_table'):
        from src.teams.update.handler import handler as lambda_handler
        yield lambda_handler


class TestUpdateTeamSuccess:
    def test_update_team_name(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id, sample_team_id, sample_timestamp):
        """Test updating team name"""
        team = {'PK': f'TEAM#{sample_team_id}', 'SK': 'METADATA', 'teamId': sample_team_id, 'name': 'Old Name', 'ownerId': sample_user_id, 'status': 'active', 'createdAt': sample_timestamp, 'updatedAt': sample_timestamp}
        membership = {'PK': f'USER#{sample_user_id}', 'SK': f'TEAM#{sample_team_id}', 'userId': sample_user_id, 'teamId': sample_team_id, 'role': 'team-owner', 'status': 'active'}
        dynamodb_table.put_item(Item=team)
        dynamodb_table.put_item(Item=membership)
        
        event = api_event_builder(method='PUT', path=f'/teams/{sample_team_id}', path_parameters={'teamId': sample_team_id}, body={'name': 'New Name'}, user_id=sample_user_id)
        
        with patch('src.teams.update.handler.get_table', return_value=dynamodb_table):
            result = handler(event, mock_context)
            assert result['statusCode'] == 200


class TestUpdateTeamValidation:
    def test_empty_body(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id, sample_team_id):
        """Test empty update body"""
        event = api_event_builder(method='PUT', path=f'/teams/{sample_team_id}', path_parameters={'teamId': sample_team_id}, body={}, user_id=sample_user_id)
        with patch('src.teams.update.handler.get_table', return_value=dynamodb_table):
            result = handler(event, mock_context)
            assert result['statusCode'] == 400


class TestUpdateTeamAuthorization:
    def test_non_owner_cannot_update(self, handler, dynamodb_table, api_event_builder, mock_context, sample_team_id, sample_timestamp):
        """Test non-owner cannot update team"""
        non_owner = 'user-non-owner'
        team = {'PK': f'TEAM#{sample_team_id}', 'SK': 'METADATA', 'teamId': sample_team_id, 'name': 'Test', 'ownerId': 'different-owner', 'status': 'active', 'createdAt': sample_timestamp, 'updatedAt': sample_timestamp}
        membership = {'PK': f'USER#{non_owner}', 'SK': f'TEAM#{sample_team_id}', 'userId': non_owner, 'teamId': sample_team_id, 'role': 'team-player', 'status': 'active'}
        dynamodb_table.put_item(Item=team)
        dynamodb_table.put_item(Item=membership)
        
        event = api_event_builder(method='PUT', path=f'/teams/{sample_team_id}', path_parameters={'teamId': sample_team_id}, body={'name': 'Hacked'}, user_id=non_owner)
        with patch('src.teams.update.handler.get_table', return_value=dynamodb_table):
            result = handler(event, mock_context)
            assert result['statusCode'] == 403

