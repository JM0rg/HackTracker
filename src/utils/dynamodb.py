"""
DynamoDB utility functions

Provides shared functions for DynamoDB access across all Lambda functions

This module instantiates the client and table objects in the global scope.
This allows Lambda to re-use the same connection across warm invocations,
which is a major performance optimization.
"""

import os
import boto3


def _get_dynamodb_client():
    """
    (Internal) Get DynamoDB resource (works locally and in AWS)
    
    Returns:
        boto3.resource: DynamoDB resource
    """
    if os.environ.get('DYNAMODB_LOCAL') or os.environ.get('AWS_SAM_LOCAL'):
        return boto3.resource(
            'dynamodb',
            endpoint_url=os.environ.get('DYNAMODB_ENDPOINT', 'http://localhost:8000'),
            region_name='us-east-1',
            aws_access_key_id='dummy',
            aws_secret_access_key='dummy'
        )
    return boto3.resource('dynamodb')


def _get_table(dynamodb_client):
    """
    (Internal) Get DynamoDB table reference
    
    Args:
        dynamodb_client: boto3.resource - DynamoDB resource
    
    Returns:
        boto3.resource.Table: DynamoDB table
    """
    table_name = os.environ.get('TABLE_NAME', 'HackTracker-dev')
    return dynamodb_client.Table(table_name)


# --- GLOBAL SCOPE ---
# These are instantiated ONCE per Lambda container (cold start)
# and re-used for all subsequent warm invocations.
# This provides significant performance improvement on warm starts.
DYNAMODB_CLIENT = _get_dynamodb_client()
TABLE = _get_table(DYNAMODB_CLIENT)
# --------------------


def get_table():
    """
    Get the globally instantiated DynamoDB table object
    
    This function returns a table object that was created once at module load time.
    Lambda containers re-use this object across multiple invocations (warm starts),
    avoiding the overhead of creating new connections on every request.
    
    Returns:
        boto3.resource.Table: DynamoDB table
    """
    return TABLE

