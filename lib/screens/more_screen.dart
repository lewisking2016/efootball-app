import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.cardColorLight,
      appBar: AppBar(
        title: const Text("More Options", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User Profile Section
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: AppTheme.cardColorLight,
                    backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                    child: user?.photoURL == null ? const Icon(Icons.person, size: 40, color: AppTheme.primaryPurple) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.displayName ?? "Guest User", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple)),
                        const SizedBox(height: 4),
                        Text(user?.email ?? "Not signed in permanently", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Settings List
            _buildSettingTile(Icons.add_circle_outline, "Admin: Create Tournament", onTap: () => context.push('/create-tournament')),
            _buildSettingTile(Icons.notifications_outlined, "Notification Settings"),
            _buildSettingTile(Icons.privacy_tip_outlined, "Privacy & Terms"),
            _buildSettingTile(Icons.help_outline, "Help & Support"),
            _buildSettingTile(Icons.info_outline, "About eFootball League"),
            
            const SizedBox(height: 24),
            
            // Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  // GoRouter will pick this up on splash but we can force it
                  if (context.mounted) context.go('/');
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text("LOG OUT", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.redForm,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Social Links
            const Text("Follow the League", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryPurple)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialIcon(Icons.facebook),
                _buildSocialIcon(Icons.camera_alt),
                _buildSocialIcon(Icons.alternate_email),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile(IconData icon, String title, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryPurple),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.primaryPurple.withOpacity(0.05),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppTheme.primaryPurple, size: 28),
    );
  }
}
