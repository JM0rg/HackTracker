"""
Pytest configuration and shared fixtures for Lambda function tests

This module provides shared fixtures for testing Lambda functions including:
- DynamoDB table mocking
- Event builders
- Common test data
"""

import os
import pytest
import boto3
from moto import mock_aws
from datetime import datetime, timezone


# Set environment variables for testing
os.environ['TABLE_NAME'] = 'HackTracker-test'
os.environ['ENVIRONMENT'] = 'test'
os.environ['AWS_DEFAULT_REGION'] = 'us-east-1'


@pytest.fixture
def aws_credentials():
    """Mocked AWS Credentials for moto."""
    os.environ['AWS_ACCESS_KEY_ID'] = 'testing'
    os.environ['AWS_SECRET_ACCESS_KEY'] = 'testing'
    os.environ['AWS_SECURITY_TOKEN'] = 'testing'
    os.environ['AWS_SESSION_TOKEN'] = 'testing'


@pytest.fixture
def dynamodb_table(aws_credentials):
    """Create a mocked DynamoDB table for testing."""
    with mock_aws():
        dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
        
        # Create table with same schema as production
        table = dynamodb.create_table(
            TableName='HackTracker-test',
            KeySchema=[
                {'AttributeName': 'PK', 'KeyType': 'HASH'},
                {'AttributeName': 'SK', 'KeyType': 'RANGE'}
            ],
            AttributeDefinitions=[
                {'AttributeName': 'PK', 'AttributeType': 'S'},
                {'AttributeName': 'SK', 'AttributeType': 'S'},
                {'AttributeName': 'GSI1PK', 'AttributeType': 'S'},
                {'AttributeName': 'GSI1SK', 'AttributeType': 'S'},
                {'AttributeName': 'GSI2PK', 'AttributeType': 'S'},
                {'AttributeName': 'GSI2SK', 'AttributeType': 'S'},
                {'AttributeName': 'GSI3PK', 'AttributeType': 'S'},
                {'AttributeName': 'GSI3SK', 'AttributeType': 'S'},
                {'AttributeName': 'GSI4PK', 'AttributeType': 'S'},
                {'AttributeName': 'GSI4SK', 'AttributeType': 'S'},
                {'AttributeName': 'GSI5PK', 'AttributeType': 'S'},
                {'AttributeName': 'GSI5SK', 'AttributeType': 'S'},
            ],
            GlobalSecondaryIndexes=[
                {
                    'IndexName': 'GSI1',
                    'KeySchema': [
                        {'AttributeName': 'GSI1PK', 'KeyType': 'HASH'},
                        {'AttributeName': 'GSI1SK', 'KeyType': 'RANGE'}
                    ],
                    'Projection': {'ProjectionType': 'ALL'}
                },
                {
                    'IndexName': 'GSI2',
                    'KeySchema': [
                        {'AttributeName': 'GSI2PK', 'KeyType': 'HASH'},
                        {'AttributeName': 'GSI2SK', 'KeyType': 'RANGE'}
                    ],
                    'Projection': {'ProjectionType': 'ALL'}
                },
                {
                    'IndexName': 'GSI3',
                    'KeySchema': [
                        {'AttributeName': 'GSI3PK', 'KeyType': 'HASH'},
                        {'AttributeName': 'GSI3SK', 'KeyType': 'RANGE'}
                    ],
                    'Projection': {'ProjectionType': 'ALL'}
                },
                {
                    'IndexName': 'GSI4',
                    'KeySchema': [
                        {'AttributeName': 'GSI4PK', 'KeyType': 'HASH'},
                        {'AttributeName': 'GSI4SK', 'KeyType': 'RANGE'}
                    ],
                    'Projection': {'ProjectionType': 'ALL'}
                },
                {
                    'IndexName': 'GSI5',
                    'KeySchema': [
                        {'AttributeName': 'GSI5PK', 'KeyType': 'HASH'},
                        {'AttributeName': 'GSI5SK', 'KeyType': 'RANGE'}
                    ],
                    'Projection': {'ProjectionType': 'ALL'}
                }
            ],
            BillingMode='PAY_PER_REQUEST'
        )
        
        yield table


