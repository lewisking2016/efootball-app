import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../data/firebase_service.dart';
import '../../models/match_model.dart';
import '../../models/tournament_model.dart';
import '../../models/team_model.dart';
import '../../widgets/team_logo.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../submission_screen.dart';

class FixturesListView extends StatefulWidget {
  final String tournamentId;
  final ValueChanged<String>? onTournamentChanged;
  const FixturesListView({super.key, required this.tournamentId, this.onTournamentChanged});

  @override
  State<FixturesListView> createState() => _FixturesListViewState();
}

class _FixturesListViewState extends State<FixturesListView> {
  String _selectedMatchweek = '1';
  String _selectedTeamId = 'all';

  Widget _buildFilterChip({
    required String label,
    required List<DropdownMenuItem<String>> items,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: AppTheme.primaryPurple),
          style: GoogleFonts.outfit(color: AppTheme.primaryPurple, fontSize: 13, fontWeight: FontWeight.w600),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildMatchRow(BuildContext context, Match match, Map<String, Team> teamMap) {
    // Lookup teams
    final homeTeam = teamMap[match.homeTeamId] ?? Team(id: match.homeTeamId, name: 'TBD', shortName: 'TBD', logoUrl: '', managerId: '', managerName: 'TBD');
    final awayTeam = teamMap[match.awayTeamId] ?? Team(id: match.awayTeamId, name: 'TBD', shortName: 'TBD', logoUrl: '', managerId: '', managerName: 'TBD');
    
    String centerDisplay;
    double centerFontSize = 18;
    if (match.status == 'FT' && match.homeScore != null && match.awayScore != null) {
      centerDisplay = "${match.homeScore} - ${match.awayScore}";
    } else {
      centerDisplay = DateFormat('EEE\nd MMM').format(match.date);
      centerFontSize = 12; // Smaller font for dates
    }

    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => MatchSubmissionScreen(match: match)));
      },
      child: Padding(
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
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))
                    ],
                  ),
                  child: Center(
                    child: Text(
                      centerDisplay,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: centerFontSize, color: AppTheme.primaryPurple, height: 1.2),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    
    // Listen to all teams for lookup
    final allTeams = context.watch<List<Team>>();
    final tournaments = context.watch<List<Tournament>>();
    final teamMap = {for (var t in allTeams) t.id: t};
    final firebaseService = context.read<FirebaseService>();

    final selectedTournament = tournaments.firstWhere((t) => t.id == widget.tournamentId, orElse: () => tournaments.first);

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
                      _buildFilterChip(
                        label: selectedTournament.name,
                        value: widget.tournamentId,
                        items: tournaments.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                        onChanged: (val) {
                          if (val != null && widget.onTournamentChanged != null) {
                            widget.onTournamentChanged!(val);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: "Matchweek $_selectedMatchweek",
                        value: _selectedMatchweek,
                        items: List.generate(38, (i) => (i + 1).toString())
                            .map((mw) => DropdownMenuItem(value: mw, child: Text("MW $mw")))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedMatchweek = val);
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: _selectedTeamId == 'all' ? "All Clubs" : (teamMap[_selectedTeamId]?.name ?? "All Clubs"),
                        value: _selectedTeamId,
                        items: [
                          const DropdownMenuItem(value: 'all', child: Text("All Clubs")),
                          ...allTeams.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedTeamId = val);
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Navigator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildNavButton(Icons.chevron_left, () {
                      int current = int.parse(_selectedMatchweek);
                      if (current > 1) {
                        setState(() => _selectedMatchweek = (current - 1).toString());
                      }
                    }),
                    const SizedBox(width: 32),
                    Column(
                      children: [
                        Text(
                          "MATCHWEEK $_selectedMatchweek",
                          style: GoogleFonts.outfit(
                            fontSize: 20, 
                            fontWeight: FontWeight.w900, 
                            color: AppTheme.primaryPurple,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "2025/26 Season", // Dynamic date range could be complex, keeping it simple
                          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(width: 32),
                    _buildNavButton(Icons.chevron_right, () {
                      int current = int.parse(_selectedMatchweek);
                      if (current < 38) {
                        setState(() => _selectedMatchweek = (current + 1).toString());
                      }
                    }),
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

                    final matches = snapshot.data!.where((m) {
                      bool matchesTournament = m.tournamentId == widget.tournamentId;
                      bool matchesMW = m.matchweek == _selectedMatchweek;
                      bool matchesTeam = _selectedTeamId == 'all' || 
                                       m.homeTeamId == _selectedTeamId || 
                                       m.awayTeamId == _selectedTeamId;
                      bool isPending = m.status == 'Pending';
                      
                      return matchesTournament && matchesMW && matchesTeam && isPending;
                    }).toList();
                    if (matches.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Text(
                            "No upcoming fixtures for this tournament.", 
                            style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }

                    // Group matches by date
                    final Map<String, List<Match>> groupedMatches = {};
                    for (var m in matches) {
                      final dateKey = DateFormat('EEEE d MMMM yyyy').format(m.date);
                      groupedMatches.putIfAbsent(dateKey, () => []).add(m);
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: groupedMatches.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.fromLTRB(4, 24, 0, 12),
                              child: Text(
                                entry.key.toUpperCase(),
                                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.primaryPurple, letterSpacing: 1.2),
                              ),
                            ),
                            ...entry.value.map((match) => Column(
                              children: [
                                _buildMatchRow(context, match, teamMap),
                                Divider(color: Colors.grey.withValues(alpha: 0.1), height: 1),
                              ],
                            )),
                          ],
                        );
                      }).toList(),
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

  Widget _buildNavButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Icon(icon, color: AppTheme.primaryPurple, size: 28),
      ),
    );
  }
}
