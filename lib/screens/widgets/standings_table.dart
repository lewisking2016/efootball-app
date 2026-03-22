import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/standings_model.dart';
import '../../models/team_model.dart';
import '../../models/tournament_model.dart';
import '../../widgets/team_logo.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';

class StandingsTableView extends StatefulWidget {
  final String tournamentId;
  const StandingsTableView({super.key, required this.tournamentId});

  @override
  State<StandingsTableView> createState() => _StandingsTableViewState();
}

class _StandingsTableViewState extends State<StandingsTableView> {
  String _currentTab = 'Full'; // Short, Full, Form

  Widget _buildTypeToggle() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: Responsive.sp(context, 20)),
      height: Responsive.sp(context, 48),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.primaryPurple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: ['Short', 'Full', 'Form'].map((type) {
          final isSelected = _currentTab == type;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _currentTab = type),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))]
                      : [],
                ),
                child: Center(
                  child: Text(
                    type,
                    style: TextStyle(
                      color: isSelected ? AppTheme.primaryPurple : Colors.grey.shade600,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                      fontSize: Responsive.sp(context, 14),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFormIcon(String result) {
    Color bgColor;
    if (result == 'W') { bgColor = AppTheme.accentGreen; }
    else if (result == 'L') { bgColor = Colors.red; }
    else { bgColor = Colors.grey.shade300; }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: Responsive.sp(context, 20),
      height: Responsive.sp(context, 20),
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Center(
        child: Text(result, style: TextStyle(color: result == 'D' ? Colors.black : Colors.white, fontSize: Responsive.sp(context, 10), fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTrajectoryIcon(int prev, int current) {
    if (prev == 0) return const SizedBox();
    if (current < prev) return const Icon(Icons.arrow_drop_up, color: Colors.green, size: 20);
    if (current > prev) return const Icon(Icons.arrow_drop_down, color: Colors.red, size: 20);
    return Icon(Icons.remove, color: Colors.grey.shade400, size: 16);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final standings = context.watch<List<StandingsEntry>>();
    final allTeams = context.watch<List<Team>>();

    final tournaments = context.watch<List<Tournament>>();
    final selectedTournament = tournaments.firstWhere((t) => t.id == widget.tournamentId, orElse: () => Tournament(id: '', name: 'Loading...', region: '', type: TournamentType.epl, createdAt: DateTime.now()));

    // Create a map of teams for quick lookup
    final Map<String, Team> teamMap = {for (var t in allTeams) t.id: t};

    if (standings.isEmpty || allTeams.isEmpty) {
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: ListView.builder(
          itemCount: 15,
          shrinkWrap: true,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              height: 56.0,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      );
    }

    // Filter and Sort standings
    final sortedStandings = standings
        .where((s) => s.tournamentId == widget.tournamentId)
        .toList();
        
    sortedStandings.sort((a, b) {
      if (b.points != a.points) return b.points.compareTo(a.points);
      if (b.goalDifference != a.goalDifference) return b.goalDifference.compareTo(a.goalDifference);
      return b.goalsFor.compareTo(a.goalsFor);
    });

    return Container(
      color: AppTheme.lightBackground,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1000),
                padding: EdgeInsets.all(isTablet ? 32.0 : 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedTournament.name.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: Responsive.sp(context, 18), 
                        fontWeight: FontWeight.w900, 
                        color: AppTheme.primaryPurple,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTypeToggle(),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1000),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: isTablet ? BorderRadius.circular(20) : BorderRadius.zero,
                  boxShadow: isTablet ? [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))
                  ] : [],
                ),
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                columnSpacing: Responsive.sp(context, 18),
                horizontalMargin: 16,
                headingTextStyle: TextStyle(color: Colors.grey.shade700, fontSize: Responsive.sp(context, 12), fontWeight: FontWeight.w900, letterSpacing: 0.5),
                dataTextStyle: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textColorLight, fontSize: Responsive.sp(context, 13)),
                showCheckboxColumn: false,
                headingRowColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) => Colors.grey.shade50),
                headingRowHeight: 48,
                dataRowMinHeight: 64,
                dataRowMaxHeight: 64,
                columns: [
                  const DataColumn(label: Text('Pos')),
                  const DataColumn(label: Text('Team')),
                  if (_currentTab != 'Form') ...[
                    const DataColumn(label: Text('PL')),
                    const DataColumn(label: Text('W')),
                    const DataColumn(label: Text('D')),
                    const DataColumn(label: Text('L')),
                    if (_currentTab == 'Full') ...[
                      const DataColumn(label: Text('GF')),
                      const DataColumn(label: Text('GA')),
                      const DataColumn(label: Text('GD')),
                      const DataColumn(label: Text('Pts')),
                    ]
                  ],
                  if (_currentTab == 'Form')
                    const DataColumn(label: Text('Form')),
                ],
                rows: sortedStandings.asMap().entries.map((entry) {
                  final int index = entry.key;
                  final StandingsEntry standing = entry.value;
                  final int pos = index + 1;
                  
                  // Get actual team data
                  final Team team = teamMap[standing.teamId] ?? Team(
                    id: standing.teamId, 
                    name: 'Unknown', 
                    shortName: 'UNK', 
                    logoUrl: '', 
                    managerId: '',
                    managerName: 'Unknown',
                  );

                  return DataRow(
                    onSelectChanged: (selected) {
                      if (selected != null && selected) {
                        context.push('/team/${standing.teamId}');
                      }
                    },
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            Container(
                              width: 3,
                              height: 20,
                              color: pos <= 4 ? Colors.blue.shade700 : (pos == 5 ? Colors.orange : Colors.transparent),
                            ),
                            const SizedBox(width: 8),
                            Text(pos.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                            _buildTrajectoryIcon(standing.previousPosition, pos),
                          ],
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            TeamLogo(logoData: team.logoUrl, size: 32),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                 Text(team.name, style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: AppTheme.primaryPurple, fontSize: Responsive.sp(context, 15))),
                                 Text(
                                   team.managerName.toUpperCase(), 
                                   style: GoogleFonts.inter(fontSize: Responsive.sp(context, 9), color: Colors.grey.shade500, fontWeight: FontWeight.w900, letterSpacing: 1),
                                 ),
                               ],
                            ),
                          ],
                        ),
                      ),
                      if (_currentTab != 'Form') ...[
                        DataCell(Text(standing.played.toString(), style: const TextStyle(fontWeight: FontWeight.normal))),
                        DataCell(Text(standing.won.toString(), style: const TextStyle(fontWeight: FontWeight.normal))),
                        DataCell(Text(standing.drawn.toString(), style: const TextStyle(fontWeight: FontWeight.normal))),
                        DataCell(Text(standing.lost.toString(), style: const TextStyle(fontWeight: FontWeight.normal))),
                        if (_currentTab == 'Full') ...[
                          DataCell(Text(standing.goalsFor.toString(), style: const TextStyle(fontWeight: FontWeight.normal))),
                          DataCell(Text(standing.goalsAgainst.toString(), style: const TextStyle(fontWeight: FontWeight.normal))),
                          DataCell(Text(standing.goalDifference.toString(), style: const TextStyle(fontWeight: FontWeight.normal))),
                          DataCell(Text(standing.points.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                        ]
                      ],
                      if (_currentTab == 'Form')
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: standing.form.map((result) => _buildFormIcon(result)).toList(),
                          ),
                        ),
                    ],
                  );
                 }).toList(),
               ),
             ),
           ),
         ),
       ),
     ],
   ),
 );
}
}
