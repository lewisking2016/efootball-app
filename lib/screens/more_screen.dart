import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../data/firebase_service.dart';
import '../models/app_user_model.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<AppUser?>(
      future: context.read<FirebaseService>().getUserProfile(user?.uid ?? ''),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final isAdmin = profile?.isAdmin ?? false;

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
                            if (isAdmin)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: AppTheme.accentGreen, borderRadius: BorderRadius.circular(4)),
                                child: const Text("ADMIN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Settings List
                if (isAdmin)
                  _buildSettingTile(Icons.add_circle_outline, "Admin: Create Tournament", onTap: () => context.push('/create-tournament')),
                
                _buildSettingTile(Icons.notifications_outlined, "Notification Settings"),
                _buildSettingTile(Icons.privacy_tip_outlined, "Privacy & Terms"),
                _buildSettingTile(Icons.help_outline, "Help & Support"),
                _buildSettingTile(Icons.info_outline, "About eFootball League"),
                
                if (isAdmin)
                  _buildSettingTile(
                    Icons.delete_sweep_outlined, 
                    "Admin: Reset All App Data", 
                    onTap: () => _showWipeConfirmation(context),
                  ),
                
                const SizedBox(height: 24),
                
                // Logout
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
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
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
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



  void _showWipeConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset All Data?"),
        content: const Text("This will permanently delete all tournaments, teams, standings, and matches. This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
              await context.read<FirebaseService>().wipeAllData();
              if (context.mounted) {
                Navigator.pop(context); // Close loading
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("All data has been wiped clean.")));
                context.go('/home');
              }
            },
            child: const Text("WIPE EVERYTHING", style: TextStyle(color: AppTheme.redForm, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
