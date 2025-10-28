#!/usr/bin/env python3
"""
Test User Lambda Functions

Unified test script for all user-related Lambda functions
Usage:
    python scripts/test_users.py create [--cloud]
    python scripts/test_users.py get <userId> [--cloud]
    python scripts/test_users.py query [list|email|cognitoSub|teamId] [value] [--cloud]
    
Options:
    --cloud     Test against deployed API Gateway (instead of local Lambda)
"""

import json
import os
import sys
from pathlib import Path

# Check if testing against cloud
IS_CLOUD = '--cloud' in sys.argv
if IS_CLOUD:
    sys.argv.remove('--cloud')  # Remove flag from args

# Set environment variables for local testing (only if not cloud)
if not IS_CLOUD:
    os.environ['DYNAMODB_LOCAL'] = 'true'
    os.environ['DYNAMODB_ENDPOINT'] = 'http://localhost:8000'
    os.environ['TABLE_NAME'] = 'HackTracker-dev'
    os.environ['ENVIRONMENT'] = 'dev'


def get_api_gateway_url():
    """Get API Gateway URL from Terraform outputs"""
    import subprocess
    
    try:
        result = subprocess.run(
            ['terraform', 'output', '-raw', 'api_gateway_endpoint'],
            cwd=Path(__file__).parent.parent / 'terraform',
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f'❌ Failed to get API Gateway URL from Terraform')
        print(f'   Make sure you have deployed with: make deploy')
        print(f'   Error: {e.stderr}')
        sys.exit(1)


def make_http_request(method, path, query_params=None):
    """Make HTTP request to API Gateway"""
    import urllib.request
    import urllib.parse
    
    api_url = get_api_gateway_url()
    
    # Build full URL
    url = f'{api_url}{path}'
    if query_params:
        url += '?' + urllib.parse.urlencode(query_params)
    
    print(f'🌐 Making request to: {url}')
    
    try:
        req = urllib.request.Request(url, method=method)
        req.add_header('Content-Type', 'application/json')
        
        with urllib.request.urlopen(req, timeout=30) as response:
            status_code = response.status
            body = json.loads(response.read().decode('utf-8'))
            return status_code, body
    
    except urllib.error.HTTPError as e:
        status_code = e.code
        try:
            body = json.loads(e.read().decode('utf-8'))
        except:
            body = {'error': str(e)}
        return status_code, body
    
    except Exception as e:
        print(f'❌ HTTP request failed: {e}')
        sys.exit(1)


def test_create_user():
    """Test create-user Lambda (Cognito trigger)"""
    print('🧪 Testing: create-user Lambda (Cognito trigger)')
    print('='*60)
    
    # Add Lambda to path
    sys.path.insert(0, str(Path(__file__).parent.parent / 'src' / 'users' / 'create'))
    from handler import handler
    
    # Create mock Cognito post-confirmation event
    event = {
        'version': '1',
        'region': 'us-east-1',
        'userPoolId': 'us-east-1_TEST123',
        'userName': 'test-user',
        'triggerSource': 'PostConfirmation_ConfirmSignUp',
        'request': {
            'userAttributes': {
                'sub': '12345678-1234-1234-1234-123456789012',
                'email': 'test@example.com',
                'given_name': 'John',
                'family_name': 'Doe',
                'phone_number': '+15555551234'
            }
        },
        'response': {}
    }
    
    class MockContext:
        function_name = 'test-create-user'
        aws_request_id = 'test-request-id'
        
        @staticmethod
        def get_remaining_time_in_millis():
            return 30000
    
    print('\n📋 Event:')
    print(json.dumps(event, indent=2))
    print('\n' + '='*60 + '\n')
    
    result = handler(event, MockContext())
    
    print('\n' + '='*60)
    print('✅ Lambda execution completed successfully!')
    print('\n📤 Response:')
    print(json.dumps(result, indent=2))
    
    # Verify user was created
    print('\n' + '='*60)
    print('🔍 Verifying User Creation...')
    print('='*60)
    
    import boto3
    dynamodb = boto3.resource(
        'dynamodb',
        endpoint_url=os.environ.get('DYNAMODB_ENDPOINT', 'http://localhost:8000'),
        region_name='us-east-1',
        aws_access_key_id='dummy',
        aws_secret_access_key='dummy'
    )
    table = dynamodb.Table('HackTracker-dev')
    user_id = event['request']['userAttributes']['sub']
    
    # Get user record
    user_response = table.get_item(
        Key={'PK': f'USER#{user_id}', 'SK': 'METADATA'}
    )
    
    if 'Item' in user_response:
        user = user_response['Item']
        print(f'✅ User record found: {user.get("firstName")} {user.get("lastName")}')
        print(f'   Email: {user.get("email")}')
        print(f'   Note: Personal teams are no longer auto-created.')
        print(f'   Users can create PERSONAL teams via POST /teams with teamType=PERSONAL')
    else:
        print(f'⚠️  User record not found in database')
    
    print('\n💡 Check DynamoDB Admin UI: http://localhost:8001')
    print('   Look for the new user in the HackTracker-dev table')


