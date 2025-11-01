import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:hacktracker/theme/app_colors.dart';
import 'package:hacktracker/theme/glass_theme.dart';
import 'package:hacktracker/features/auth/widgets/auth_gate.dart';
import 'package:hacktracker/features/auth/widgets/glass_container.dart';
import 'package:hacktracker/features/auth/widgets/glass_button.dart';
import 'package:hacktracker/features/auth/widgets/status_indicator.dart';
import 'package:hacktracker/features/auth/widgets/auth_title_header.dart';
import 'package:hacktracker/features/auth/widgets/auth_error_message.dart';
import 'package:hacktracker/features/auth/widgets/auth_divider.dart';
import 'package:hacktracker/features/auth/widgets/auth_form_link.dart';
import 'package:hacktracker/features/auth/widgets/auth_info_box.dart';
import 'package:hacktracker/features/auth/widgets/auth_success_dialog.dart';
import 'package:hacktracker/features/auth/widgets/auth_glass_field.dart';

enum AuthFormMode { login, signup, forgotPassword }

/// Login Screen with iOS liquid glass aesthetic
/// Handles both login and signup forms with animated transitions
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  AuthFormMode _formMode = AuthFormMode.login;
  bool _isLoading = false;
  
  // Login controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Signup controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Forgot password controllers
  bool _codeSent = false;
  final _forgotPasswordEmailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();
  
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _confirmPasswordController.dispose();
    _forgotPasswordEmailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  void _switchFormMode(AuthFormMode mode) {
    if (_formMode == mode) return;
    
    setState(() {
      _formMode = mode;
      _errorMessage = null;
      if (mode != AuthFormMode.forgotPassword) {
        _codeSent = false; // Reset forgot password state when leaving
      }
      _animationController.reset();
      _animationController.forward();
    });
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

      debugPrint('✅ Login successful, reloading AuthGate');
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthGate()),
        );
      }
      
    } on AuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    }
  }

  Future<void> _handleSignUp() async {
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

    if (_signupEmailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email';
      });
      return;
    }

    if (_signupPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a password';
      });
      return;
    }

    if (_signupPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    if (_signupPasswordController.text.length < 8) {
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
        username: _signupEmailController.text.trim(),
        password: _signupPasswordController.text,
        options: SignUpOptions(
          userAttributes: {
            AuthUserAttributeKey.email: _signupEmailController.text.trim(),
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

  void _showSuccessDialog(String message, {VoidCallback? onOk}) {
    AuthSuccessDialog.show(
      context,
      title: 'Success',
      message: message,
      onOkPressed: onOk ??
          () {
            Navigator.pop(context);
            _switchFormMode(AuthFormMode.login);
          },
    );
  }

  Future<void> _sendResetCode() async {
    if (_forgotPasswordEmailController.text.trim().isEmpty) {
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
        username: _forgotPasswordEmailController.text.trim(),
      );

      setState(() {
        _isLoading = false;
        _codeSent = true;
        _errorMessage = null;
      });

      // Restart fade animation for form transition
      _animationController.reset();
      _animationController.forward();
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

    if (_newPasswordController.text != _confirmNewPasswordController.text) {
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
        username: _forgotPasswordEmailController.text.trim(),
        newPassword: _newPasswordController.text,
        confirmationCode: _codeController.text,
      );

      if (mounted) {
        AuthSuccessDialog.show(
          context,
          title: 'Success',
          message: 'Password reset successfully!\n\nYou can now log in with your new password.',
          onOkPressed: () {
            Navigator.pop(context);
            _switchFormMode(AuthFormMode.login);
          },
        );
      }
    } on AuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    }
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status Indicator
        StatusIndicator(text: 'LOG IN'),
        const SizedBox(height: 12),
        // Email Field
        AuthGlassField(
          controller: _emailController,
          labelText: 'EMAIL',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
        ),
        const SizedBox(height: 12),
        // Password Field
        AuthGlassField(
          controller: _passwordController,
          labelText: 'PASSWORD',
          icon: Icons.lock_outline,
          obscureText: true,
          autocorrect: false,
        ),
        const SizedBox(height: 8),
        // Forgot Password
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => _switchFormMode(AuthFormMode.forgotPassword),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'FORGOT PASSWORD?',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: GlassTheme.primaryTextColor,
                    letterSpacing: 1,
                  ),
            ),
          ),
        ),
        // Error Message
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          AuthErrorMessage(message: _errorMessage!),
        ],
        const SizedBox(height: 12),
        // Sign In Button
        GlassButton(
          text: 'LOG IN',
          onPressed: _isLoading ? null : _handleSignIn,
          isLoading: _isLoading,
          icon: Icons.login,
          height: 48,
        ),
        const SizedBox(height: 12),
        // Divider
        const AuthDivider(),
        const SizedBox(height: 12),
        // Sign Up Link
        AuthFormLink(
          text: 'CREATE ACCOUNT',
          onPressed: () => _switchFormMode(AuthFormMode.signup),
        ),
      ],
    );
  }

  Widget _buildSignupForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status Indicator
        StatusIndicator(text: 'SIGN UP'),
        const SizedBox(height: 12),
        // First Name Field
        AuthGlassField(
          controller: _firstNameController,
          labelText: 'FIRST NAME',
          icon: Icons.person_outline,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 12),
        // Last Name Field
        AuthGlassField(
          controller: _lastNameController,
          labelText: 'LAST NAME',
          icon: Icons.person_outline,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 12),
        // Email Field
        AuthGlassField(
          controller: _signupEmailController,
          labelText: 'EMAIL',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
        ),
        const SizedBox(height: 12),
        // Password Field
        AuthGlassField(
          controller: _signupPasswordController,
          labelText: 'PASSWORD',
          icon: Icons.lock_outline,
          obscureText: true,
          autocorrect: false,
        ),
        const SizedBox(height: 12),
        // Confirm Password Field
        AuthGlassField(
          controller: _confirmPasswordController,
          labelText: 'CONFIRM PASSWORD',
          icon: Icons.lock_outline,
          obscureText: true,
          autocorrect: false,
        ),
        const SizedBox(height: 8),
        // Password Requirements (compact)
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Minimum 8 characters',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                ),
          ),
        ),
        // Error Message
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          AuthErrorMessage(message: _errorMessage!),
        ],
        const SizedBox(height: 12),
        // Sign Up Button
        GlassButton(
          text: 'SIGN UP',
          onPressed: _isLoading ? null : _handleSignUp,
          isLoading: _isLoading,
          icon: Icons.person_add,
          height: 48,
        ),
        const SizedBox(height: 12),
        // Divider
        const AuthDivider(),
        const SizedBox(height: 12),
        // Sign In Link
        AuthFormLink(
          text: 'SIGN IN',
          onPressed: () => _switchFormMode(AuthFormMode.login),
        ),
      ],
    );
  }

  Widget _buildForgotPasswordForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status Indicator
        StatusIndicator(text: 'RESET PASSWORD'),
        const SizedBox(height: 12),
        if (!_codeSent) ...[
          // Email Field
          AuthGlassField(
            controller: _forgotPasswordEmailController,
            labelText: 'EMAIL',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
          ),
          const SizedBox(height: 12),
          // Info Box
          AuthInfoBox(
            message: 'Enter your email address and we\'ll send you a code to reset your password.',
          ),
        ] else ...[
          // Code Field
          AuthGlassField(
            controller: _codeController,
            labelText: 'RESET CODE',
            icon: Icons.key_outlined,
            keyboardType: TextInputType.number,
            autocorrect: false,
          ),
          const SizedBox(height: 12),
          // New Password Field
          AuthGlassField(
            controller: _newPasswordController,
            labelText: 'NEW PASSWORD',
            icon: Icons.lock_outline,
            obscureText: true,
            autocorrect: false,
          ),
          const SizedBox(height: 12),
          // Confirm Password Field
          AuthGlassField(
            controller: _confirmNewPasswordController,
            labelText: 'CONFIRM PASSWORD',
            icon: Icons.lock_outline,
            obscureText: true,
            autocorrect: false,
          ),
          const SizedBox(height: 12),
          // Info Box
          AuthInfoBox(
            message: 'Check your email for the reset code.',
            icon: Icons.check_circle_outline,
          ),
        ],
        // Error Message
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          AuthErrorMessage(message: _errorMessage!),
        ],
        const SizedBox(height: 12),
        // Action Button
        GlassButton(
          text: _codeSent ? 'RESET PASSWORD' : 'SEND CODE',
          onPressed: _isLoading
              ? null
              : (_codeSent ? _confirmReset : _sendResetCode),
          isLoading: _isLoading,
          icon: _codeSent ? Icons.lock_reset : Icons.send,
          height: 48,
        ),
        const SizedBox(height: 12),
        // Divider
        const AuthDivider(),
        const SizedBox(height: 12),
        // Go Back Link
        AuthFormLink(
          text: 'GO BACK',
          onPressed: () => _switchFormMode(AuthFormMode.login),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: GlassTheme.backgroundGradient,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                // Logo / Header Glass Container (always visible)
                const AuthTitleHeader(),
                const SizedBox(height: 24),
                // Form Glass Container (animated)
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      child: GlassContainer(
                        padding: const EdgeInsets.all(16),
                        child: _formMode == AuthFormMode.login
                            ? _buildLoginForm()
                            : _formMode == AuthFormMode.signup
                                ? _buildSignupForm()
                                : _buildForgotPasswordForm(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
