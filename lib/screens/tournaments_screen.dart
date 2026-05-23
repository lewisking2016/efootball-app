import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../data/firebase_service.dart';
import '../models/app_user_model.dart';
import '../models/match_model.dart';
import '../models/team_model.dart';
import '../models/tournament_model.dart';
import '../theme/app_theme.dart';

class TournamentsScreen extends StatelessWidget {
  const TournamentsScreen({super.key});

  Future<_LeagueAccess> _loadAccess(
    FirebaseService firebaseService,
    String uid,
  ) async {
    final profile = uid.isEmpty
        ? null
        : await firebaseService.getUserProfile(uid);
    final isAdmin = uid.isNotEmpty && await firebaseService.isAdmin(uid);
    return _LeagueAccess(profile: profile, isAdmin: isAdmin);
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = context.read<FirebaseService>();
    final user = FirebaseAuth.instance.currentUser;
    final tournaments = context.watch<List<Tournament>>();
    final teams = context.watch<List<Team>>();
    final matches = context.watch<List<Match>>();

    return FutureBuilder<_LeagueAccess>(
      future: _loadAccess(firebaseService, user?.uid ?? ''),
      builder: (context, accessSnapshot) {
        final access = accessSnapshot.data ?? const _LeagueAccess();
        final linkedTeam = teams
            .where((team) => team.id == access.profile?.teamId)
            .firstOrNull;

        return Scaffold(
          backgroundColor: AppTheme.lightBackground,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 210,
                backgroundColor: AppTheme.primaryPurple,
                foregroundColor: Colors.white,
                actions: [
                  if (access.isAdmin)
                    IconButton(
                      onPressed: () => context.push('/create-tournament'),
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: "Create League",
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: AppTheme.headerGradient,
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              "Leagues",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              linkedTeam == null
                                  ? "Choose a league, then claim the team you will manage."
                                  : "Managing ${linkedTeam.name}. Enter your league and update your fixtures.",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.78),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _StatusPill(
                              icon: access.isAdmin
                                  ? Icons.admin_panel_settings
                                  : Icons.shield_outlined,
                              label: access.isAdmin
                                  ? "ADMIN CONTROL"
                                  : (linkedTeam == null
                                        ? "TEAM NOT CLAIMED"
                                        : linkedTeam.shortName),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (tournaments.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyLeaguesState(isAdmin: access.isAdmin),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList.builder(
                    itemCount: tournaments.length,
                    itemBuilder: (context, index) {
                      final tournament = tournaments[index];
                      final tournamentTeams = teams
                          .where((team) => team.tournamentId == tournament.id)
                          .toList();
                      final tournamentMatches = matches
                          .where((match) => match.tournamentId == tournament.id)
                          .toList();
                      final completedMatches = tournamentMatches
                          .where(
                            (match) =>
                                match.status == 'FT' ||
                                match.status == 'Finished',
                          )
                          .length;
                      final canClaimHere =
                          !access.isAdmin && linkedTeam == null;
                      final isLinkedLeague =
                          linkedTeam?.tournamentId == tournament.id;

                      return _LeagueCard(
                        tournament: tournament,
                        teamCount: tournamentTeams.length,
                        matchCount: tournamentMatches.length,
                        completedMatches: completedMatches,
                        isAdmin: access.isAdmin,
                        isLinkedLeague: isLinkedLeague,
                        actionLabel: canClaimHere
                            ? "SELECT TEAM"
                            : "ENTER LEAGUE",
                        onTap: () {
                          if (canClaimHere) {
                            context.push(
                              '/join-tournament?tournamentId=${tournament.id}',
                            );
                          } else {
                            context.push('/league/${tournament.id}');
                          }
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _LeagueAccess {
  final AppUser? profile;
  final bool isAdmin;

  const _LeagueAccess({this.profile, this.isAdmin = false});
}

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatusPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.accentGreen, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLeaguesState extends StatelessWidget {
  final bool isAdmin;

  const _EmptyLeaguesState({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 72,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 18),
            Text(
              "No leagues yet",
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isAdmin
                  ? "Create the first league to begin the season."
                  : "An admin needs to create a league first.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isAdmin) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.push('/create-tournament'),
                icon: const Icon(Icons.add),
                label: const Text("Create League"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LeagueCard extends StatelessWidget {
  final Tournament tournament;
  final int teamCount;
  final int matchCount;
  final int completedMatches;
  final bool isAdmin;
  final bool isLinkedLeague;
  final String actionLabel;
  final VoidCallback onTap;

  const _LeagueCard({
    required this.tournament,
    required this.teamCount,
    required this.matchCount,
    required this.completedMatches,
    required this.isAdmin,
    required this.isLinkedLeague,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = matchCount == 0 ? 0.0 : completedMatches / matchCount;
    final imageName = tournament.type == TournamentType.epl
        ? 'epl'
        : 'champions_league';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 132,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/tournaments/$imageName.png'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      AppTheme.primaryPurple.withValues(alpha: 0.42),
                      BlendMode.darken,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tournament.name.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 23,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          if (isLinkedLeague || isAdmin)
                            _MiniBadge(
                              label: isAdmin ? "ADMIN" : "YOUR LEAGUE",
                            ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        tournament.region.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _Metric(
                          icon: Icons.groups_2_outlined,
                          label: "$teamCount teams",
                        ),
                        const SizedBox(width: 14),
                        _Metric(
                          icon: Icons.sports_soccer,
                          label: "$matchCount fixtures",
                        ),
                        const Spacer(),
                        Text(
                          actionLabel,
                          style: TextStyle(
                            color: AppTheme.primaryPurple,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: AppTheme.primaryPurple,
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0, 1),
                        minHeight: 7,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.accentGreen,
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
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;

  const _MiniBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.accentGreen,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppTheme.primaryPurple,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Metric({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.grey.shade500, size: 17),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
