"""
Authentication and Authorization utilities for API Gateway Lambda functions.

Extracts user information from Cognito JWT tokens passed via API Gateway.
"""

from typing import Optional, Dict, Any


def get_user_from_event(event: Dict[str, Any]) -> Dict[str, str]:
    """
    Extract user information from API Gateway authorizer context.
    
    Supports both API Gateway V1 and V2 JWT authorizer formats:
    - V2: event['requestContext']['authorizer']['jwt']['claims']
    - V1: event['requestContext']['authorizer']['claims']
    
    Args:
        event: API Gateway event
        
    Returns:
        Dict with user info: {
            'cognitoSub': str,
            'email': str,
            'givenName': str,
            'familyName': str
        }
        
    Raises:
        ValueError: If user claims are missing
    """
    try:
        authorizer = event.get('requestContext', {}).get('authorizer', {})
        
        # API Gateway V2 HTTP API with JWT authorizer
        if 'jwt' in authorizer:
            claims = authorizer['jwt']['claims']
        # API Gateway V1 REST API or legacy format
        elif 'claims' in authorizer:
            claims = authorizer['claims']
        else:
            raise ValueError("No JWT claims found in authorizer context")
        
        user_info = {
            'cognitoSub': claims['sub'],
            'email': claims.get('email', ''),
            'givenName': claims.get('given_name', ''),
            'familyName': claims.get('family_name', ''),
        }
        
        return user_info
        
    except (KeyError, TypeError) as e:
        raise ValueError(f"Unable to extract user from event: {e}")


def require_auth(event: Dict[str, Any]) -> Dict[str, str]:
    """
    Ensure the request is authenticated and return user info.
    
    Args:
        event: API Gateway event
        
    Returns:
        User info dict
        
    Raises:
        ValueError: If authentication is missing
    """
    user_info = get_user_from_event(event)
    
    if not user_info.get('cognitoSub'):
        raise ValueError("Authentication required")
    
    return user_info

