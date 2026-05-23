import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../data/firebase_service.dart';
import '../data/notification_service.dart';
import '../models/team_model.dart';
import '../models/tournament_model.dart';
import '../theme/app_theme.dart';
import '../widgets/team_logo.dart';

class JoinTournamentScreen extends StatefulWidget {
  final String? initialTournamentId;

  const JoinTournamentScreen({super.key, this.initialTournamentId});

  @override
  State<JoinTournamentScreen> createState() => _JoinTournamentScreenState();
}

class _JoinTournamentScreenState extends State<JoinTournamentScreen> {
  String? _selectedTournamentId;
  bool _isClaiming = false;

  @override
  void initState() {
    super.initState();
    _selectedTournamentId = widget.initialTournamentId;
  }

  Future<void> _claimTeam(Team team) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isClaiming = true);

    try {
      final firebaseService = context.read<FirebaseService>();
      await firebaseService.claimTeam(user.uid, team.id, user.email ?? '');
      await NotificationService.saveTokenToFirestore(user.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${team.name} linked to your account.")),
        );
        context.go('/league/${team.tournamentId}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isClaiming = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allTeams = context.watch<List<Team>>();
    final tournaments = context.watch<List<Tournament>>();
    final selectedTeams =
        _selectedTournamentId == null
              ? <Team>[]
              : allTeams
                    .where((team) => team.tournamentId == _selectedTournamentId)
                    .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text(
          "Join League",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryPurple,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            } else {
              context.go('/login');
            }
          },
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                _selectedTournamentId == null
                    ? "Choose your league"
                    : "Claim your team",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryPurple,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedTournamentId == null
                    ? "Start by selecting the league you will play in. After that, choose the team you will manage."
                    : "Pick the club you will manage in this league. You will only submit and edit results for this team.",
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              if (widget.initialTournamentId == null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedTournamentId,
                      hint: const Text("Select League"),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                      isExpanded: true,
                      items: tournaments
                          .map(
                            (t) => DropdownMenuItem(
                              value: t.id,
                              child: Text(
                                t.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedTournamentId = value),
                    ),
                  ),
                ),
              if (widget.initialTournamentId != null)
                _buildSelectedLeagueBanner(tournaments),
              const SizedBox(height: 24),
              if (_selectedTournamentId == null)
                _buildMessageCard(
                  icon: Icons.emoji_events_outlined,
                  message: "Pick a league to see the available EPL teams.",
                )
              else if (selectedTeams.isEmpty)
                _buildMessageCard(
                  icon: Icons.sentiment_dissatisfied_outlined,
                  message: "No teams were found in this league yet.",
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 240,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: selectedTeams.length,
                  itemBuilder: (context, index) =>
                      _buildTeamCard(selectedTeams[index]),
                ),
            ],
          ),
          if (_isClaiming)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.accentGreen),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedLeagueBanner(List<Tournament> tournaments) {
    final tournament = tournaments
        .where((t) => t.id == _selectedTournamentId)
        .firstOrNull;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryPurple,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: AppTheme.accentGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tournament?.name.toUpperCase() ?? "SELECTED LEAGUE",
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard({required IconData icon, required String message}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: AppTheme.primaryPurple.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCard(Team team) {
    final isClaimed = team.playerId != null;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 12),
            child: child,
          ),
        );
      },
      child: Card(
        elevation: isClaimed ? 0 : 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isClaimed ? null : () => _showClaimDialog(team),
          child: Opacity(
            opacity: isClaimed ? 0.55 : 1,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    isClaimed ? Colors.grey.shade200 : const Color(0xFFF7F8FF),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -10,
                    top: -10,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryPurple.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: 76,
                          height: 76,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryPurple.withValues(
                                  alpha: isClaimed ? 0.06 : 0.14,
                                ),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: TeamLogo(logoData: team.logoUrl, size: 52),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          team.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            color: AppTheme.primaryPurple,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          team.managerName,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isClaimed
                                ? Colors.red.withValues(alpha: 0.1)
                                : AppTheme.accentGreen.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            isClaimed ? "ALREADY LINKED" : "LINK THIS TEAM",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: isClaimed
                                  ? Colors.red.shade800
                                  : AppTheme.primaryPurple,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showClaimDialog(Team team) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Link this team?",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryPurple,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: TeamLogo(logoData: team.logoUrl),
            ),
            const SizedBox(height: 16),
            Text(
              "${team.name}\nManager: ${team.managerName}",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            const Text(
              "Your account will use this club and logo across the league.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
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
              Navigator.of(dialogContext).pop();
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
