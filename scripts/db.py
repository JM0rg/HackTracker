"""
Database Management Script

Unified script for managing local DynamoDB
Usage: uv run db <command>
"""

import re
import subprocess
import sys
import time
from pathlib import Path

import boto3
from botocore.exceptions import ClientError

# Configuration
ROOT_DIR = Path(__file__).parent.parent
TABLE_NAME = 'HackTracker-dev'
DOCKER_COMPOSE_FILE = ROOT_DIR / 'local' / 'docker-compose.yml'
TERRAFORM_FILE = ROOT_DIR / 'terraform' / 'dynamodb.tf'

# DynamoDB client for local
client = boto3.client(
    'dynamodb',
    endpoint_url='http://localhost:8000',
    region_name='us-east-1',
    aws_access_key_id='dummy',
    aws_secret_access_key='dummy'
)


def is_running():
    """Check if DynamoDB Local is running"""
    try:
        client.list_tables()
        return True
    except Exception:
        return False


def table_exists():
    """Check if table exists"""
    try:
        client.describe_table(TableName=TABLE_NAME)
        return True
    except ClientError:
        return False


def parse_terraform_config():
    """Parse Terraform HCL to extract DynamoDB table configuration"""
    content = TERRAFORM_FILE.read_text()
    
    config = {
        'tableName': TABLE_NAME,
        'hashKey': None,
        'rangeKey': None,
        'attributes': [],
        'gsis': []
    }
    
    # Extract hash_key
    hash_match = re.search(r'hash_key\s*=\s*"([^"]+)"', content)
    if hash_match:
        config['hashKey'] = hash_match.group(1)
    
    # Extract range_key
    range_match = re.search(r'range_key\s*=\s*"([^"]+)"', content)
    if range_match:
        config['rangeKey'] = range_match.group(1)
    
    # Extract attributes
    for match in re.finditer(r'attribute\s*\{[^}]*name\s*=\s*"([^"]+)"[^}]*type\s*=\s*"([^"]+)"[^}]*\}', content):
        config['attributes'].append({
            'name': match.group(1),
            'type': match.group(2)
        })
    
    # Extract GSIs
    for match in re.finditer(r'global_secondary_index\s*\{([^}]+(?:\{[^}]*\}[^}]*)*)\}', content):
        gsi_block = match.group(1)
        
        name_match = re.search(r'name\s*=\s*"([^"]+)"', gsi_block)
        hash_key_match = re.search(r'hash_key\s*=\s*"([^"]+)"', gsi_block)
        range_key_match = re.search(r'range_key\s*=\s*"([^"]+)"', gsi_block)
        
        if name_match and hash_key_match:
            config['gsis'].append({
                'name': name_match.group(1),
                'hashKey': hash_key_match.group(1),
                'rangeKey': range_key_match.group(1) if range_key_match else None
            })
    
    return config


def cmd_start():
    """Start DynamoDB Local containers"""
    print('🚀 Starting DynamoDB Local...\n')
    
    if is_running():
        print('✅ DynamoDB Local is already running')
        print('🌐 DynamoDB Local: http://localhost:8000')
        print('🎨 Admin UI: http://localhost:8001')
        return
    
    try:
        result = subprocess.run(
            ['docker-compose', '-f', str(DOCKER_COMPOSE_FILE), 'up', '-d'],
            capture_output=True,
            text=True
        )
        
        if result.stdout:
            print(result.stdout.strip())
        
        # Wait for services to be ready
        print('\n⏳ Waiting for services to start...')
        time.sleep(3)
        
        print('\n✅ DynamoDB Local started successfully!')
        print('🌐 DynamoDB Local: http://localhost:8000')
        print('🎨 Admin UI: http://localhost:8001')
    except Exception as e:
        print(f'❌ Failed to start DynamoDB Local: {e}')
        sys.exit(1)


