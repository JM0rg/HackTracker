import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:hacktracker/theme/app_colors.dart';
import 'package:hacktracker/theme/custom_text_styles.dart';
import 'package:hacktracker/theme/decoration_styles.dart';
import 'package:hacktracker/widgets/app_input_fields.dart';
import 'package:hacktracker/screens/home_screen.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

/// Login Screen for user authentication
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter email and password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Amplify.Auth.signIn(
        username: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on AuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: DecorationStyles.primaryBorder(),
                child: Column(
                  children: [
                    Text(
                      'HACKTRACKER',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Slowpitch Stats Tracking',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              // Status Indicator
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'LOG IN',
                    style: Theme.of(context).extension<CustomTextStyles>()!.statusIndicator,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Email Field
              AppEmailField(
                controller: _emailController,
                labelText: 'EMAIL',
                prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                autocorrect: false,
              ),
              const SizedBox(height: 16),
              // Password Field
              AppPasswordField(
                controller: _passwordController,
                labelText: 'PASSWORD',
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                autocorrect: false,
              ),
              const SizedBox(height: 12),
              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: const Text('FORGOT PASSWORD?'),
                ),
              ),
              // Error Message
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: DecorationStyles.errorContainer(),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: Theme.of(context).extension<CustomTextStyles>()!.errorMessage,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              // Sign In Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignIn,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text('LOG IN'),
                ),
              ),
              const SizedBox(height: 24),
              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.border)),
                ],
              ),
              const SizedBox(height: 24),
              // Sign Up Link
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignUpScreen(),
                      ),
                    );
                  },
                  child: const Text('Sign Up'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
