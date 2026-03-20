import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../data/firebase_service.dart';
import '../models/tournament_model.dart';

class TournamentsScreen extends StatelessWidget {
  const TournamentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService = context.read<FirebaseService>();

    return Scaffold(
      backgroundColor: AppTheme.cardColorLight,
      appBar: AppBar(
        title: const Text("Tournaments", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => context.push('/create-tournament'),
            icon: const Icon(Icons.add_circle_outline),
            tooltip: "Create Tournament",
          ),
        ],
      ),
      body: StreamBuilder<List<Tournament>>(
        stream: firebaseService.getTournaments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple));
          }
          
          final tournaments = snapshot.data ?? [];
          
          if (tournaments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text("No tournaments yet", style: TextStyle(color: Colors.grey.shade600, fontSize: 18)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => context.push('/create-tournament'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple, foregroundColor: Colors.white),
                    child: const Text("Create Your First Tournament"),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tournaments.length,
            itemBuilder: (context, index) {
              final t = tournaments[index];
              final isActive = t.active;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 60,
                    height: 60,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColorLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Hero(
                      tag: 'tourn_${t.id}',
                      child: Image.asset(
                        'assets/tournaments/${t.type == TournamentType.epl ? 'epl' : 'champions_league'}.png',
                        errorBuilder: (_, __, ___) => const Icon(Icons.emoji_events, color: AppTheme.primaryPurple, size: 32),
                      ),
                    ),
                  ),
                  title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryPurple)),
                  subtitle: Text("${t.region} • ${t.type == TournamentType.epl ? 'League' : 'UEFA Cup'}", style: TextStyle(color: Colors.grey.shade600)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppTheme.accentGreen.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                          child: const Text("LIVE", style: TextStyle(color: AppTheme.primaryPurple, fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                      else
                        const Text("Finished", style: TextStyle(fontSize: 10, color: Colors.grey)),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                  onTap: () {
                    // Navigate to specific tournament view if needed
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