def test_get_user(user_id):
    """Test get-user Lambda (API Gateway)"""
    if not user_id:
        print('❌ Error: userId is required')
        print('Usage: python scripts/test_users.py get <userId> [--cloud]')
        sys.exit(1)
    
    mode = '☁️  CLOUD' if IS_CLOUD else '💻 LOCAL'
    print(f'🧪 Testing [{mode}]: GET /users/{user_id}')
    print('='*60)
    
    if IS_CLOUD:
        # Test against deployed API Gateway
        status_code, body = make_http_request('GET', f'/users/{user_id}')
        
        print(f'\n📤 Response (Status {status_code}):')
        print(json.dumps(body, indent=2))
        
        if status_code == 200:
            print('\n✅ User retrieved successfully from cloud!')
        elif status_code == 404:
            print('\n⚠️  User not found in cloud')
        else:
            print(f'\n❌ Error: {body.get("error", "Unknown error")}')
        
        return
    
    # Test local Lambda
    # Add Lambda to path
    sys.path.insert(0, str(Path(__file__).parent.parent / 'src' / 'users' / 'get'))
    from handler import handler
    
    # Create API Gateway event (format version 2.0)
    event = {
        'version': '2.0',
        'routeKey': f'GET /users/{user_id}',
        'rawPath': f'/users/{user_id}',
        'rawQueryString': '',
        'headers': {
            'accept': 'application/json',
            'content-type': 'application/json'
        },
        'requestContext': {
            'accountId': '123456789012',
            'apiId': 'test-api',
            'domainName': 'test.execute-api.us-east-1.amazonaws.com',
            'domainPrefix': 'test',
            'http': {
                'method': 'GET',
                'path': f'/users/{user_id}',
                'protocol': 'HTTP/1.1',
                'sourceIp': '127.0.0.1',
                'userAgent': 'test-agent'
            },
            'requestId': 'test-request-id',
            'routeKey': f'GET /users/{user_id}',
            'stage': '$default',
            'time': '01/Jan/2025:00:00:00 +0000',
            'timeEpoch': 1704067200000
        },
        'pathParameters': {
            'userId': user_id
        },
        'isBase64Encoded': False
    }
    
    class MockContext:
        function_name = 'test-get-user'
        aws_request_id = 'test-request-id'
        
        @staticmethod
        def get_remaining_time_in_millis():
            return 10000
    
    result = handler(event, MockContext())
    
    print(f'\n📤 Response (Status {result["statusCode"]}):')
    body = json.loads(result['body'])
    print(json.dumps(body, indent=2))
    
    if result['statusCode'] == 200:
        print('\n✅ User retrieved successfully!')
    elif result['statusCode'] == 404:
        print('\n⚠️  User not found')
    else:
        print(f'\n❌ Error: {body.get("error", "Unknown error")}')


