import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config/app_config.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';

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
      home: _amplifyConfigured
          ? const AuthGate()
          : Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            ),
    );
  }
}

/// Auth gate that checks if user is already logged in
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuthSession>(
      future: Amplify.Auth.fetchAuthSession(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          );
        }

        // Check if user is signed in
        if (snapshot.hasData && snapshot.data!.isSignedIn) {
          return const HomeScreen();
        }

        // Not signed in, show login
        return const LoginScreen();
      },
    );
  }
}

// Login Screen (Default)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  bool _obscurePassword = true;
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
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'HACKTRACKER',
                      style: GoogleFonts.tektur(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Slowpitch Stats Tracking',
                      style: GoogleFonts.tektur(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                        letterSpacing: 1,
                      ),
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
                    style: GoogleFonts.tektur(
                      fontSize: 13,
                      color: AppColors.primary,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Email Field
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'EMAIL',
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
                ),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
                style: GoogleFonts.tektur(fontSize: 15),
              ),
              const SizedBox(height: 16),
              // Password Field
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'PASSWORD',
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textTertiary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
                style: GoogleFonts.tektur(fontSize: 15),
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
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.tektur(
                            color: Colors.red,
                            fontSize: 12,
                          ),
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
                      style: GoogleFonts.tektur(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
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

// Sign Up Screen
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
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
          style: GoogleFonts.tektur(color: AppColors.primary),
        ),
        content: Text(
          message,
          style: GoogleFonts.tektur(fontSize: 14),
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
          style: GoogleFonts.tektur(
            color: AppColors.primary,
            fontSize: 16,
          ),
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
                    style: GoogleFonts.tektur(
                      fontSize: 13,
                      color: AppColors.primary,
                      letterSpacing: 2,
                    ),
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
                style: GoogleFonts.tektur(fontSize: 15),
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
                style: GoogleFonts.tektur(fontSize: 15),
              ),
              const SizedBox(height: 16),
              // Email Field
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'EMAIL',
                  prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
                ),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
                style: GoogleFonts.tektur(fontSize: 15),
              ),
              const SizedBox(height: 16),
              // Password Field
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'PASSWORD',
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textTertiary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
                style: GoogleFonts.tektur(fontSize: 15),
              ),
              const SizedBox(height: 16),
              // Confirm Password Field
              TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'CONFIRM PASSWORD',
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.textTertiary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscureConfirmPassword,
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
                style: GoogleFonts.tektur(fontSize: 15),
              ),
              const SizedBox(height: 12),
              // Password Requirements
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PASSWORD REQUIREMENTS:',
                      style: GoogleFonts.tektur(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '• Minimum 8 characters',
                      style: GoogleFonts.tektur(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Error Message
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.tektur(
                            color: Colors.red,
                            fontSize: 12,
                          ),
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

// Forgot Password Screen
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  bool _isLoading = false;
  bool _codeSent = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
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
              style: GoogleFonts.tektur(color: AppColors.primary),
            ),
            content: Text(
              'Password reset successfully!\n\nYou can now log in with your new password.',
              style: GoogleFonts.tektur(fontSize: 14),
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
          style: GoogleFonts.tektur(
            color: AppColors.primary,
            fontSize: 16,
          ),
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
                    style: GoogleFonts.tektur(
                      fontSize: 13,
                      color: AppColors.primary,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (!_codeSent) ...[
                // Email Field
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'EMAIL',
                    prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textCapitalization: TextCapitalization.none,
                  style: GoogleFonts.tektur(fontSize: 15),
                ),
                const SizedBox(height: 12),
                // Info Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'Enter your email address and we\'ll send you a code to reset your password.',
                    style: GoogleFonts.tektur(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ] else ...[
                // Code Field
                TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'RESET CODE',
                    prefixIcon: Icon(Icons.key_outlined, color: AppColors.primary),
                  ),
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.tektur(fontSize: 15),
                ),
                const SizedBox(height: 16),
                // New Password Field
                TextField(
                  controller: _newPasswordController,
                  decoration: InputDecoration(
                    labelText: 'NEW PASSWORD',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textTertiary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  autocorrect: false,
                  textCapitalization: TextCapitalization.none,
                  style: GoogleFonts.tektur(fontSize: 15),
                ),
                const SizedBox(height: 16),
                // Confirm Password Field
                TextField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'CONFIRM PASSWORD',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.textTertiary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscureConfirmPassword,
                  autocorrect: false,
                  textCapitalization: TextCapitalization.none,
                  style: GoogleFonts.tektur(fontSize: 15),
                ),
                const SizedBox(height: 12),
                // Info Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'Check your email for the reset code.',
                    style: GoogleFonts.tektur(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
              // Error Message
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.tektur(
                            color: Colors.red,
                            fontSize: 12,
                          ),
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
