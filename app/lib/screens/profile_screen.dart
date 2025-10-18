import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

/// Profile screen showing user info and settings
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? userEmail;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      final attributes = await Amplify.Auth.fetchUserAttributes();
      
      setState(() {
        userEmail = attributes
            .firstWhere((attr) => attr.userAttributeKey == AuthUserAttributeKey.email)
            .value;
        isLoading = false;
      });
    } catch (e) {
      safePrint('Error loading user info: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF10B981)),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981), width: 2),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF10B981), width: 3),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userEmail ?? 'User',
                    style: GoogleFonts.tektur(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFE2E8F0),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PLAYER',
                    style: GoogleFonts.tektur(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Settings Section
            Text(
              'SETTINGS',
              style: GoogleFonts.tektur(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF10B981),
                letterSpacing: 1.5,
              ),
            ),

            const SizedBox(height: 12),

            _SettingsItem(
              icon: Icons.person_outline,
              title: 'Edit Profile',
              onTap: () {
                // TODO: Navigate to edit profile
              },
            ),
            _SettingsItem(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              onTap: () {
                // TODO: Navigate to notification settings
              },
            ),
            _SettingsItem(
              icon: Icons.security_outlined,
              title: 'Privacy & Security',
              onTap: () {
                // TODO: Navigate to privacy settings
              },
            ),
            _SettingsItem(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {
                // TODO: Navigate to help
              },
            ),
            _SettingsItem(
              icon: Icons.info_outline,
              title: 'About',
              onTap: () {
                // TODO: Show about dialog
              },
            ),

            const SizedBox(height: 32),

            // App Version
            Center(
              child: Text(
                'HackTracker v1.0.0',
                style: GoogleFonts.tektur(
                  fontSize: 11,
                  color: const Color(0xFF475569),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// Settings item widget
class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF10B981), size: 22),
        title: Text(
          title,
          style: GoogleFonts.tektur(
            fontSize: 14,
            color: const Color(0xFFE2E8F0),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Color(0xFF64748B),
        ),
        onTap: onTap,
      ),
    );
  }
}