def test_query_users(query_type='list', query_value=None):
    """Test query-users Lambda (API Gateway)"""
    # Build query parameters
    query_params = {}
    if query_type != 'list' and query_value:
        query_params[query_type] = query_value
    
    # Build description
    if query_type == 'list':
        description = 'List all users'
        raw_query_string = ''
    else:
        description = f'Query by {query_type}: {query_value}'
        raw_query_string = f'{query_type}={query_value}'
    
    mode = '☁️  CLOUD' if IS_CLOUD else '💻 LOCAL'
    print(f'🧪 Testing [{mode}]: GET /users?{raw_query_string if raw_query_string else "(no params)"}')
    print(f'   {description}')
    print('='*60)
    
    if IS_CLOUD:
        # Test against deployed API Gateway
        status_code, body = make_http_request('GET', '/users', query_params if query_params else None)
        
        print(f'\n📤 Response (Status {status_code}):')
        print(json.dumps(body, indent=2))
        
        if status_code == 200:
            if 'users' in body:
                count = body.get('count', len(body.get('users', [])))
                print(f'\n✅ Query completed successfully! Found {count} user(s) in cloud')
            else:
                print('\n✅ User found in cloud!')
        elif status_code == 404:
            print('\n⚠️  User not found in cloud')
        else:
            print(f'\n❌ Error: {body.get("error", "Unknown error")}')
        
        return
    
    # Test local Lambda
    # Add Lambda to path
    sys.path.insert(0, str(Path(__file__).parent.parent / 'src' / 'users' / 'query'))
    from handler import handler
    
    # Create API Gateway event (format version 2.0)
    event = {
        'version': '2.0',
        'routeKey': 'GET /users',
        'rawPath': '/users',
        'rawQueryString': raw_query_string,
        'headers': {
            'accept': 'application/json',
            'content-type': 'application/json'
        },
        'queryStringParameters': query_params if query_params else None,
        'requestContext': {
            'accountId': '123456789012',
            'apiId': 'test-api',
            'domainName': 'test.execute-api.us-east-1.amazonaws.com',
            'domainPrefix': 'test',
            'http': {
                'method': 'GET',
                'path': '/users',
                'protocol': 'HTTP/1.1',
                'sourceIp': '127.0.0.1',
                'userAgent': 'test-agent'
            },
            'requestId': 'test-request-id',
            'routeKey': 'GET /users',
            'stage': '$default',
            'time': '01/Jan/2025:00:00:00 +0000',
            'timeEpoch': 1704067200000
        },
        'isBase64Encoded': False
    }
    
    class MockContext:
        function_name = 'test-query-users'
        aws_request_id = 'test-request-id'
        
        @staticmethod
        def get_remaining_time_in_millis():
            return 30000
    
    result = handler(event, MockContext())
    
    print(f'\n📤 Response (Status {result["statusCode"]}):')
    body = json.loads(result['body'])
    
    if 'users' in body:
        print(f'   Found {body["count"]} user(s)')
        for user in body['users'][:3]:  # Show first 3
            print(f'   - {user["email"]} ({user["userId"]})')
        if body['count'] > 3:
            print(f'   ... and {body["count"] - 3} more')
    else:
        print(json.dumps(body, indent=2))
    
    if result['statusCode'] == 200:
        print('\n✅ Query completed successfully!')
    elif result['statusCode'] == 404:
        print('\n⚠️  No users found')
    else:
        print(f'\n❌ Error: {body.get("error", "Unknown error")}')


