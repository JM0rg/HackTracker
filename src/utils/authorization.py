"""
Authorization utilities for HackTracker

Provides role-based access control for team operations
"""

import json


class PermissionError(Exception):
    """Custom exception for permission-related errors"""
    pass


def check_team_role(table, user_id, team_id, required_roles):
    """
    Check if user has required role on team
    
    Args:
        table: DynamoDB table resource
        user_id (str): User ID to check
        team_id (str): Team ID to check
        required_roles (list): List of acceptable roles (e.g., ['team-owner', 'team-coach'])
        
    Returns:
        dict: Membership record if authorized
        
    Raises:
        PermissionError: If user is not authorized
    """
    # Query user's membership for this team
    response = table.get_item(
        Key={
            'PK': f'USER#{user_id}',
            'SK': f'TEAM#{team_id}'
        }
    )
    
    # Check if membership exists
    if 'Item' not in response:
        print(json.dumps({
            'level': 'WARN',
            'message': 'User is not a member of this team',
            'userId': user_id,
            'teamId': team_id
        }))
        raise PermissionError("User is not a member of this team")
    
    membership = response['Item']
    
    # Check if membership is active
    if membership.get('status') != 'active':
        print(json.dumps({
            'level': 'WARN',
            'message': 'Team membership is not active',
            'userId': user_id,
            'teamId': team_id,
            'status': membership.get('status')
        }))
        raise PermissionError("Team membership is not active")
    
    # Check if user has required role
    user_role = membership.get('role')
    if user_role not in required_roles:
        print(json.dumps({
            'level': 'WARN',
            'message': 'Insufficient permissions',
            'userId': user_id,
            'teamId': team_id,
            'userRole': user_role,
            'requiredRoles': required_roles
        }))
        raise PermissionError(f"Insufficient permissions. Required: {', '.join(required_roles)}")
    
    print(json.dumps({
        'level': 'INFO',
        'message': 'Authorization check passed',
        'userId': user_id,
        'teamId': team_id,
        'role': user_role
    }))
    
    return membership


def get_user_id_from_event(event):
    """
    Extract user ID from API Gateway event
    
    Extracts from JWT authorizer claims (populated by API Gateway JWT authorizer)
    Falls back to X-User-Id header for local testing
    
    Args:
        event: API Gateway event
        
    Returns:
        str: User ID (Cognito sub)
        
    Raises:
        ValueError: If user ID not found
    """
    # Extract from JWT authorizer context (set by API Gateway JWT authorizer)
    try:
        claims = event.get('requestContext', {}).get('authorizer', {}).get('jwt', {}).get('claims', {})
        user_id = claims.get('sub')
        if user_id:
            print(json.dumps({
                'level': 'INFO',
                'message': 'User ID extracted from JWT authorizer',
                'userId': user_id
            }))
            return user_id
    except Exception as e:
        print(json.dumps({
            'level': 'WARN',
            'message': 'Failed to extract from JWT authorizer context',
            'error': str(e)
        }))
    
    # Fallback to X-User-Id header (testing/local development only)
    headers = event.get('headers', {})
    user_id = headers.get('X-User-Id') or headers.get('x-user-id')
    
    if user_id:
        print(json.dumps({
            'level': 'WARN',
            'message': 'Using X-User-Id header (testing mode)',
            'userId': user_id
        }))
        return user_id
    
    # No user ID found
    print(json.dumps({
        'level': 'ERROR',
        'message': 'User ID not found. Ensure API Gateway JWT authorizer is configured.',
        'requestContext': event.get('requestContext', {}),
        'headers': list(headers.keys())
    }))
    raise ValueError("User ID not found. Authentication required.")

