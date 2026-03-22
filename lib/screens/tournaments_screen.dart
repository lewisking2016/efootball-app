import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../data/firebase_service.dart';
import '../models/tournament_model.dart';

import 'matches_screen.dart';

class TournamentsScreen extends StatelessWidget {
  const TournamentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService = context.read<FirebaseService>();
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<bool>(
      future: firebaseService.isAdmin(user?.uid ?? ''),
      builder: (context, adminSnapshot) {
        final isAdmin = adminSnapshot.data ?? false;

        return Scaffold(
          backgroundColor: AppTheme.cardColorLight,
          appBar: AppBar(
            title: const Text("Tournaments", style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: AppTheme.primaryPurple,
            foregroundColor: Colors.white,
            actions: isAdmin ? [
              IconButton(
                onPressed: () => context.push('/join-tournament'),
                icon: const Icon(Icons.group_add_outlined),
                tooltip: "Join Tournament",
              ),
              IconButton(
                onPressed: () => context.push('/create-tournament'),
                icon: const Icon(Icons.add_circle_outline),
                tooltip: "Create Tournament",
              ),
            ] : null,
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
                      if (isAdmin) ...[
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => context.push('/create-tournament'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple, foregroundColor: Colors.white),
                          child: const Text("Create Your First Tournament"),
                        ),
                      ],
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
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
                  image: DecorationImage(
                    image: AssetImage('assets/tournaments/${t.type == TournamentType.epl ? 'epl' : 'champions_league'}.png'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.3), BlendMode.darken),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MatchesMainScreen(tournamentId: t.id),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  t.name.toUpperCase(), 
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 24, color: Colors.white, letterSpacing: 1),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: AppTheme.accentGreen, borderRadius: BorderRadius.circular(6)),
                                  child: const Text("LIVE", style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(6)),
                                  child: const Text("FINISHED", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              const Icon(Icons.public, color: Colors.white70, size: 16),
                              const SizedBox(width: 6),
                              Text(t.region.toUpperCase(), style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 0.5)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                ),
                                child: Text("VIEW MATCHES", style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
            },
          ),
        );
      },
    );
  }
}