@pytest.fixture
def sample_user_id():
    """Sample user ID for testing."""
    return 'user-12345678-1234-1234-1234-123456789012'


@pytest.fixture
def sample_team_id():
    """Sample team ID for testing."""
    return 'team-a6f27724-7042-4816-94d3-a2183ef50a09'


@pytest.fixture
def sample_player_id():
    """Sample player ID for testing."""
    return 'player-b7e38835-8153-5927-a5e4-b3294fg61b1a'


@pytest.fixture
def sample_game_id():
    """Sample game ID for testing."""
    return 'game-c8f49946-9264-6a38-b6f5-c4395gh72c2b'


@pytest.fixture
def sample_timestamp():
    """Sample timestamp for testing."""
    return datetime.now(timezone.utc).isoformat()


def create_api_gateway_event(
    method='GET',
    path='/',
    path_parameters=None,
    query_string_parameters=None,
    body=None,
    headers=None,
    user_id=None
):
    """
    Create a mock API Gateway event (HTTP API format 2.0).
    
    Args:
        method: HTTP method
        path: Request path
        path_parameters: Path parameters dict
        query_string_parameters: Query string parameters dict
        body: Request body (will be JSON stringified if dict)
        headers: Request headers dict
        user_id: User ID for JWT claims (Cognito sub)
    
    Returns:
        API Gateway event dict
    """
    import json
    
    event = {
        'version': '2.0',
        'routeKey': f'{method} {path}',
        'rawPath': path,
        'requestContext': {
            'http': {
                'method': method,
                'path': path
            },
            'authorizer': {}
        },
        'headers': headers or {},
        'pathParameters': path_parameters or {},
        'queryStringParameters': query_string_parameters or {}
    }
    
    # Add JWT claims if user_id provided
    if user_id:
        event['requestContext']['authorizer']['jwt'] = {
            'claims': {
                'sub': user_id,
                'email': f'{user_id}@example.com'
            }
        }
    
    # Add body
    if body is not None:
        if isinstance(body, dict):
            event['body'] = json.dumps(body)
        else:
            event['body'] = body
    
    return event


def create_cognito_event(user_id, email, attributes=None):
    """
    Create a mock Cognito post-confirmation trigger event.
    
    Args:
        user_id: User ID (Cognito sub)
        email: User email
        attributes: Additional user attributes dict
    
    Returns:
        Cognito trigger event dict
    """
    base_attributes = {
        'sub': user_id,
        'email': email,
        'email_verified': 'true'
    }
    
    if attributes:
        base_attributes.update(attributes)
    
    return {
        'version': '1',
        'region': 'us-east-1',
        'userPoolId': 'us-east-1_TEST',
        'userName': user_id,
        'triggerSource': 'PostConfirmation_ConfirmSignUp',
        'request': {
            'userAttributes': base_attributes
        },
        'response': {}
    }


@pytest.fixture
def api_event_builder():
    """Fixture that returns the event builder function."""
    return create_api_gateway_event


@pytest.fixture
def cognito_event_builder():
    """Fixture that returns the Cognito event builder function."""
    return create_cognito_event


@pytest.fixture
def mock_context():
    """Create a mock Lambda context object."""
    class MockContext:
        def __init__(self):
            self.function_name = 'test-function'
            self.function_version = '1'
            self.invoked_function_arn = 'arn:aws:lambda:us-east-1:123456789012:function:test-function'
            self.memory_limit_in_mb = 128
            self.aws_request_id = 'test-request-id'
            self.log_group_name = '/aws/lambda/test-function'
            self.log_stream_name = 'test-stream'
            
        def get_remaining_time_in_millis(self):
            return 30000
    
    return MockContext()

