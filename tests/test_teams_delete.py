"""Unit tests for Delete Team Lambda (DELETE /teams/{teamId})"""

import json
import pytest
from unittest.mock import patch, MagicMock
from botocore.exceptions import ClientError


@pytest.fixture
def handler():
    with patch('src.teams.delete.handler.get_table'):
        from src.teams.delete.handler import handler as lambda_handler
        yield lambda_handler


class TestDeleteTeamSuccess:
    def test_delete_team_success(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id, sample_team_id, sample_timestamp):
        """Test successful team deletion (soft delete)"""
        team = {'PK': f'TEAM#{sample_team_id}', 'SK': 'METADATA', 'teamId': sample_team_id, 'name': 'Test', 'ownerId': sample_user_id, 'status': 'active', 'createdAt': sample_timestamp, 'updatedAt': sample_timestamp}
        membership = {'PK': f'USER#{sample_user_id}', 'SK': f'TEAM#{sample_team_id}', 'userId': sample_user_id, 'teamId': sample_team_id, 'role': 'team-owner', 'status': 'active'}
        dynamodb_table.put_item(Item=team)
        dynamodb_table.put_item(Item=membership)
        
        event = api_event_builder(method='DELETE', path=f'/teams/{sample_team_id}', path_parameters={'teamId': sample_team_id}, user_id=sample_user_id)
        
        with patch('src.teams.delete.handler.get_table', return_value=dynamodb_table):
            result = handler(event, mock_context)
            assert result['statusCode'] == 204


class TestDeleteTeamAuthorization:
    def test_only_owner_can_delete(self, handler, dynamodb_table, api_event_builder, mock_context, sample_team_id, sample_timestamp):
        """Test only owner can delete team"""
        non_owner = 'user-non-owner'
        team = {'PK': f'TEAM#{sample_team_id}', 'SK': 'METADATA', 'teamId': sample_team_id, 'name': 'Test', 'ownerId': 'different-owner', 'status': 'active', 'createdAt': sample_timestamp, 'updatedAt': sample_timestamp}
        membership = {'PK': f'USER#{non_owner}', 'SK': f'TEAM#{sample_team_id}', 'userId': non_owner, 'teamId': sample_team_id, 'role': 'team-coach', 'status': 'active'}
        dynamodb_table.put_item(Item=team)
        dynamodb_table.put_item(Item=membership)
        
        event = api_event_builder(method='DELETE', path=f'/teams/{sample_team_id}', path_parameters={'teamId': sample_team_id}, user_id=non_owner)
        with patch('src.teams.delete.handler.get_table', return_value=dynamodb_table):
            result = handler(event, mock_context)
            assert result['statusCode'] == 403


class TestDeleteTeamNotFound:
    def test_delete_non_existent_team(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id):
        """Test deleting non-existent team"""
        event = api_event_builder(method='DELETE', path='/teams/nonexistent', path_parameters={'teamId': 'nonexistent'}, user_id=sample_user_id)
        with patch('src.teams.delete.handler.get_table', return_value=dynamodb_table):
            result = handler(event, mock_context)
            assert result['statusCode'] in [403, 404]

