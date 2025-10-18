"""
DynamoDB helper functions for HackTracker.

Provides utilities for common DynamoDB operations with error handling.
"""

import os
import boto3
from typing import Dict, Any, List, Optional
from botocore.exceptions import ClientError

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('DYNAMODB_TABLE')

if not table_name:
    raise ValueError("DYNAMODB_TABLE environment variable is required")

table = dynamodb.Table(table_name)


def get_item(pk: str, sk: str) -> Optional[Dict[str, Any]]:
    """
    Get a single item from DynamoDB.
    
    Args:
        pk: Partition key
        sk: Sort key
        
    Returns:
        Item dict if found, None otherwise
    """
    try:
        response = table.get_item(Key={'PK': pk, 'SK': sk})
        return response.get('Item')
    except ClientError as e:
        print(f"Error getting item {pk}#{sk}: {e}")
        raise


def put_item(item: Dict[str, Any], condition_expression: Optional[str] = None) -> None:
    """
    Put an item into DynamoDB.
    
    Args:
        item: Item to store
        condition_expression: Optional condition expression for atomic writes
        
    Raises:
        ClientError: If condition fails or other DynamoDB error
    """
    try:
        kwargs = {'Item': item}
        if condition_expression:
            kwargs['ConditionExpression'] = condition_expression
            
        table.put_item(**kwargs)
    except ClientError as e:
        print(f"Error putting item: {e}")
        raise


def query_by_pk(pk: str, sk_prefix: Optional[str] = None, limit: Optional[int] = None) -> List[Dict[str, Any]]:
    """
    Query items by partition key, optionally filtering by sort key prefix.
    
    Args:
        pk: Partition key
        sk_prefix: Optional sort key prefix (e.g., 'MEMBER#')
        limit: Optional limit on number of items
        
    Returns:
        List of items
    """
    try:
        kwargs = {
            'KeyConditionExpression': boto3.dynamodb.conditions.Key('PK').eq(pk)
        }
        
        if sk_prefix:
            kwargs['KeyConditionExpression'] &= boto3.dynamodb.conditions.Key('SK').begins_with(sk_prefix)
        
        if limit:
            kwargs['Limit'] = limit
            
        response = table.query(**kwargs)
        return response.get('Items', [])
    except ClientError as e:
        print(f"Error querying items with PK {pk}: {e}")
        raise


def query_gsi(index_name: str, pk_value: str, sk_value: Optional[str] = None) -> List[Dict[str, Any]]:
    """
    Query a Global Secondary Index.
    
    Args:
        index_name: GSI name (e.g., 'GSI1', 'GSI2')
        pk_value: GSI partition key value
        sk_value: Optional GSI sort key value
        
    Returns:
        List of items
    """
    try:
        pk_attr = f'{index_name}PK'
        sk_attr = f'{index_name}SK'
        
        kwargs = {
            'IndexName': index_name,
            'KeyConditionExpression': boto3.dynamodb.conditions.Key(pk_attr).eq(pk_value)
        }
        
        if sk_value:
            kwargs['KeyConditionExpression'] &= boto3.dynamodb.conditions.Key(sk_attr).eq(sk_value)
            
        response = table.query(**kwargs)
        return response.get('Items', [])
    except ClientError as e:
        print(f"Error querying GSI {index_name}: {e}")
        raise


def get_user_by_cognito_sub(cognito_sub: str) -> Optional[Dict[str, Any]]:
    """
    Get user profile by Cognito sub using GSI1.
    
    Args:
        cognito_sub: Cognito user sub
        
    Returns:
        User profile dict if found, None otherwise
    """
    items = query_gsi('GSI1', f'COGNITO#{cognito_sub}', 'PROFILE')
    return items[0] if items else None


