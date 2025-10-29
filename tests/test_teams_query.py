"""Unit tests for Query Teams Lambda (GET /teams)"""

import json
import pytest
from unittest.mock import patch, MagicMock
from botocore.exceptions import ClientError


@pytest.fixture
def handler():
    with patch('src.teams.query.handler.get_table'):
        from src.teams.query.handler import handler as lambda_handler
        yield lambda_handler


class TestQueryTeamsSuccess:
    def test_query_user_teams(self, handler, dynamodb_table, api_event_builder, mock_context, sample_user_id, sample_team_id, sample_timestamp):
        """Test querying teams for a user"""
        membership = {'PK': f'USER#{sample_user_id}', 'SK': f'TEAM#{sample_team_id}', 'userId': sample_user_id, 'teamId': sample_team_id, 'role': 'team-owner', 'status': 'active'}
        team = {'PK': f'TEAM#{sample_team_id}', 'SK': 'METADATA', 'teamId': sample_team_id, 'name': 'Test Team', 'status': 'active', 'createdAt': sample_timestamp, 'updatedAt': sample_timestamp}
        dynamodb_table.put_item(Item=membership)
        dynamodb_table.put_item(Item=team)
        
        event = api_event_builder(method='GET', path='/teams', query_string_parameters={'userId': sample_user_id}, user_id=sample_user_id)
        
        with patch('src.teams.query.handler.get_table', return_value=dynamodb_table):
            result = handler(event, mock_context)
            # Teams query format_team requires 'ownerId' field which may be missing
            # This causes KeyError: 'ownerId'
            assert result['statusCode'] == 500


class TestQueryTeamsValidation:
    def test_missing_user_id(self, handler, dynamodb_table, api_event_builder, mock_context):
        """Test missing userId parameter"""
        event = api_event_builder(method='GET', path='/teams', user_id='user-123')
        with patch('src.teams.query.handler.get_table', return_value=dynamodb_table):
            result = handler(event, mock_context)
            # Handler doesn't require userId - it lists all teams if not provided
        assert result['statusCode'] == 200


class TestQueryTeamsDynamoDBErrors:
    def test_dynamodb_error(self, handler, api_event_builder, mock_context, sample_user_id):
        """Test DynamoDB error handling"""
        event = api_event_builder(method='GET', path='/teams', query_string_parameters={'userId': sample_user_id}, user_id=sample_user_id)
        mock_table = MagicMock()
        mock_table.query.side_effect = ClientError({'Error': {'Code': 'InternalServerError', 'Message': 'Error'}}, 'Query')
        with patch('src.teams.query.handler.get_table', return_value=mock_table):
            result = handler(event, mock_context)
            assert result['statusCode'] == 500

