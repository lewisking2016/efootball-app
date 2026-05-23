import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../data/firebase_service.dart';
import '../../models/app_user_model.dart';
import '../../models/match_model.dart' as model;
import '../../models/team_model.dart';
import '../../widgets/team_logo.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../submission_screen.dart';

class ResultsListView extends StatelessWidget {
  final String tournamentId;
  const ResultsListView({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context) {
    final firebaseService = context.read<FirebaseService>();
    final allTeams = context.watch<List<Team>>();
    final allMatches = context.watch<List<model.Match>>();
    final teamMap = {for (var t in allTeams) t.id: t};

    final results = allMatches
        .where(
          (m) =>
              m.tournamentId.trim() == tournamentId.trim() &&
              (m.status == 'FT' || m.status == 'Finished'),
        )
        .toList();

    // SORT: Latest results first
    results.sort((a, b) => b.date.compareTo(a.date));

    if (results.isEmpty) {
      return Center(
        child: Text(
          "No results found for this tournament.",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return FutureBuilder<AppUser?>(
      future: firebaseService.getUserProfile(
        FirebaseAuth.instance.currentUser?.uid ?? '',
      ),
      builder: (context, profileSnapshot) {
        final profile = profileSnapshot.data;
        final isAdmin = profile?.isAdmin ?? false;
        final userTeamId = profile?.teamId;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final match = results[index];
            final home = teamMap[match.homeTeamId];
            final away = teamMap[match.awayTeamId];
            final animationDelay = index * 40 > 240 ? 240 : index * 40;

            Widget card = TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 260 + animationDelay),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * 16),
                    child: child,
                  ),
                );
              },
              child: _buildResultCard(context, match, home, away),
            );

            final canEdit =
                isAdmin ||
                match.homeTeamId == userTeamId ||
                match.awayTeamId == userTeamId;

            if (canEdit) {
              return InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MatchSubmissionScreen(match: match),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: card,
              );
            }

            return card;
          },
        );
      },
    );
  }

  Widget _buildResultCard(
    BuildContext context,
    model.Match match,
    Team? home,
    Team? away,
  ) {
    final isCompact = MediaQuery.of(context).size.width < 380;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              DateFormat('EEE d MMM').format(match.date).toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          home?.name ?? 'TBD',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TeamLogo(logoData: home?.logoUrl ?? '', size: 24),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 16),
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 10 : 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "${match.homeScore} - ${match.awayScore}",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isCompact ? 14 : 16,
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      TeamLogo(logoData: away?.logoUrl ?? '', size: 24),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          away?.name ?? 'TBD',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
