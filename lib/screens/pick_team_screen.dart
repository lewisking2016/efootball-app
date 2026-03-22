import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to claim team: $e')),
        );
      }
      setState(() => _isClaiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teams = context.watch<List<Team>>();
    final availableTeams = teams.where((t) => t.playerId == null).toList();

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: Text('CLAIM YOUR TEAM', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        backgroundColor: AppTheme.primaryPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const LineDecoration(opacity: 0.05),
          
          if (availableTeams.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sentiment_dissatisfied, size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      "No teams available to claim.",
                      style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "The admin might need to create more teams or reset the season.",
                      style: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade600),
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
              itemCount: availableTeams.length,
              itemBuilder: (context, index) {
                final team = availableTeams[index];
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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showClaimDialog(team),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey.shade50],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                ),
                padding: const EdgeInsets.all(12),
                child: TeamLogo(
                  logoData: team.logoUrl,
                  size: 60,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  team.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryPurple),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  "Assigned to: ${team.managerName}",
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClaimDialog(Team team) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Claim ${team.name}?"),
        content: Text("Are you sure you want to claim ${team.name}? You will only be able to submit scores for this team."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _claimTeam(team);
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }
}