def cmd_stop():
    """Stop DynamoDB Local containers"""
    print('🛑 Stopping DynamoDB Local...\n')
    
    try:
        result = subprocess.run(
            ['docker-compose', '-f', str(DOCKER_COMPOSE_FILE), 'down'],
            capture_output=True,
            text=True
        )
        
        if result.stdout:
            print(result.stdout.strip())
        
        print('\n✅ DynamoDB Local stopped successfully!')
    except Exception as e:
        print(f'❌ Failed to stop DynamoDB Local: {e}')
        sys.exit(1)


def cmd_delete():
    """Delete the DynamoDB table"""
    print('🗑️  Deleting table...\n')
    
    if not is_running():
        print('❌ DynamoDB Local is not running!')
        print('   Start it with: uv run db start\n')
        sys.exit(1)
    
    if not table_exists():
        print('⚠️  Table does not exist')
        return
    
    try:
        client.delete_table(TableName=TABLE_NAME)
        print(f'✅ Table "{TABLE_NAME}" deleted successfully')
        time.sleep(2)
    except Exception as e:
        print(f'❌ Failed to delete table: {e}')
        sys.exit(1)


def cmd_create():
    """Create the DynamoDB table from Terraform schema"""
    print('📦 Creating table from Terraform schema...\n')
    
    if not is_running():
        print('❌ DynamoDB Local is not running!')
        print('   Start it with: uv run db start\n')
        sys.exit(1)
    
    if table_exists():
        print('❌ Table already exists!')
        print('   Delete it first with: uv run db delete\n')
        sys.exit(1)
    
    # Parse Terraform config
    config = parse_terraform_config()
    
    print('📋 Parsed schema from terraform/dynamodb.tf:')
    print(f'   Table: {config["tableName"]}')
    print(f'   Keys: {config["hashKey"]}' + (f', {config["rangeKey"]}' if config["rangeKey"] else ''))
    print(f'   Attributes: {len(config["attributes"])}')
    print(f'   GSIs: {len(config["gsis"])}')
    print('')
    
    # Build key schema
    key_schema = [{'AttributeName': config['hashKey'], 'KeyType': 'HASH'}]
    if config['rangeKey']:
        key_schema.append({'AttributeName': config['rangeKey'], 'KeyType': 'RANGE'})
    
    # Build attribute definitions
    attribute_definitions = [
        {'AttributeName': attr['name'], 'AttributeType': attr['type']}
        for attr in config['attributes']
    ]
    
    # Build GSI definitions
    global_secondary_indexes = []
    for gsi in config['gsis']:
        gsi_key_schema = [{'AttributeName': gsi['hashKey'], 'KeyType': 'HASH'}]
        if gsi['rangeKey']:
            gsi_key_schema.append({'AttributeName': gsi['rangeKey'], 'KeyType': 'RANGE'})
        
        global_secondary_indexes.append({
            'IndexName': gsi['name'],
            'KeySchema': gsi_key_schema,
            'Projection': {'ProjectionType': 'ALL'}
        })
    
    # Create table
    try:
        client.create_table(
            TableName=TABLE_NAME,
            BillingMode='PAY_PER_REQUEST',
            KeySchema=key_schema,
            AttributeDefinitions=attribute_definitions,
            GlobalSecondaryIndexes=global_secondary_indexes
        )
        
        print('✅ Table created successfully!')
        print(f'\n📊 Table Details:')
        print(f'   Name: {TABLE_NAME}')
        print(f'   Primary Key: {config["hashKey"]} (HASH)' + 
              (f', {config["rangeKey"]} (RANGE)' if config["rangeKey"] else ''))
        for i, gsi in enumerate(config['gsis'], 1):
            print(f'   GSI{i}: {gsi["name"]}')
    except Exception as e:
        print(f'❌ Failed to create table: {e}')
        sys.exit(1)


