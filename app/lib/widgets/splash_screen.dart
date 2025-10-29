import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Splash screen shown during app initialization
/// 
/// Displays app branding with smooth fade-in animation.
/// After 2 seconds, shows a loading spinner if still loading.
/// This is the "Best-of-Both-Worlds" pattern used by top-tier apps.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _showSpinner = false;

  @override
  void initState() {
    super.initState();
    
    // Create fade animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Create fade animation (0.0 to 1.0)
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));
    
    // Start fade-in animation
    _controller.forward();
    
    // Show spinner after 2 seconds if still loading
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showSpinner = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App icon/logo
              Icon(
                Icons.sports_baseball,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              
              // App name
              Text(
                'HackTracker',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Tagline
              Text(
                'Track Your Game',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              
              // Show spinner after 2 seconds if still loading
              if (_showSpinner) ...[
                const SizedBox(height: 32),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

