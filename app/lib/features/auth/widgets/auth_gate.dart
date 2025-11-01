import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hacktracker/theme/app_colors.dart';
import 'package:hacktracker/services/auth_service.dart';
import 'package:hacktracker/screens/welcome_screen.dart';
import 'package:hacktracker/screens/dynamic_home_screen.dart';
import 'package:hacktracker/providers/user_context_provider.dart';
import 'package:hacktracker/widgets/splash_screen.dart';
import '../screens/login_screen.dart';

/// Auth gate that checks authentication and user context
/// 
/// Flow:
/// 1. Validate authentication
/// 2. If authenticated, check user context (teams)
/// 3. Route to appropriate screen:
///    - No teams: WelcomeScreen
///    - Has teams: DynamicHomeScreen (with context)
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  /// Handle user context errors by signing out (clears cached tokens)
  Future<void> _handleUserContextError(BuildContext context) async {
    try {
      await AuthService.signOut();
    } catch (e) {
      // Ignore sign out errors, just proceed to login
      debugPrint('Error during sign out in AuthGate: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<AuthStatus>(
      future: AuthService.validateAuth(),
      builder: (context, authSnapshot) {
        // Show splash screen while checking auth (initial app launch)
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        final authStatus = authSnapshot.data ?? AuthStatus.invalidToken;

        // User needs to sign in (invalid, expired, error, or no auth)
        // Treat all non-valid states as "need to login" rather than showing error
        if (!authStatus.isValid) {
          return const LoginScreen();
        }

        // User is authenticated, check team context
        debugPrint('🔐 AuthGate: User authenticated, checking team context...');
        final userContextAsync = ref.watch(userContextNotifierProvider);

        return userContextAsync.when(
          data: (userContext) {
            debugPrint('📊 AuthGate: UserContext loaded - personal: ${userContext.hasPersonalContext}, managed: ${userContext.hasManagedContext}');
            
            // User has no teams - show welcome screen
            if (userContext.shouldShowWelcome) {
              debugPrint('👋 AuthGate: No teams, showing WelcomeScreen');
              return const WelcomeScreen();
            }
            
            // User has teams - show dynamic home with appropriate UI
            debugPrint('🏠 AuthGate: Has teams, showing DynamicHomeScreen');
            return DynamicHomeScreen(userContext: userContext);
          },
          loading: () {
            debugPrint('⏳ AuthGate: Loading user context...');
            // After login, use simple spinner instead of full splash screen
            return Scaffold(
              backgroundColor: Theme.of(context).colorScheme.surface,
              body: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            );
          },
          error: (error, stack) {
            // If user context fails, show welcome screen as fallback (API might not be deployed yet)
            debugPrint('UserContext error: $error');
            
            // For 404 or endpoint not found errors, assume new user with no teams
            if (error.toString().contains('404') || 
                error.toString().contains('Not Found') ||
                error.toString().contains('endpoint')) {
              debugPrint('Context endpoint not found - showing WelcomeScreen');
              return const WelcomeScreen();
            }
            
            // For other errors, try to sign out and redirect to login
            return FutureBuilder(
              future: _handleUserContextError(context),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppColors.primary),
                          const SizedBox(height: 16),
                          Text(
                            'Signing out...',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const LoginScreen();
              },
            );
          },
        );
      },
    );
  }
}
