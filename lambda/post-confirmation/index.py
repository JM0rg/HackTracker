"""
Cognito PostConfirmation Trigger Handler

Automatically invoked by Cognito after a user successfully confirms their account.
Creates a user profile record in DynamoDB with a unique ULID-based identifier.
"""

import os
import sys
from datetime import datetime, timezone
from ulid import ULID

# Add shared utilities to path
# In Lambda zip: index.py and shared/ are at same level
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'shared'))

from dynamodb import put_item
from logging_utils import log_event, log_error


def handler(event, context):
    """
    PostConfirmation Lambda Handler
    
    Args:
        event: Cognito PostConfirmation trigger event
        context: Lambda context
        
    Returns:
        The original event (required by Cognito)
    """
    user_attributes = event['request']['userAttributes']
    cognito_sub = user_attributes['sub']
    email = str(user_attributes.get('email', '')).strip()
    first_name = str(user_attributes.get('given_name', '')).strip()[:100]
    last_name = str(user_attributes.get('family_name', '')).strip()[:100]
    
    log_event('post_confirmation_triggered', cognito_sub=cognito_sub, email=email)
    
    now = datetime.now(timezone.utc).isoformat()
    
    try:
        user_id = create_user_profile(cognito_sub, email, first_name, last_name, now)
        log_event('user_profile_created', user_id=user_id, cognito_sub=cognito_sub)
        
    except Exception as e:
        error_code = e.response.get('Error', {}).get('Code', '') if hasattr(e, 'response') else ''
        
        if error_code == 'ConditionalCheckFailedException':
            log_event('user_profile_already_exists', cognito_sub=cognito_sub)
        else:
            log_error(
                'UserProfileCreationFailed',
                str(e),
                cognito_sub=cognito_sub,
                email=email
            )
            # Allow signup to proceed - profile will be created on first API call
    
    return event


def create_user_profile(cognito_sub: str, email: str, first_name: str, last_name: str, timestamp: str) -> str:
    """
    Create a new user profile in DynamoDB with atomic idempotency check
    
    Args:
        cognito_sub: Cognito user sub
        email: User's email address
        first_name: User's first name
        last_name: User's last name
        timestamp: ISO timestamp for record creation
        
    Returns:
        The generated user ID
        
    Raises:
        ConditionalCheckFailedException: If user already exists (idempotent)
    """
    user_id = f"USER#{ULID()}"
    email_lower = email.lower()
    
    item = {
        'PK': user_id,
        'SK': 'PROFILE',
        'cognitoSub': cognito_sub,
        'email': email,
        'firstName': first_name,
        'lastName': last_name,
        'createdAt': timestamp,
        'updatedAt': timestamp,
        'GSI1PK': f"COGNITO#{cognito_sub}",
        'GSI1SK': 'PROFILE',
        'GSI2PK': f"EMAIL#{email_lower}",
        'GSI2SK': 'PROFILE'
    }
    
    # Use shared utility with condition expression for idempotency
    put_item(item, condition_expression='attribute_not_exists(GSI1PK) AND attribute_not_exists(GSI2PK)')
    
    return user_id

