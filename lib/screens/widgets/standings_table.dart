import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/standings_model.dart';
import '../../models/team_model.dart';
import '../../widgets/team_logo.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';

class StandingsTableView extends StatefulWidget {
  const StandingsTableView({super.key});

  @override
  State<StandingsTableView> createState() => _StandingsTableViewState();
}

class _StandingsTableViewState extends State<StandingsTableView> {
  String _currentTab = 'Full'; // Short, Full, Form

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

  Widget _buildTypeToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.primaryPurple.withOpacity(0.05),
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
                      ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))]
                      : [],
                ),
                child: Center(
                  child: Text(
                    type,
                    style: TextStyle(
                      color: isSelected ? AppTheme.primaryPurple : Colors.grey.shade600,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                      fontSize: 14,
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
    if (result == 'W') bgColor = AppTheme.accentGreen;
    else if (result == 'L') bgColor = Colors.red;
    else bgColor = Colors.grey.shade300;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 20,
      height: 20,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Center(
        child: Text(result, style: TextStyle(color: result == 'D' ? Colors.black : Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final standings = context.watch<List<StandingsEntry>>();
    final allTeams = context.watch<List<Team>>();

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

    // Sort standings by position
    final sortedStandings = List<StandingsEntry>.from(standings);
    sortedStandings.sort((a, b) => a.position.compareTo(b.position));

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
                      "PREMIER LEAGUE 2025/26",
                      style: GoogleFonts.outfit(
                        fontSize: isTablet ? 24 : 18, 
                        fontWeight: FontWeight.w900, 
                        color: AppTheme.primaryPurple,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All Matchweeks'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Home & Away'),
                          const SizedBox(width: 16),
                          Text(
                            "Reset", 
                            style: GoogleFonts.inter(color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
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
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
                  ] : [],
                ),
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                columnSpacing: 18,
                horizontalMargin: 16,
                headingTextStyle: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                dataTextStyle: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textColorLight, fontSize: 14),
                showCheckboxColumn: false,
                headingRowColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) => Colors.grey.shade50),
                headingRowHeight: 48,
                dataRowHeight: 64,
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
                                Text(team.name, style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: AppTheme.primaryPurple, fontSize: 16)),
                                Text(
                                  team.managerName.toUpperCase(), 
                                  style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w900, letterSpacing: 1),
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
