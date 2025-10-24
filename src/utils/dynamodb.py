"""
DynamoDB utility functions

Provides shared functions for DynamoDB access across all Lambda functions
"""

import os
import boto3


def get_dynamodb_client():
    """
    Get DynamoDB resource (works locally and in AWS)
    
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


def get_table():
    """
    Get DynamoDB table reference
    
    Returns:
        boto3.resource.Table: DynamoDB table
    """
    dynamodb = get_dynamodb_client()
    table_name = os.environ.get('TABLE_NAME', 'HackTracker-dev')
    return dynamodb.Table(table_name)

