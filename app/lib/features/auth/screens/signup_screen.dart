import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:hacktracker/theme/app_colors.dart';
import 'package:hacktracker/theme/custom_text_styles.dart';
import 'package:hacktracker/theme/decoration_styles.dart';
import 'package:hacktracker/widgets/app_input_fields.dart';

/// Sign Up Screen for user registration
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _isLoading = false;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    // Validation
    if (_firstNameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your first name';
      });
      return;
    }

    if (_lastNameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your last name';
      });
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email';
      });
      return;
    }

    if (_passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a password';
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    if (_passwordController.text.length < 8) {
      setState(() {
        _errorMessage = 'Password must be at least 8 characters';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Amplify.Auth.signUp(
        username: _emailController.text.trim(),
        password: _passwordController.text,
        options: SignUpOptions(
          userAttributes: {
            AuthUserAttributeKey.email: _emailController.text.trim(),
            AuthUserAttributeKey.givenName: _firstNameController.text.trim(),
            AuthUserAttributeKey.familyName: _lastNameController.text.trim(),
          },
        ),
      );

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        _showSuccessDialog(
          'Account created!\n\nCheck your email and click the verification link to activate your account.',
        );
      }
    } on AuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Success',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary),
        ),
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to login
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Sign Up',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                    'SIGN UP',
                    style: Theme.of(context).extension<CustomTextStyles>()!.statusIndicator,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // First Name Field
              TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'FIRST NAME',
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
                ),
                textCapitalization: TextCapitalization.words,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              // Last Name Field
              TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'LAST NAME',
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
                ),
                textCapitalization: TextCapitalization.words,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              // Email Field
              AppEmailField(
                controller: _emailController,
                labelText: 'EMAIL',
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
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
              const SizedBox(height: 16),
              // Confirm Password Field
              AppPasswordField(
                controller: _confirmPasswordController,
                labelText: 'CONFIRM PASSWORD',
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                autocorrect: false,
              ),
              const SizedBox(height: 12),
              // Password Requirements
              Container(
                padding: const EdgeInsets.all(12),
                decoration: DecorationStyles.passwordRequirements(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PASSWORD REQUIREMENTS:',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiary,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '• Minimum 8 characters',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
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
              // Sign Up Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignUp,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text('SIGN UP'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
