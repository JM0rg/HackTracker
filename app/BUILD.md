# Building HackTracker

## Environment-Based Builds

The app uses compile-time constants for environment configuration (dev vs prod).

### Development Build

```bash
flutter run --dart-define=COGNITO_USER_POOL_ID=us-east-1_R5NI7XncW \
           --dart-define=COGNITO_CLIENT_ID=3cmqcik2h2d5o96nkdepqmffal \
           --dart-define=COGNITO_REGION=us-east-1
```

Or use the build script:
```bash
./build-dev.sh
```

### Production Build

```bash
flutter run --dart-define=COGNITO_USER_POOL_ID=us-east-1_PROD_POOL \
           --dart-define=COGNITO_CLIENT_ID=PROD_CLIENT_ID \
           --dart-define=COGNITO_REGION=us-east-1
```

Or use the build script:
```bash
./build-prod.sh
```

### Getting Cognito Values from Terraform

```bash
cd ..
tofu workspace select dev
tofu output -json | jq '{cognito_user_pool_id, cognito_client_id}'
```

## Quick Start (Development)

```bash
flutter run
```

This uses the default values configured in `lib/config/app_config.dart` (dev environment).

## Platforms

- **iOS**: `flutter run -d ios`
- **Android**: `flutter run -d android`
- **Web**: `flutter run -d chrome`

