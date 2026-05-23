import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../data/firebase_service.dart';
import '../data/notification_service.dart';
import '../models/team_model.dart';
import '../widgets/line_decoration.dart';
import '../widgets/team_logo.dart';

class PickTeamScreen extends StatefulWidget {
  const PickTeamScreen({super.key});

  @override
  State<PickTeamScreen> createState() => _PickTeamScreenState();
}

class _PickTeamScreenState extends State<PickTeamScreen> {
  bool _isClaiming = false;

  void _claimTeam(Team team) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isClaiming = true);

    try {
      final firebaseService = context.read<FirebaseService>();
      await firebaseService.claimTeam(user.uid, team.id, user.email ?? '');
      await NotificationService.saveTokenToFirestore(user.uid);

      if (mounted) {
        // Clear routes and go to home
        while (context.canPop()) {
          context.pop();
        }
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to claim team: $e')));
      }
      setState(() => _isClaiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allTeams = context.watch<List<Team>>();

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: Text(
          'CLAIM YOUR TEAM',
          style: TextStyle(
            fontSize: Responsive.sp(context, 18),
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: AppTheme.primaryPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false, // Force them to stay if required
      ),
      body: Stack(
        children: [
          const LineDecoration(opacity: 0.05),

          if (allTeams.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.sentiment_dissatisfied,
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No teams available to claim.",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryPurple,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "The admin might need to create more teams or reset the season.",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 250,
                childAspectRatio: 0.85,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: allTeams.length,
              itemBuilder: (context, index) {
                final team = allTeams[index];
                return _buildTeamCard(team);
              },
            ),

          if (_isClaiming)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.accentGreen),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTeamCard(Team team) {
    bool isClaimed = team.playerId != null;

    return Card(
      elevation: isClaimed ? 0 : 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isClaimed ? null : () => _showClaimDialog(team),
        child: Opacity(
          opacity: isClaimed ? 0.6 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  isClaimed ? Colors.grey.shade200 : Colors.white,
                  isClaimed ? Colors.grey.shade300 : Colors.grey.shade50,
                ],
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: Responsive.sp(context, 70),
                        height: Responsive.sp(context, 70),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(10),
                        child: TeamLogo(
                          logoData: team.logoUrl,
                          size: Responsive.sp(context, 50),
                        ),
                      ),
                      SizedBox(height: Responsive.sp(context, 12)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          team.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: Responsive.sp(context, 16),
                            color: AppTheme.primaryPurple,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        team.managerName,
                        style: TextStyle(
                          fontSize: Responsive.sp(context, 10),
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      if (isClaimed) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            "ALREADY SELECTED",
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.red.shade800,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isClaimed)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Icon(
                      Icons.lock,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showClaimDialog(Team team) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Confirm if this is your team",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryPurple,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              padding: const EdgeInsets.all(8),
              child: TeamLogo(logoData: team.logoUrl),
            ),
            const SizedBox(height: 16),
            Text(
              "Team: ${team.name}\nManager: ${team.managerName}",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            const Text(
              "Once confirmed, your account will be linked to this team automatically.",
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              "CANCEL",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGreen,
              foregroundColor: AppTheme.primaryPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _claimTeam(team);
            },
            child: Text(
              "CONTINUE",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
