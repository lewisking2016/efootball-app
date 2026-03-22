import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../models/team_model.dart';
import '../models/standings_model.dart';
import '../models/match_model.dart' as model;
import '../data/firebase_service.dart';
import '../widgets/team_logo.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class TeamProfileScreen extends StatelessWidget {
  final String teamId;

  const TeamProfileScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context) {
    final allTeams = context.watch<List<Team>>();
    final standings = context.watch<List<StandingsEntry>>();
    
    final Team team = allTeams.firstWhere(
      (t) => t.id == teamId, 
      orElse: () => Team(id: teamId, name: 'Loading...', shortName: '', logoUrl: '', managerId: '', managerName: 'Loading...')
    );
    
    final StandingsEntry? teamStats = standings.where((s) => s.teamId == teamId).firstOrNull;

    // Calculate dynamic momentum spots off Form History moving forward
    List<FlSpot> spots = const [FlSpot(0, 0)];
    List<Color> spotColors = [Colors.grey];

    if (teamStats != null && teamStats.form.isNotEmpty) {
      spots = [];
      spotColors = [];
      
      int currentPoints = teamStats.points;
      for (String result in teamStats.form.reversed) {
        if (result == 'W') { currentPoints -= 3; }
        else if (result == 'D') { currentPoints -= 1; }
      }
      
      spots.add(FlSpot(0, currentPoints.toDouble()));
      spotColors.add(Colors.transparent); // Baseline point
      
      for (int i = 0; i < teamStats.form.length; i++) {
        String result = teamStats.form[i];
        if (result == 'W') {
          currentPoints += 3;
          spotColors.add(AppTheme.accentGreen);
        } else if (result == 'D') {
          currentPoints += 1;
          spotColors.add(Colors.grey);
        } else {
          spotColors.add(AppTheme.redForm);
        }
        spots.add(FlSpot((i + 1).toDouble(), currentPoints.toDouble()));
      }
    }

    // Min and Max Y for scaling beautifully
    double minY = spots.map((s) => s.y).reduce(min) - 5;
    double maxY = spots.map((s) => s.y).reduce(max) + 5;

    return Scaffold(
      backgroundColor: AppTheme.cardColorLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.of(context).pop();
                } else {
                  context.go('/home');
                }
              },
              tooltip: "Back to Home",
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.headerGradient,
                ),
                child: SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Hero(
                          tag: 'logo_$teamId',
                          child: TeamLogo(logoData: team.logoUrl, size: 80),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          team.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Manager ID: ${team.managerId.isEmpty ? 'System' : team.managerId}",
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Form Trajectory", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple)),
                  const SizedBox(height: 16),
                  Container(
                    height: 180,
                    padding: const EdgeInsets.only(top: 24, bottom: 12, left: 16, right: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: 5,
                        minY: minY,
                        maxY: maxY,
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: AppTheme.primaryPurple,
                            barWidth: 4,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true, 
                              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                radius: 5, 
                                color: spotColors[index], 
                                strokeWidth: 2, 
                                strokeColor: spotColors[index] == Colors.transparent ? Colors.transparent : Colors.white
                              )
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppTheme.primaryPurple.withValues(alpha: 0.15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (teamStats != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard("Matches", "${teamStats.played}"),
                        _buildStatCard("GF / GA", "${teamStats.goalsFor} / ${teamStats.goalsAgainst}"),
                        _buildStatCard("Points", "${teamStats.points}"),
                      ],
                    ),
                  ],
                  const SizedBox(height: 32),
                  const Text("Recent Fixtures", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple)),
                  const SizedBox(height: 16),
                  StreamBuilder<List<model.Match>>(
                    stream: context.read<FirebaseService>().getMatches(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      
                      final teamMatches = snapshot.data!.where((m) => 
                        (m.homeTeamId == teamId || m.awayTeamId == teamId) && 
                        (m.status == 'FT' || m.status == 'Finished')
                      ).toList();
                      
                      // Sort latest first
                      teamMatches.sort((a, b) => b.date.compareTo(a.date));

                      if (teamMatches.isEmpty) {
                        return Container(
                          height: 100,
                          alignment: Alignment.center,
                          child: Text("No finished matches yet.", style: TextStyle(color: Colors.grey.shade500)),
                        );
                      }

                      return Column(
                        children: teamMatches.take(5).map((m) => _buildMatchTile(m, allTeams)).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchTile(model.Match match, List<Team> allTeams) {
    final home = allTeams.firstWhere((t) => t.id == match.homeTeamId, orElse: () => Team(id: '', name: 'TBD', shortName: '', logoUrl: '', managerId: '', managerName: ''));
    final away = allTeams.firstWhere((t) => t.id == match.awayTeamId, orElse: () => Team(id: '', name: 'TBD', shortName: '', logoUrl: '', managerId: '', managerName: ''));
    final isHome = match.homeTeamId == teamId;
    final teamScore = isHome ? match.homeScore : match.awayScore;
    final oppScore = isHome ? match.awayScore : match.homeScore;
    
    Color resultColor = Colors.grey;
    if (teamScore! > oppScore!) { resultColor = AppTheme.accentGreen; }
    else if (teamScore < oppScore) { resultColor = AppTheme.redForm; }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: resultColor.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Center(
              child: Text(
                teamScore > oppScore ? "W" : (teamScore < oppScore ? "L" : "D"),
                style: TextStyle(color: resultColor, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHome ? "vs ${away.name}" : "at ${home.name}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  DateFormat('MMM d, yyyy').format(match.date),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            "${match.homeScore} - ${match.awayScore}",
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.primaryPurple),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.primaryPurple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: AppTheme.primaryPurple, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
