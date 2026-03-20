import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../models/team_model.dart';
import '../models/standings_model.dart';
import '../widgets/team_logo.dart';
import '../theme/app_theme.dart';

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
        if (result == 'W') currentPoints -= 3;
        else if (result == 'D') currentPoints -= 1;
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
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
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
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
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
                              color: AppTheme.primaryPurple.withOpacity(0.15),
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
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: const Center(
                      child: Text("History synchronized to live matches stream.", style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                ],
              ),
            ),
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
        color: AppTheme.primaryPurple.withOpacity(0.05),
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