def update_item(pk: str, sk: str, updates: Dict[str, Any]) -> None:
    """
    Update specific attributes of an item.
    
    Args:
        pk: Partition key
        sk: Sort key
        updates: Dict of attributes to update
    """
    try:
        update_expression_parts = []
        expression_attribute_names = {}
        expression_attribute_values = {}
        
        for i, (key, value) in enumerate(updates.items()):
            attr_name = f'#attr{i}'
            attr_value = f':val{i}'
            update_expression_parts.append(f'{attr_name} = {attr_value}')
            expression_attribute_names[attr_name] = key
            expression_attribute_values[attr_value] = value
        
        table.update_item(
            Key={'PK': pk, 'SK': sk},
            UpdateExpression='SET ' + ', '.join(update_expression_parts),
            ExpressionAttributeNames=expression_attribute_names,
            ExpressionAttributeValues=expression_attribute_values
        )
    except ClientError as e:
        print(f"Error updating item {pk}#{sk}: {e}")
        raise


def delete_item(pk: str, sk: str) -> None:
    """
    Delete an item from DynamoDB.
    
    Args:
        pk: Partition key
        sk: Sort key
    """
    try:
        table.delete_item(Key={'PK': pk, 'SK': sk})
    except ClientError as e:
        print(f"Error deleting item {pk}#{sk}: {e}")
        raise


def batch_get_items(keys: List[Dict[str, str]]) -> List[Dict[str, Any]]:
    """
    Batch get multiple items from DynamoDB in a single request.
    
    Args:
        keys: List of key dicts, e.g. [{'PK': 'TEAM#123', 'SK': 'METADATA'}, ...]
        
    Returns:
        List of items (order not guaranteed)
        
    Example:
        keys = [
            {'PK': 'TEAM#123', 'SK': 'METADATA'},
            {'PK': 'TEAM#456', 'SK': 'METADATA'}
        ]
        teams = batch_get_items(keys)
    """
    if not keys:
        return []
    
    try:
        # Use low-level client for batch operations
        client = dynamodb.meta.client
        
        # BatchGetItem has a limit of 100 items per request
        # Split into chunks if needed
        results = []
        chunk_size = 100
        
        for i in range(0, len(keys), chunk_size):
            chunk = keys[i:i + chunk_size]
            
            response = client.batch_get_item(
                RequestItems={
                    table_name: {
                        'Keys': chunk
                    }
                }
            )
            
            # Add retrieved items to results
            items = response.get('Responses', {}).get(table_name, [])
            results.extend(items)
            
            # Handle unprocessed keys (throttling, etc.)
            unprocessed = response.get('UnprocessedKeys', {})
            while unprocessed:
                print(f"Retrying {len(unprocessed.get(table_name, {}).get('Keys', []))} unprocessed keys")
                response = client.batch_get_item(RequestItems=unprocessed)
                items = response.get('Responses', {}).get(table_name, [])
                results.extend(items)
                unprocessed = response.get('UnprocessedKeys', {})
        
        return results
        
    except ClientError as e:
        print(f"Error batch getting items: {e}")
        raise


def transact_write(items: List[Dict[str, Any]]) -> None:
    """
    Execute a transactional write with multiple items.
    All operations succeed or all fail atomically.
    
    Args:
        items: List of items to write, each with 'Put', 'Update', 'Delete', or 'ConditionCheck'
        
    Example:
        transact_write([
            {
                'Put': {
                    'TableName': table_name,
                    'Item': {'PK': 'TEAM#123', 'SK': 'METADATA', 'name': 'Team'}
                }
            },
            {
                'Put': {
                    'TableName': table_name,
                    'Item': {'PK': 'TEAM#123', 'SK': 'MEMBER#USER#456', 'role': 'owner'}
                }
            }
        ])
        
    Raises:
        ClientError: If transaction fails (including conditional check failures)
    """
    try:
        # Use the low-level client for transactions
        client = table.meta.client
        
        # Ensure all items have TableName set
        for item in items:
            for operation in ['Put', 'Update', 'Delete', 'ConditionCheck']:
                if operation in item and 'TableName' not in item[operation]:
                    item[operation]['TableName'] = table_name
        
        client.transact_write_items(TransactItems=items)
        
    except ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == 'TransactionCanceledException':
            # Get cancellation reasons
            reasons = e.response.get('CancellationReasons', [])
            print(f"Transaction cancelled. Reasons: {reasons}")
        else:
            print(f"Transaction failed: {e}")
        raise

