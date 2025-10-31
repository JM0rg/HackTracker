import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:hacktracker/theme/app_colors.dart';
import 'package:hacktracker/theme/custom_text_styles.dart';
import 'package:hacktracker/theme/decoration_styles.dart';
import 'package:hacktracker/widgets/app_input_fields.dart';

/// Forgot Password Screen for password reset
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  bool _isLoading = false;
  bool _codeSent = false;
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendResetCode() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Amplify.Auth.resetPassword(
        username: _emailController.text.trim(),
      );

      setState(() {
        _isLoading = false;
        _codeSent = true;
      });
    } on AuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    }
  }

  Future<void> _confirmReset() async {
    if (_codeController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter the code';
      });
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    if (_newPasswordController.text.length < 8) {
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
      await Amplify.Auth.confirmResetPassword(
        username: _emailController.text.trim(),
        newPassword: _newPasswordController.text,
        confirmationCode: _codeController.text,
      );

      if (mounted) {
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
              'Password reset successfully!\n\nYou can now log in with your new password.',
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
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Reset Password',
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
                    'RESET PASSWORD',
                    style: Theme.of(context).extension<CustomTextStyles>()!.statusIndicator,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (!_codeSent) ...[
                // Email Field
                AppEmailField(
                  controller: _emailController,
                  labelText: 'EMAIL',
                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                  autocorrect: false,
                ),
                const SizedBox(height: 12),
                // Info Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: DecorationStyles.infoBox(),
                  child: Text(
                    'Enter your email address and we\'ll send you a code to reset your password.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ] else ...[
                // Code Field
                AppTextField(
                  controller: _codeController,
                  labelText: 'RESET CODE',
                  prefixIcon: const Icon(Icons.key_outlined, color: AppColors.primary),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                // New Password Field
                AppPasswordField(
                  controller: _newPasswordController,
                  labelText: 'NEW PASSWORD',
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
                // Info Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: DecorationStyles.infoBox(),
                  child: Text(
                    'Check your email for the reset code.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
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
              // Action Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : (_codeSent ? _confirmReset : _sendResetCode),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : Text(_codeSent ? 'RESET PASSWORD' : 'SEND CODE'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
