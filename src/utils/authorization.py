"""
Authorization utilities for HackTracker

Provides role-based access control for team operations
"""

import json


class PermissionError(Exception):
    """Custom exception for permission-related errors"""
    pass


# Permission constants for common operations
MANAGE_ROSTER_ROLES = ['team-owner', 'team-coach']
MANAGE_TEAM_ROLES = ['team-owner', 'team-coach']
DELETE_TEAM_ROLES = ['team-owner']

# Central policy map: action → required roles
POLICY_MAP = {
    'manage_roster': MANAGE_ROSTER_ROLES,
    'manage_team': MANAGE_TEAM_ROLES,
    'delete_team': DELETE_TEAM_ROLES,
}


def authorize(table, user_id, team_id, action):
    """
    Check if user can perform a specific action on a team (v2 Policy Engine)
    
    This is the primary authorization function. Handlers should use this
    instead of directly calling check_team_role().
    
    Args:
        table: DynamoDB table resource
        user_id (str): User ID to check
        team_id (str): Team ID to check
        action (str): Action to authorize (e.g., 'manage_roster', 'manage_team', 'delete_team')
        
    Returns:
        dict: Membership record if authorized
        
    Raises:
        PermissionError: If user is not authorized or action is invalid
        
    Example:
        >>> authorize(table, user_id, team_id, action='manage_roster')
    """
    # Get required roles from central policy map
    required_roles = POLICY_MAP.get(action)
    if not required_roles:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'Invalid action requested',
            'action': action,
            'validActions': list(POLICY_MAP.keys())
        }))
        raise PermissionError(f"Invalid action: {action}")
    
    # Use existing role check logic
    return _check_team_role(table, user_id, team_id, required_roles)


def _check_team_role(table, user_id, team_id, required_roles):
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


def check_team_role(table, user_id, team_id, required_roles):
    """
    Check if user has required role on team (backward compatibility wrapper)
    
    Note: Prefer using authorize(table, user_id, team_id, action='...')
    for better maintainability.
    
    Args:
        table: DynamoDB table resource
        user_id (str): User ID to check
        team_id (str): Team ID to check
        required_roles (list): List of acceptable roles
        
    Returns:
        dict: Membership record if authorized
        
    Raises:
        PermissionError: If user is not authorized
    """
    return _check_team_role(table, user_id, team_id, required_roles)


def check_team_membership(table, user_id, team_id):
    """
    Check if user is an active member of the team (any role)
    
    More future-proof than role-based checks for simple read operations.
    Use this for "view" operations where any team member should have access.
    
    Args:
        table: DynamoDB table resource
        user_id (str): User ID to check
        team_id (str): Team ID to check
        
    Returns:
        dict: Membership record if user is an active member
        
    Raises:
        PermissionError: If user is not an active member
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
    
    print(json.dumps({
        'level': 'INFO',
        'message': 'Team membership verified',
        'userId': user_id,
        'teamId': team_id,
        'role': membership.get('role')
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


def check_personal_team_operation(table, team_id, operation):
    """
    Block certain operations on personal stats teams
    
    Personal teams are invisible containers for at-bats not linked to real teams.
    Users should not be able to manage them like regular teams.
    
    Allowed operations: create games, record at-bats
    Blocked operations: add players, delete team, manage roster, create seasons
    
    Args:
        table: DynamoDB table resource
        team_id (str): Team ID to check
        operation (str): Operation to validate (e.g., 'manage_roster', 'delete_team')
    
    Returns:
        None if operation is allowed
    
    Raises:
        PermissionError: If operation is not allowed on personal team
    """
    # Get team record
    response = table.get_item(
        Key={
            'PK': f'TEAM#{team_id}',
            'SK': 'METADATA'
        }
    )
    
    if 'Item' not in response:
        print(json.dumps({
            'level': 'WARN',
            'message': 'Team not found for personal team check',
            'teamId': team_id
        }))
        raise PermissionError("Team not found")
    
    team = response['Item']
    
    # If not a personal team, allow all operations
    if not team.get('isPersonal', False):
        return
    
    # Define blocked operations for personal teams
    blocked_operations = [
        'manage_roster',  # Can't add/remove players
        'delete_team',    # Can't delete personal team
        'manage_team'     # Can't rename/edit team
    ]
    
    if operation in blocked_operations:
        print(json.dumps({
            'level': 'WARN',
            'message': 'Operation not allowed on personal stats team',
            'teamId': team_id,
            'operation': operation
        }))
        raise PermissionError(f"Cannot {operation.replace('_', ' ')} on personal stats team")