def test_update_user(user_id, update_data):
    """Test update-user Lambda (API Gateway)"""
    if not user_id:
        print('❌ Error: userId is required')
        print('Usage: python scripts/test_users.py update <userId> <field=value> [<field=value>...] [--cloud]')
        sys.exit(1)
    
    if not update_data:
        print('❌ Error: At least one field to update is required')
        print('Example: python scripts/test_users.py update <userId> firstName=Jane lastName=Smith')
        sys.exit(1)
    
    mode = '☁️  CLOUD' if IS_CLOUD else '💻 LOCAL'
    print(f'🧪 Testing [{mode}]: PUT /users/{user_id}')
    print(f'   Update data: {json.dumps(update_data, indent=2)}')
    print('='*60)
    
    if IS_CLOUD:
        # Test against deployed API Gateway
        import urllib.request
        import urllib.parse
        
        api_url = get_api_gateway_url()
        url = f'{api_url}/users/{user_id}'
        
        print(f'🌐 Making request to: {url}')
        
        try:
            data = json.dumps(update_data).encode('utf-8')
            req = urllib.request.Request(url, data=data, method='PUT')
            req.add_header('Content-Type', 'application/json')
            
            with urllib.request.urlopen(req, timeout=30) as response:
                status_code = response.status
                body = json.loads(response.read().decode('utf-8'))
        
        except urllib.error.HTTPError as e:
            status_code = e.code
            try:
                body = json.loads(e.read().decode('utf-8'))
            except:
                body = {'error': str(e)}
        
        print(f'\n📤 Response (Status {status_code}):')
        print(json.dumps(body, indent=2))
        
        if status_code == 200:
            print('\n✅ User updated successfully in cloud!')
        elif status_code == 404:
            print('\n⚠️  User not found in cloud')
        else:
            print(f'\n❌ Error: {body.get("error", "Unknown error")}')
        
        return
    
    # Test local Lambda
    sys.path.insert(0, str(Path(__file__).parent.parent / 'src' / 'users' / 'update'))
    from handler import handler
    
    # Create API Gateway event (format version 2.0)
    event = {
        'version': '2.0',
        'routeKey': f'PUT /users/{user_id}',
        'rawPath': f'/users/{user_id}',
        'requestContext': {
            'http': {
                'method': 'PUT',
                'path': f'/users/{user_id}'
            }
        },
        'pathParameters': {
            'userId': user_id
        },
        'body': json.dumps(update_data),
        'isBase64Encoded': False
    }
    
    class MockContext:
        function_name = 'test-update-user'
        aws_request_id = 'test-request-id'
        
        @staticmethod
        def get_remaining_time_in_millis():
            return 10000
    
    result = handler(event, MockContext())
    
    print(f'\n📤 Response (Status {result["statusCode"]}):')
    body = json.loads(result['body'])
    print(json.dumps(body, indent=2))
    
    if result['statusCode'] == 200:
        print('\n✅ User updated successfully!')
    elif result['statusCode'] == 404:
        print('\n⚠️  User not found')
    elif result['statusCode'] == 400:
        print(f'\n⚠️  Validation error: {body.get("error", "Unknown error")}')
    else:
        print(f'\n❌ Error: {body.get("error", "Unknown error")}')


def test_delete_user(user_id):
    """Test delete-user Lambda (API Gateway)"""
    if not user_id:
        print('❌ Error: userId is required')
        print('Usage: python scripts/test_users.py delete <userId> [--cloud]')
        sys.exit(1)
    
    mode = '☁️  CLOUD' if IS_CLOUD else '💻 LOCAL'
    print(f'🧪 Testing [{mode}]: DELETE /users/{user_id}')
    print('='*60)
    
    if IS_CLOUD:
        # Test against deployed API Gateway
        import urllib.request
        
        api_url = get_api_gateway_url()
        url = f'{api_url}/users/{user_id}'
        
        print(f'🌐 Making request to: {url}')
        
        try:
            req = urllib.request.Request(url, method='DELETE')
            req.add_header('Content-Type', 'application/json')
            
            with urllib.request.urlopen(req, timeout=30) as response:
                status_code = response.status
                # 204 No Content has no body
                body = {} if status_code == 204 else json.loads(response.read().decode('utf-8'))
        
        except urllib.error.HTTPError as e:
            status_code = e.code
            try:
                body = json.loads(e.read().decode('utf-8'))
            except:
                body = {'error': str(e)}
        
        print(f'\n📤 Response (Status {status_code}):')
        if body:
            print(json.dumps(body, indent=2))
        else:
            print('   (No content)')
        
        if status_code == 204:
            print('\n✅ User deleted successfully from cloud!')
        elif status_code == 404:
            print('\n⚠️  User not found in cloud')
        else:
            print(f'\n❌ Error: {body.get("error", "Unknown error")}')
        
        return
    
    # Test local Lambda
    sys.path.insert(0, str(Path(__file__).parent.parent / 'src' / 'users' / 'delete'))
    from handler import handler
    
    # Create API Gateway event (format version 2.0)
    event = {
        'version': '2.0',
        'routeKey': f'DELETE /users/{user_id}',
        'rawPath': f'/users/{user_id}',
        'requestContext': {
            'http': {
                'method': 'DELETE',
                'path': f'/users/{user_id}'
            }
        },
        'pathParameters': {
            'userId': user_id
        },
        'isBase64Encoded': False
    }
    
    class MockContext:
        function_name = 'test-delete-user'
        aws_request_id = 'test-request-id'
        
        @staticmethod
        def get_remaining_time_in_millis():
            return 10000
    
    result = handler(event, MockContext())
    
    print(f'\n📤 Response (Status {result["statusCode"]}):')
    if result.get('body'):
        body = json.loads(result['body'])
        print(json.dumps(body, indent=2))
    else:
        print('   (No content)')
    
    if result['statusCode'] == 204:
        print('\n✅ User deleted successfully!')
    elif result['statusCode'] == 404:
        print('\n⚠️  User not found')
    else:
        body = json.loads(result.get('body', '{}'))
        print(f'\n❌ Error: {body.get("error", "Unknown error")}')


