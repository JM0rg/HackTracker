class AppConfig {
  final String cognitoUserPoolId;
  final String cognitoClientId;
  final String cognitoRegion;

  const AppConfig({
    required this.cognitoUserPoolId,
    required this.cognitoClientId,
    required this.cognitoRegion,
  });

  String get amplifyConfig => '''{
    "UserAgent": "aws-amplify-cli/2.0",
    "Version": "1.0",
    "auth": {
      "plugins": {
        "awsCognitoAuthPlugin": {
          "UserAgent": "aws-amplify-cli/0.1.0",
          "Version": "0.1.0",
          "IdentityManager": {
            "Default": {}
          },
          "CognitoUserPool": {
            "Default": {
              "PoolId": "$cognitoUserPoolId",
              "AppClientId": "$cognitoClientId",
              "Region": "$cognitoRegion"
            }
          },
          "Auth": {
            "Default": {
              "authenticationFlowType": "USER_SRP_AUTH",
              "socialProviders": [],
              "usernameAttributes": ["EMAIL"],
              "signupAttributes": ["EMAIL"],
              "passwordProtectionSettings": {
                "passwordPolicyMinLength": 8,
                "passwordPolicyCharacters": []
              },
              "mfaConfiguration": "OFF",
              "mfaTypes": ["SMS"],
              "verificationMechanisms": ["EMAIL"]
            }
          }
        }
      }
    }
  }''';
}

class Environment {
  static const String _userPoolId = String.fromEnvironment(
    'COGNITO_USER_POOL_ID',
    defaultValue: 'us-east-1_6oZj7BCGd', // Deployed Cognito User Pool
  );

  static const String _clientId = String.fromEnvironment(
    'COGNITO_CLIENT_ID',
    defaultValue: '6d5gg4nr09c33lji5rvmqiu3rf', // Deployed Cognito Client
  );

  static const String _region = String.fromEnvironment(
    'COGNITO_REGION',
    defaultValue: 'us-east-1',
  );

  static AppConfig get config => AppConfig(
        cognitoUserPoolId: _userPoolId,
        cognitoClientId: _clientId,
        cognitoRegion: _region,
      );
}

