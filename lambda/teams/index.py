"""
Teams Lambda - Handles team CRUD operations
"""

import os
import sys
import json
from datetime import datetime, timezone
from ulid import ULID

sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'shared'))

from auth import require_auth
from dynamodb import put_item, get_item, get_user_by_cognito_sub, query_by_pk, query_gsi, transact_write, batch_get_items
from responses import success_response, validation_error, not_found_error, forbidden_error, server_error


def handler(event, context):
    """
    Main Lambda handler for teams operations.
    
    Routes based on HTTP method and path parameters from API Gateway.
    """
    try:
        # Debug: Print the event structure to understand JWT location
        import json
        print("Event structure:")
        print(json.dumps(event, default=str))
        
        method = event.get('httpMethod') or event.get('requestContext', {}).get('http', {}).get('method')
        
        # API Gateway V2 uses routeKey (e.g., "GET /teams" or "GET /teams/{teamId}")
        route_key = event.get('routeKey', '')
        
        # Path parameters from API Gateway proxy integration
        path_params = event.get('pathParameters') or {}
        team_id = path_params.get('teamId')
        
        # Require authentication for all operations
        user_info = require_auth(event)
        
        # Get user's full profile from DynamoDB
        user_profile = get_user_by_cognito_sub(user_info['cognitoSub'])
        if not user_profile:
            return forbidden_error('User profile not found')
        
        user_id = user_profile['PK']  # USER#<ULID>
        
        # Route to appropriate handler based on method and presence of teamId
        if method == 'GET' and not team_id:
            # GET /teams - List user's teams
            return list_user_teams(user_id)
        elif method == 'POST' and not team_id:
            # POST /teams - Create team
            return create_team(event, user_id, user_info)
        elif method == 'GET' and team_id:
            # GET /teams/{teamId} - Get team details
            return get_team(team_id, user_id)
        elif method == 'PUT' and team_id:
            # PUT /teams/{teamId} - Update team
            return update_team(event, team_id, user_id)
        elif method == 'DELETE' and team_id:
            # DELETE /teams/{teamId} - Delete team
            return delete_team(team_id, user_id)
        else:
            return validation_error(f'Unsupported operation: {method} {route_key}')
            
    except ValueError as e:
        return validation_error(str(e))
    except Exception as e:
        print(f"Unexpected error: {e}")
        import traceback
        print(traceback.format_exc())
        return server_error()


def list_user_teams(user_id: str) -> dict:
    """
    List all teams the user is a member of.
    
    Uses GSI3 to query all team memberships, then batch fetches team metadata.
    This avoids N+1 query problem by using a single batch get operation.
    
    Returns:
        200 with array of team summaries
    """
    try:
        # Query GSI3 for all teams this user is a member of
        # GSI3PK = USER#<ULID>, GSI3SK = TEAM#<TEAM_ID>
        memberships = query_gsi('GSI3', user_id)
        
        if not memberships:
            return success_response({'teams': [], 'count': 0})
        
        # Batch fetch all team metadata in a single request (avoids N+1 queries)
        team_keys = [{'PK': membership['PK'], 'SK': 'METADATA'} for membership in memberships]
        teams_data = batch_get_items(team_keys)
        
        # Build lookup dict for O(1) access
        teams_by_id = {team['PK']: team for team in teams_data}
        
        # Combine membership data with team metadata
        teams = []
        for membership in memberships:
            team_id = membership['PK']
            team = teams_by_id.get(team_id)
            
            if team:
                teams.append({
                    'teamId': team_id,
                    'name': team['name'],
                    'description': team.get('description', ''),
                    'role': membership['role'],
                    'memberCount': team.get('memberCount', 0),
                    'joinedAt': membership['joinedAt'],
                    'createdAt': team['createdAt'],
                })
        
        # Sort by join date (most recent first)
        teams.sort(key=lambda t: t['joinedAt'], reverse=True)
        
        return success_response({
            'teams': teams,
            'count': len(teams)
        })
        
    except Exception as e:
        print(f"Error listing teams for user {user_id}: {e}")
        import traceback
        print(traceback.format_exc())
        return server_error()


