import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'config/app_config.dart';
import 'theme/app_theme.dart';
import 'utils/messenger.dart';
import 'widgets/splash_screen.dart';
import 'features/auth/widgets/auth_gate.dart';

/// Main HackTracker App
class HackTrackerApp extends StatefulWidget {
  const HackTrackerApp({super.key});

  @override
  State<HackTrackerApp> createState() => _HackTrackerAppState();
}

class _HackTrackerAppState extends State<HackTrackerApp> {
  bool _amplifyConfigured = false;

  @override
  void initState() {
    super.initState();
    _configureAmplify();
  }

  Future<void> _configureAmplify() async {
    try {
      await Amplify.addPlugin(AmplifyAuthCognito());
      await Amplify.configure(Environment.config.amplifyConfig);
      setState(() {
        _amplifyConfigured = true;
      });
      safePrint('Successfully configured Amplify');
    } on Exception catch (e) {
      safePrint('Error configuring Amplify: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HackTracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      scaffoldMessengerKey: messengerKey,
      home: _amplifyConfigured
          ? const AuthGate()
          : const SplashScreen(),
    );
  }
}
