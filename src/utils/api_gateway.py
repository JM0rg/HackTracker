"""
API Gateway utility functions

Provides shared functions for API Gateway responses
"""

import json
from decimal import Decimal


class DecimalEncoder(json.JSONEncoder):
    """JSON encoder that handles Decimal types from DynamoDB"""
    def default(self, obj):
        if isinstance(obj, Decimal):
            return int(obj) if obj % 1 == 0 else float(obj)
        return super(DecimalEncoder, self).default(obj)


def create_response(status_code, body, additional_headers=None):
    """
    Create API Gateway response
    
    Args:
        status_code (int): HTTP status code
        body (dict): Response body (will be JSON encoded)
        additional_headers (dict, optional): Additional headers to include
    
    Returns:
        dict: API Gateway response format
    """
    headers = {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
    }
    
    # Merge additional headers if provided
    if additional_headers:
        headers.update(additional_headers)
    
    return {
        'statusCode': status_code,
        'headers': headers,
        'body': json.dumps(body, cls=DecimalEncoder)
    }

