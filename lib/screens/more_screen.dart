import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/notification_service.dart';
import '../data/session_service.dart';
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
            title: const Text(
              "More Options",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
                        backgroundImage: user?.photoURL != null
                            ? NetworkImage(user!.photoURL!)
                            : null,
                        child: user?.photoURL == null
                            ? const Icon(
                                Icons.person,
                                size: 40,
                                color: AppTheme.primaryPurple,
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? "Guest User",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryPurple,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? "Not signed in permanently",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                            if (isAdmin)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentGreen,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  "ADMIN",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
                  _buildSettingTile(
                    Icons.add_circle_outline,
                    "Admin: Create Tournament",
                    onTap: () => context.push('/create-tournament'),
                  ),

                _buildSettingTile(
                  Icons.notifications_outlined,
                  "Notification Settings",
                  onTap: () => _showNotificationSettings(context, user),
                ),
                _buildSettingTile(
                  Icons.privacy_tip_outlined,
                  "Privacy & Terms",
                  onTap: () => _showPrivacyAndTerms(context),
                ),
                _buildSettingTile(
                  Icons.help_outline,
                  "Help & Support",
                  onTap: () => _showHelpAndSupport(context),
                ),
                _buildSettingTile(
                  Icons.info_outline,
                  "About eFootball League",
                  onTap: () => _showAboutApp(context),
                ),

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
                      await SessionService.clearRememberPreference();
                      await GoogleSignIn().signOut();
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) context.go('/');
                    },
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      "LOG OUT",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.redForm,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Delete Account
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextButton.icon(
                    onPressed: () =>
                        _showDeleteAccountConfirmation(context, user),
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    label: const Text(
                      "DELETE ACCOUNT",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                        fontSize: 13,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

                const SizedBox(height: 48),
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

  void _showNotificationSettings(BuildContext context, User? user) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Notification Settings"),
        content: const Text(
          "Turn on reminders for match day alerts and important league updates. You can also send a test notification to confirm your device is ready.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("CLOSE"),
          ),
          TextButton(
            onPressed: () async {
              await NotificationService.initialize();
              if (user != null) {
                await NotificationService.saveTokenToFirestore(user.uid);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Notifications are enabled.")),
                );
              }
            },
            child: const Text("ENABLE"),
          ),
          ElevatedButton(
            onPressed: () async {
              await NotificationService.showLocalNotification(
                "eFootball League",
                "Notifications are working on this device.",
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text("SEND TEST"),
          ),
        ],
      ),
    );
  }

  void _showPrivacyAndTerms(BuildContext context) {
    _showInfoDialog(
      context,
      title: "Privacy & Terms",
      icon: Icons.privacy_tip_outlined,
      body:
          "Your account keeps your profile, claimed team, tournament entries, match results, and standings linked to your Firebase user ID. Signing out does not delete league data. Deleting your account removes your user profile and releases your claimed team.",
    );
  }

  void _showHelpAndSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Help & Support"),
        content: const Text(
          "Need help with login, claiming a team, submitting results, or managing a league? Send support a message and include your league name plus the account email shown on this page.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("CLOSE"),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final uri = Uri(
                scheme: 'mailto',
                path: 'support@efootballleague.app',
                queryParameters: {
                  'subject': 'eFootball League Support',
                  'body': 'Hi, I need help with ',
                },
              );
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
            icon: const Icon(Icons.email_outlined),
            label: const Text("EMAIL SUPPORT"),
          ),
        ],
      ),
    );
  }

  void _showAboutApp(BuildContext context) {
    _showInfoDialog(
      context,
      title: "About eFootball League",
      icon: Icons.info_outline,
      body:
          "eFootball League helps managers run tournaments, claim teams, submit match results, track standings, and keep league history in one place.",
    );
  }

  void _showInfoDialog(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String body,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: AppTheme.primaryPurple),
            const SizedBox(width: 10),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("GOT IT"),
          ),
        ],
      ),
    );
  }

  void _showWipeConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset All Data?"),
        content: const Text(
          "This will permanently delete all tournaments, teams, standings, and matches. This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                    const Center(child: CircularProgressIndicator()),
              );
              await context.read<FirebaseService>().wipeAllData();
              if (context.mounted) {
                Navigator.pop(context); // Close loading
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("All data has been wiped clean."),
                  ),
                );
                context.go('/home');
              }
            },
            child: const Text(
              "WIPE EVERYTHING",
              style: TextStyle(
                color: AppTheme.redForm,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountConfirmation(BuildContext context, User? user) {
    if (user == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete Account?"),
        content: const Text(
          "This is permanent. It will delete your profile and release your claimed team. This cannot be undone.",
          style: TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog

              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: CircularProgressIndicator(color: AppTheme.accentGreen),
                ),
              );

              try {
                final firebaseService = context.read<FirebaseService>();

                // 1. Cleanup Firestore first
                await firebaseService.deleteUserAccount(user.uid);
                await SessionService.clearRememberPreference();

                // 2. Delete Firebase Auth account
                try {
                  await user.delete();
                } on FirebaseAuthException catch (e) {
                  if (e.code == 'requires-recent-login') {
                    if (context.mounted) {
                      Navigator.pop(context); // Close loading
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Please log out and log back in to verify your identity before deleting your account.",
                          ),
                        ),
                      );
                      return;
                    }
                  }
                }

                if (context.mounted) {
                  Navigator.pop(context); // Close loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Account deleted successfully."),
                    ),
                  );
                  context.go('/');
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // Close loading
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.redForm,
              foregroundColor: Colors.white,
            ),
            child: const Text("DELETE PERMANENTLY"),
          ),
        ],
      ),
    );
  }
}