def create_team(event, user_id: str, user_info: dict) -> dict:
    """
    Create a new team.
    
    Request body:
    {
        "name": "Team Name",
        "description": "Optional description"
    }
    
    Returns:
        201 with team object
    """
    try:
        body = json.loads(event.get('body', '{}'))
        
        # Validation with safe type conversion
        team_name = str(body.get('name', '')).strip()
        if not team_name:
            return validation_error('Team name is required')
        
        if len(team_name) > 100:
            return validation_error('Team name must be 100 characters or less')
        
        description = str(body.get('description', '')).strip()
        if len(description) > 500:
            return validation_error('Description must be 500 characters or less')
        
        # Generate team ID
        team_id = f"TEAM#{ULID()}"
        now = datetime.now(timezone.utc).isoformat()
        
        # Create team record
        team_item = {
            'PK': team_id,
            'SK': 'METADATA',
            'name': team_name,
            'description': description,
            'createdBy': user_id,
            'createdAt': now,
            'updatedAt': now,
            'memberCount': 1,  # Creator is first member
        }
        
        # Create owner membership record
        owner_item = {
            'PK': team_id,
            'SK': f'MEMBER#{user_id}',
            'userId': user_id,
            'email': user_info['email'],
            'firstName': user_info.get('givenName', ''),
            'lastName': user_info.get('familyName', ''),
            'role': 'owner',
            'joinedAt': now,
            # GSI3 for user's team list
            'GSI3PK': user_id,
            'GSI3SK': f'TEAM#{team_id}',
        }
        
        # Write both items atomically (team + owner membership)
        # This ensures both succeed or neither do - no orphaned teams
        transact_write([
            {'Put': {'Item': team_item}},
            {'Put': {'Item': owner_item}}
        ])
        
        # Build response
        team_response = {
            'teamId': team_id,
            'name': team_name,
            'description': description,
            'role': 'owner',
            'memberCount': 1,
            'joinedAt': now,  # When user joined (same as creation for owner)
            'createdAt': now,
            'createdBy': user_id,
        }
        
        return success_response(team_response, 201)
        
    except json.JSONDecodeError:
        return validation_error('Invalid JSON in request body')
    except Exception as e:
        print(f"Error creating team: {e}")
        return server_error()


def get_team(team_id: str, user_id: str) -> dict:
    """
    Get team details.
    
    User must be a member of the team.
    """
    try:
        # Get team metadata
        team = get_item(team_id, 'METADATA')
        if not team:
            return not_found_error('Team not found')
        
        # Check if user is a member
        membership = get_item(team_id, f'MEMBER#{user_id}')
        if not membership:
            return forbidden_error('You are not a member of this team')
        
        # Build response
        team_response = {
            'teamId': team['PK'],
            'name': team['name'],
            'description': team.get('description', ''),
            'memberCount': team.get('memberCount', 0),
            'role': membership['role'],
            'createdAt': team['createdAt'],
            'createdBy': team['createdBy'],
        }
        
        return success_response(team_response)
        
    except Exception as e:
        print(f"Error getting team {team_id}: {e}")
        return server_error()


def update_team(event, team_id: str, user_id: str) -> dict:
    """
    Update team details.
    
    Only team owners can update team info.
    """
    try:
        body = json.loads(event.get('body', '{}'))
        
        # Get team metadata
        team = get_item(team_id, 'METADATA')
        if not team:
            return not_found_error('Team not found')
        
        # Check if user is owner
        membership = get_item(team_id, f'MEMBER#{user_id}')
        if not membership or membership['role'] != 'owner':
            return forbidden_error('Only team owners can update team details')
        
        # Validation with safe type conversion
        updates = {}
        
        if 'name' in body:
            name = str(body.get('name', '')).strip()
            if not name:
                return validation_error('Team name cannot be empty')
            if len(name) > 100:
                return validation_error('Team name must be 100 characters or less')
            updates['name'] = name
        
        if 'description' in body:
            description = str(body.get('description', '')).strip()
            if len(description) > 500:
                return validation_error('Description must be 500 characters or less')
            updates['description'] = description
        
        if not updates:
            return validation_error('No valid fields to update')
        
        updates['updatedAt'] = datetime.now(timezone.utc).isoformat()
        
        # Update team
        from dynamodb import update_item
        update_item(team_id, 'METADATA', updates)
        
        # Get updated team and user's membership
        updated_team = get_item(team_id, 'METADATA')
        membership = get_item(team_id, f'MEMBER#{user_id}')
        
        team_response = {
            'teamId': updated_team['PK'],
            'name': updated_team['name'],
            'description': updated_team.get('description', ''),
            'memberCount': updated_team.get('memberCount', 0),
            'role': membership['role'],
            'joinedAt': membership['joinedAt'],
            'createdAt': updated_team['createdAt'],
            'updatedAt': updated_team['updatedAt'],
        }
        
        return success_response(team_response)
        
    except json.JSONDecodeError:
        return validation_error('Invalid JSON in request body')
    except Exception as e:
        print(f"Error updating team {team_id}: {e}")
        return server_error()


def delete_team(team_id: str, user_id: str) -> dict:
    """
    Delete a team.
    
    Only team owners can delete teams.
    This is a soft delete for now - just removes the user as owner.
    Full deletion would require cleaning up all related records.
    """
    try:
        # Get team metadata
        team = get_item(team_id, 'METADATA')
        if not team:
            return not_found_error('Team not found')
        
        # Check if user is owner
        membership = get_item(team_id, f'MEMBER#{user_id}')
        if not membership or membership['role'] != 'owner':
            return forbidden_error('Only team owners can delete teams')
        
        # TODO: Implement full deletion logic
        # For now, return not implemented
        return validation_error('Team deletion not yet implemented - contact support')
        
    except Exception as e:
        print(f"Error deleting team {team_id}: {e}")
        return server_error()