def show_usage():
    """Show usage information"""
    print("""
🧪 User Lambda Test Script

Usage:
    python scripts/test_users.py <command> [options] [--cloud]

Commands:
    create                          Test create-user Lambda (Cognito trigger)
    get <userId>                    Test get-user Lambda
    query [type] [value]            Test query-users Lambda
    update <userId> <field=value>   Test update-user Lambda
    delete <userId>                 Test delete-user Lambda

Options:
    --cloud                         Test against deployed API Gateway (default: local)

Query Types:
    list                            List all users (default)
    email <email>                   Query by email
    cognitoSub <sub>                Query by Cognito sub
    teamId <teamId>                 Query by team ID

Examples (Local):
    python scripts/test_users.py create
    python scripts/test_users.py get 12345678-1234-1234-1234-123456789012
    python scripts/test_users.py query list
    python scripts/test_users.py query email test@example.com
    python scripts/test_users.py update 12345678-1234-1234-1234-123456789012 firstName=Jane lastName=Smith
    python scripts/test_users.py delete 12345678-1234-1234-1234-123456789012

Examples (Cloud):
    python scripts/test_users.py get 12345678-1234-1234-1234-123456789012 --cloud
    python scripts/test_users.py query list --cloud
    python scripts/test_users.py update 12345678-1234-1234-1234-123456789012 firstName=Jane --cloud
    python scripts/test_users.py delete 12345678-1234-1234-1234-123456789012 --cloud

Workflow:
    1. python scripts/test_users.py create                                    # Create a test user
    2. Copy the userId from the output
    3. python scripts/test_users.py get <userId>                              # Get the user
    4. python scripts/test_users.py update <userId> firstName=Jane            # Update the user
    5. python scripts/test_users.py get <userId>                              # Verify update
    6. python scripts/test_users.py query list                                # List all users
    7. python scripts/test_users.py delete <userId>                           # Delete the user
""")


def main():
    if len(sys.argv) < 2:
        show_usage()
        sys.exit(0)
    
    command = sys.argv[1]
    
    try:
        if command == 'create':
            test_create_user()
        
        elif command == 'get':
            user_id = sys.argv[2] if len(sys.argv) > 2 else None
            test_get_user(user_id)
        
        elif command == 'query':
            query_type = sys.argv[2] if len(sys.argv) > 2 else 'list'
            query_value = sys.argv[3] if len(sys.argv) > 3 else None
            
            if query_type not in ['list', 'email', 'cognitoSub', 'teamId']:
                print(f'❌ Invalid query type: {query_type}')
                print('Valid types: list, email, cognitoSub, teamId')
                sys.exit(1)
            
            if query_type != 'list' and not query_value:
                print(f'❌ Query type "{query_type}" requires a value')
                print(f'Usage: python scripts/test_users.py query {query_type} <value>')
                sys.exit(1)
            
            test_query_users(query_type, query_value)
        
        elif command == 'update':
            user_id = sys.argv[2] if len(sys.argv) > 2 else None
            
            # Parse field=value pairs
            update_data = {}
            for arg in sys.argv[3:]:
                if '=' in arg:
                    key, value = arg.split('=', 1)
                    update_data[key] = value
            
            test_update_user(user_id, update_data)
        
        elif command == 'delete':
            user_id = sys.argv[2] if len(sys.argv) > 2 else None
            test_delete_user(user_id)
        
        else:
            print(f'❌ Unknown command: {command}')
            show_usage()
            sys.exit(1)
    
    except KeyboardInterrupt:
        print('\n\n⚠️  Interrupted by user')
        sys.exit(1)
    except Exception as e:
        print(f'\n❌ Test failed: {e}')
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()