def cmd_clear():
    """Remove all data from the table"""
    print('🧹 Clearing all data from table...\n')
    
    if not is_running():
        print('❌ DynamoDB Local is not running!')
        print('   Start it with: uv run db start\n')
        sys.exit(1)
    
    if not table_exists():
        print('❌ Table does not exist!')
        print('   Create it with: uv run db create\n')
        sys.exit(1)
    
    try:
        # Scan all items
        print('📊 Scanning table...')
        response = client.scan(TableName=TABLE_NAME)
        items = response.get('Items', [])
        
        if not items:
            print('✅ Table is already empty')
            return
        
        print(f'   Found {len(items)} items')
        print('🗑️  Deleting items...')
        
        # Delete items in batches of 25
        batch_size = 25
        for i in range(0, len(items), batch_size):
            batch = items[i:i + batch_size]
            
            delete_requests = [
                {'DeleteRequest': {'Key': {'PK': item['PK'], 'SK': item['SK']}}}
                for item in batch
            ]
            
            client.batch_write_item(
                RequestItems={TABLE_NAME: delete_requests}
            )
            
            print(f'   Deleted {min(i + batch_size, len(items))}/{len(items)} items')
        
        print('\n✅ All data cleared successfully!')
    except Exception as e:
        print(f'❌ Failed to clear data: {e}')
        sys.exit(1)


def cmd_reset():
    """Delete and recreate the table"""
    print('🔄 Resetting table...\n')
    
    if table_exists():
        cmd_delete()
        print('')
    
    cmd_create()


def cmd_status():
    """Show status of DynamoDB Local and table"""
    print('📊 DynamoDB Local Status\n')
    
    running = is_running()
    print(f'DynamoDB Local: {"✅ Running" if running else "❌ Not running"}')
    
    if running:
        print('  🌐 Endpoint: http://localhost:8000')
        print('  🎨 Admin UI: http://localhost:8001')
        
        exists = table_exists()
        print(f'\nTable "{TABLE_NAME}": {"✅ Exists" if exists else "❌ Does not exist"}')
        
        if exists:
            try:
                response = client.scan(
                    TableName=TABLE_NAME,
                    Select='COUNT'
                )
                print(f'  📊 Item count: {response.get("Count", 0)}')
            except Exception:
                print('  ⚠️  Could not get item count')


def show_usage():
    """Show usage information"""
    print("""
🗄️  Database Management Script

Usage: uv run db <command>

Commands:
  uv run db start    Start DynamoDB Local containers
  uv run db stop     Stop DynamoDB Local containers
  uv run db create   Create table from Terraform schema
  uv run db delete   Delete the table
  uv run db clear    Remove all data from table (keeps schema)
  uv run db reset    Delete and recreate table
  uv run db status   Show status of DynamoDB Local and table

Examples:
  uv run db start          # Start DynamoDB Local
  uv run db create         # Create table
  uv run db clear          # Clear all data
  uv run db reset          # Delete and recreate table
  uv run db status         # Check status
  uv run db stop           # Stop DynamoDB Local

Workflow:
  1. uv run db start           # Start containers
  2. uv run db create          # Create table
  3. uv run test-create-user   # Test your Lambda
  4. uv run db clear           # Clear test data
  5. uv run db stop            # Stop when done
""")


def main():
    """Main function"""
    if len(sys.argv) < 2:
        show_usage()
        sys.exit(0)
    
    command = sys.argv[1]
    
    commands = {
        'start': cmd_start,
        'stop': cmd_stop,
        'create': cmd_create,
        'delete': cmd_delete,
        'clear': cmd_clear,
        'reset': cmd_reset,
        'status': cmd_status
    }
    
    if command in commands:
        try:
            commands[command]()
        except KeyboardInterrupt:
            print('\n\n⚠️  Interrupted by user')
            sys.exit(1)
    else:
        print(f'❌ Unknown command: {command}\n')
        show_usage()
        sys.exit(1)


if __name__ == '__main__':
    main()
