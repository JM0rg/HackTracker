"""
Standard API Gateway response helpers.
"""

import json
from decimal import Decimal
from typing import Any, Dict, Optional


class DecimalEncoder(json.JSONEncoder):
    """JSON encoder that handles DynamoDB Decimal types"""
    def default(self, obj):
        if isinstance(obj, Decimal):
            # Convert to int if it's a whole number, otherwise float
            return int(obj) if obj % 1 == 0 else float(obj)
        return super(DecimalEncoder, self).default(obj)


def success_response(data: Any, status_code: int = 200) -> Dict[str, Any]:
    """
    Create a successful API Gateway response.
    
    Args:
        data: Response data (will be JSON serialized)
        status_code: HTTP status code (default 200)
        
    Returns:
        API Gateway response dict
    """
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',  # TODO: Restrict in production
            'Access-Control-Allow-Credentials': True,
        },
        'body': json.dumps(data, cls=DecimalEncoder)
    }


def error_response(message: str, status_code: int = 400, error_type: Optional[str] = None) -> Dict[str, Any]:
    """
    Create an error API Gateway response.
    
    Args:
        message: Error message
        status_code: HTTP status code
        error_type: Optional error type/code
        
    Returns:
        API Gateway response dict
    """
    body = {
        'error': message,
    }
    
    if error_type:
        body['errorType'] = error_type
    
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Credentials': True,
        },
        'body': json.dumps(body)
    }


def validation_error(message: str) -> Dict[str, Any]:
    """Create a 400 validation error response."""
    return error_response(message, 400, 'ValidationError')


def not_found_error(message: str = 'Resource not found') -> Dict[str, Any]:
    """Create a 404 not found response."""
    return error_response(message, 404, 'NotFound')


def forbidden_error(message: str = 'Access denied') -> Dict[str, Any]:
    """Create a 403 forbidden response."""
    return error_response(message, 403, 'Forbidden')


def server_error(message: str = 'Internal server error') -> Dict[str, Any]:
    """Create a 500 internal server error response."""
    return error_response(message, 500, 'InternalError')

