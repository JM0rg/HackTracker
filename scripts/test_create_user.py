"""
Test the create-user Lambda function locally
"""

import json
import os
import sys
from pathlib import Path

# Add src directory to path
src_dir = Path(__file__).parent.parent / 'src' / 'users' / 'create'
sys.path.insert(0, str(src_dir))

# Set environment variables for local testing
os.environ['DYNAMODB_LOCAL'] = 'true'
os.environ['DYNAMODB_ENDPOINT'] = 'http://localhost:8000'
os.environ['TABLE_NAME'] = 'HackTracker-dev'
os.environ['ENVIRONMENT'] = 'dev'

# Import handler
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

# Mock context
class MockContext:
    function_name = 'test-create-user'
    function_version = '$LATEST'
    invoked_function_arn = 'arn:aws:lambda:us-east-1:123456789012:function:test-create-user'
    memory_limit_in_mb = 128
    aws_request_id = 'test-request-id'
    log_group_name = '/aws/lambda/test-create-user'
    log_stream_name = 'test-stream'
    
    @staticmethod
    def get_remaining_time_in_millis():
        return 30000


def main():
    print('🧪 Testing create-user Lambda function locally...\n')
    print('📋 Event:')
    print(json.dumps(event, indent=2))
    print('\n' + '='*60 + '\n')
    
    try:
        context = MockContext()
        result = handler(event, context)
        
        print('\n' + '='*60)
        print('✅ Lambda execution completed successfully!')
        print('\n📤 Response:')
        print(json.dumps(result, indent=2))
        
        print('\n💡 Check DynamoDB Admin UI: http://localhost:8001')
        print('   Look for the new user in the HackTracker-dev table')
        
    except Exception as e:
        print('\n' + '='*60)
        print(f'❌ Lambda execution failed: {e}')
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()

