import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../data/firebase_service.dart';
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
    final teamMap = {for (var t in allTeams) t.id: t};

    return StreamBuilder<List<model.Match>>(
      stream: firebaseService.getMatches(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final results = snapshot.data!
            .where((m) => m.tournamentId.trim() == tournamentId.trim() && (m.status == 'FT' || m.status == 'Finished'))
            .toList();
        
        // SORT: Latest results first
        results.sort((a, b) => b.date.compareTo(a.date));

        if (results.isEmpty) {
          return Center(
            child: Text("No results found for this tournament.", style: GoogleFonts.outfit(color: Colors.grey)),
          );
        }

        return FutureBuilder<bool>(
          future: firebaseService.isAdmin(FirebaseAuth.instance.currentUser?.uid ?? ''),
          builder: (context, adminSnapshot) {
            final isAdmin = adminSnapshot.data ?? false;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final match = results[index];
                final home = teamMap[match.homeTeamId];
                final away = teamMap[match.awayTeamId];

                Widget card = _buildResultCard(match, home, away);
                
                if (isAdmin) {
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
          }
        );
      },
    );
  }

  Widget _buildResultCard(model.Match match, Team? home, Team? away) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              DateFormat('EEE d MMM').format(match.date).toUpperCase(),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(home?.name ?? 'TBD', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      TeamLogo(logoData: home?.logoUrl ?? '', size: 24),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.primaryPurple, borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    "${match.homeScore} - ${match.awayScore}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      TeamLogo(logoData: away?.logoUrl ?? '', size: 24),
                      const SizedBox(width: 8),
                      Text(away?.name ?? 'TBD', style: const TextStyle(fontWeight: FontWeight.bold)),
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
