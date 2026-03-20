import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../data/firebase_service.dart';
import '../../models/match_model.dart';
import '../../models/team_model.dart';
import '../../widgets/team_logo.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class FixturesListView extends StatelessWidget {
  const FixturesListView({super.key});

  Widget _buildFilterChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.primaryPurple, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          const Icon(Icons.keyboard_arrow_down, size: 16, color: AppTheme.primaryPurple),
        ],
      ),
    );
  }

  Widget _buildMatchRow(Match match, Map<String, Team> teamMap) {
    // Lookup teams
    final homeTeam = teamMap[match.homeTeamId] ?? Team(id: match.homeTeamId, name: 'TBD', shortName: 'TBD', logoUrl: '', managerId: '', managerName: 'TBD');
    final awayTeam = teamMap[match.awayTeamId] ?? Team(id: match.awayTeamId, name: 'TBD', shortName: 'TBD', logoUrl: '', managerId: '', managerName: 'TBD');
    final score = "${match.homeScore} - ${match.awayScore}";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Home Team
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    homeTeam.name,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.primaryPurple),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 12),
                TeamLogo(logoData: homeTeam.logoUrl, size: 32),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Score Box
          Column(
            children: [
              Container(
                width: 70,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade200, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                  ],
                ),
                child: Center(
                  child: Text(
                    score,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.primaryPurple),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                match.status,
                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ],
          ),
          
          const SizedBox(width: 16),
          
          // Away Team
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                TeamLogo(logoData: awayTeam.logoUrl, size: 32),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    awayTeam.name,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.primaryPurple),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    
    // Listen to all teams for lookup
    final allTeams = context.watch<List<Team>>();
    final teamMap = {for (var t in allTeams) t.id: t};
    final firebaseService = context.read<FirebaseService>();

    return Container(
      color: AppTheme.lightBackground,
      child: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000),
            padding: EdgeInsets.all(isTablet ? 32.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Premier League 2025/26'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Matchweek 1'),
                      const SizedBox(width: 8),
                      _buildFilterChip('All Clubs'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Navigator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildNavButton(Icons.chevron_left),
                    const SizedBox(width: 32),
                    Column(
                      children: [
                        Text(
                          "MATCHWEEK 1",
                          style: GoogleFonts.outfit(
                            fontSize: 20, 
                            fontWeight: FontWeight.w900, 
                            color: AppTheme.primaryPurple,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Fri 14 Aug - Sun 16 Aug 2026", 
                          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(width: 32),
                    _buildNavButton(Icons.chevron_right),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Firebase Live Matches Stream
                StreamBuilder<List<Match>>(
                  stream: firebaseService.getMatches(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Column(
                          children: List.generate(4, (index) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Container(
                              height: 80.0,
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                            ),
                          )),
                        ),
                      );
                    }
                    
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Text(
                            "The 2025/26 Season kicks off soon!", 
                            style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }

                    final matches = snapshot.data!;
                    final formattedDate = DateFormat('EEEE d MMMM yyyy').format(matches.first.date);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            formattedDate.toUpperCase(), 
                            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.primaryPurple, letterSpacing: 1.2),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ...matches.map((match) => Column(
                          children: [
                            _buildMatchRow(match, teamMap),
                            Divider(color: Colors.grey.withOpacity(0.1), height: 1),
                          ],
                        )),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Icon(icon, color: AppTheme.primaryPurple, size: 28),
    );
  }
}
