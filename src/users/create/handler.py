"""
Create User Lambda Handler

Cognito Post-Confirmation Trigger
Creates a user record in DynamoDB after successful Cognito sign-up
Also creates a personal stats team for the user
"""

import json
import os
import sys
from pathlib import Path
from datetime import datetime, timezone

import boto3
from boto3.dynamodb.conditions import Attr
from botocore.exceptions import ClientError


# Initialize DynamoDB client
def get_dynamodb_client():
    """Get DynamoDB resource (works locally and in AWS)"""
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
    """Get DynamoDB table reference"""
    dynamodb = get_dynamodb_client()
    table_name = os.environ.get('TABLE_NAME', 'HackTracker-dev')
    return dynamodb.Table(table_name)


def handler(event, context):
    """
    Lambda handler for Cognito post-confirmation trigger
    
    Args:
        event: Cognito post-confirmation event
        context: Lambda context
        
    Returns:
        The original event (required for Cognito triggers)
    """
    print(json.dumps({
        'level': 'INFO',
        'message': 'Processing Cognito post-confirmation event',
        'triggerSource': event.get('triggerSource'),
        'userPoolId': event.get('userPoolId'),
        'userName': event.get('userName')
    }))
    
    try:
        # Extract user attributes from Cognito event
        user_attributes = event['request']['userAttributes']
        sub = user_attributes['sub']
        email = user_attributes['email']
        given_name = user_attributes.get('given_name', '')
        family_name = user_attributes.get('family_name', '')
        phone_number = user_attributes.get('phone_number')
        
        # Validate required fields
        if not sub or not email:
            raise ValueError('Missing required user attributes: sub and email')
        
        # If names not provided, use email prefix as fallback
        if not given_name:
            given_name = email.split('@')[0]
        if not family_name:
            family_name = 'User'
        
        # Use Cognito sub as userId (globally unique, no need for separate ID)
        user_id = sub
        timestamp = datetime.now(timezone.utc).isoformat()
        
        # Create user item for DynamoDB (ordered for readability)
        user_item = {
            # Primary Keys
            'PK': f'USER#{user_id}',
            'SK': 'METADATA',
            
            # User Data
            'userId': user_id,
            'email': email.lower(),
            'firstName': given_name,
            'lastName': family_name,
            
            # GSI1: Lookup by Cognito sub
            'GSI1PK': f'COGNITO#{sub}',
            'GSI1SK': 'USER',
            
            # GSI2: Entity listing (list all users)
            'GSI2PK': 'ENTITY#USER',
            'GSI2SK': f'METADATA#{user_id}',
            
            # Timestamps
            'createdAt': timestamp,
            'updatedAt': timestamp
        }
        
        # Add optional phone number
        if phone_number:
            user_item['phoneNumber'] = phone_number
        
        # Save to DynamoDB
        table = get_table()
        
        try:
            table.put_item(
                Item=user_item,
                ConditionExpression=Attr('PK').not_exists()  # Prevent overwriting
            )
            
            print(json.dumps({
                'level': 'INFO',
                'message': 'User created successfully',
                'userId': user_id,  # userId is now the same as Cognito sub
                'email': email.lower()
            }))
            
            # Note: Personal teams are now created by users when needed via POST /teams with team_type=PERSONAL
        except ClientError as e:
            # If user already exists (e.g., Cognito retry or duplicate trigger)
            if e.response['Error']['Code'] == 'ConditionalCheckFailedException':
                print(json.dumps({
                    'level': 'WARN',
                    'message': 'User already exists (likely a retry)',
                    'userId': user_id,
                    'email': email.lower()
                }))
                # Not an error - just return the event
            else:
                # Re-raise other DynamoDB errors
                raise
        
        # Return the event (required for Cognito triggers)
        return event
        
    except Exception as error:
        print(json.dumps({
            'level': 'ERROR',
            'message': 'Failed to create user',
            'error': str(error),
            'userName': event.get('userName'),
            'userPoolId': event.get('userPoolId')
        }))
        
        # For Cognito triggers, we should still return the event
        # The user account is already created in Cognito at this point
        # We log the error but don't fail the sign-up process
        return event

