import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/standings_model.dart';
import '../../models/team_model.dart';
import '../../widgets/team_logo.dart';
import '../../theme/app_theme.dart';
import 'dart:math';

class LeagueStatsView extends StatelessWidget {
  final String tournamentId;
  const LeagueStatsView({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context) {
    final standings = context.watch<List<StandingsEntry>>();
    final allTeams = context.watch<List<Team>>();

    // Create a map of teams for quick lookup
    final Map<String, Team> teamMap = {for (var t in allTeams) t.id: t};

    final filteredStandings = standings
        .where((s) => s.tournamentId == tournamentId)
        .toList();

    if (filteredStandings.isEmpty || allTeams.isEmpty) {
      return const Center(
        child: Text(
          "Not enough data to generate analytics.",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Compute exact mathematical grid bounds with padding
    double minGD = filteredStandings
        .map((e) => e.goalDifference)
        .reduce(min)
        .toDouble();
    double maxGD = filteredStandings
        .map((e) => e.goalDifference)
        .reduce(max)
        .toDouble();
    double minPts = filteredStandings
        .map((e) => e.points)
        .reduce(min)
        .toDouble();
    double maxPts = filteredStandings
        .map((e) => e.points)
        .reduce(max)
        .toDouble();

    // Prevent divide by zero if data is completely flat
    if (minGD == maxGD) {
      minGD -= 10;
      maxGD += 10;
    }
    if (minPts == maxPts) {
      minPts -= 10;
      maxPts += 10;
    }

    // Pad graph boundaries by 10%
    double paddingGD = (maxGD - minGD) * 0.1;
    double paddingPts = (maxPts - minPts) * 0.1;
    minGD -= paddingGD;
    maxGD += paddingGD;
    minPts -= paddingPts;
    maxPts += paddingPts;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "2025/26 Performance Matrix",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryPurple,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Points vs Goal Difference",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Quadrant Grid Background Lines
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _GridPainter(
                        minGD: minGD,
                        maxGD: maxGD,
                        minPts: minPts,
                        maxPts: maxPts,
                      ),
                    ),
                  ),

                  // Axis Labels
                  const Positioned(
                    left: 12,
                    top: 12,
                    child: Text(
                      "High Points",
                      style: TextStyle(
                        color: AppTheme.primaryPurple,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Positioned(
                    right: 12,
                    bottom: 12,
                    child: Text(
                      "High Goal Diff",
                      style: TextStyle(
                        color: AppTheme.primaryPurple,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Team Logos
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const double logoSize = 32.0;

                      return Stack(
                        children: filteredStandings.map((stat) {
                          final team = teamMap[stat.teamId];
                          if (team == null) return const SizedBox.shrink();

                          double normalizedX =
                              (stat.goalDifference - minGD) / (maxGD - minGD);
                          double normalizedY =
                              (stat.points - minPts) / (maxPts - minPts);

                          // Calculate absolute position (origin is bottom-left theoretically, but Flutter stack origin is top-left)
                          // X is left-to-right. Y is bottom-to-top, so we invert Y for Top-Left spacing

                          // ADD JITTER for pre-season (when all teams are at 0, 0)
                          // Use the team name hash to create a unique, stable offset for each team
                          final int spreadFactor = 28;
                          final double offsetX =
                              (sin(team.id.hashCode.toDouble() * 0.8) *
                              spreadFactor);
                          final double offsetY =
                              (cos(team.id.hashCode.toDouble() * 0.8) *
                              spreadFactor);

                          double left =
                              (normalizedX * constraints.maxWidth) -
                              (logoSize / 2) +
                              offsetX;
                          double top =
                              ((1 - normalizedY) * constraints.maxHeight) -
                              (logoSize / 2) +
                              offsetY;

                          // Clamp to avoid clipping
                          left = left.clamp(
                            16.0,
                            constraints.maxWidth - logoSize - 16.0,
                          );
                          top = top.clamp(
                            16.0,
                            constraints.maxHeight - logoSize - 16.0,
                          );

                          return AnimatedPositioned(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutBack,
                            left: left,
                            top: top,
                            child: Tooltip(
                              message:
                                  "${team.name}\nPoints: ${stat.points} | GD: ${stat.goalDifference}",
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  color: Colors.white,
                                ),
                                child: ClipOval(
                                  child: TeamLogo(
                                    logoData: team.logoUrl,
                                    size: logoSize,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                color: AppTheme.accentGreen.withValues(alpha: 0.2),
              ),
              const SizedBox(width: 8),
              const Text(
                "Top Performers",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 24),
              Container(
                width: 12,
                height: 12,
                color: AppTheme.redForm.withValues(alpha: 0.2),
              ),
              const SizedBox(width: 8),
              const Text(
                "Underperforming",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final double minGD, maxGD, minPts, maxPts;

  _GridPainter({
    required this.minGD,
    required this.maxGD,
    required this.minPts,
    required this.maxPts,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..strokeWidth = 1;

    final strongPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..strokeWidth = 1.5;

    final trendPaint = Paint()
      ..color = AppTheme.primaryPurple.withValues(alpha: 0.08)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // 1. Draw grid lines
    for (int i = 1; i < 4; i++) {
      double y = size.height * (i / 4);
      double x = size.width * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // 2. Draw Multi-Layered Diagonal Trend Lines (The "Golden Path")
    // Main Trend Line (Expected Performance)
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, 0),
      trendPaint..color = trendPaint.color.withValues(alpha: 0.2),
    );

    // Performance Corridors (Multiple lines for "clarity")
    for (double i = 0.1; i <= 0.4; i += 0.1) {
      // Upper Corridors
      canvas.drawLine(
        Offset(0, size.height * (1 - i)),
        Offset(size.width * (1 - i), 0),
        trendPaint..color = trendPaint.color.withValues(alpha: 0.05),
      );
      // Lower Corridors
      canvas.drawLine(
        Offset(size.width * i, size.height),
        Offset(size.width, size.height * i),
        trendPaint..color = trendPaint.color.withValues(alpha: 0.05),
      );
    }

    // 3. Labels for Trend Lines
    _drawLabel(
      canvas,
      size,
      "ELITE EFFICIENCY",
      Offset(size.width * 0.1, size.height * 0.4),
      -0.7,
    );
    _drawLabel(
      canvas,
      size,
      "EXPECTED TREND",
      Offset(size.width * 0.4, size.height * 0.6),
      -0.7,
    );
    _drawLabel(
      canvas,
      size,
      "STRATEGIC DEFICIT",
      Offset(size.width * 0.7, size.height * 0.9),
      -0.7,
    );

    // 4. Find the 0 Goal Difference line specifically if it's within bounds
    if (minGD < 0 && maxGD > 0) {
      double zeroX = ((0 - minGD) / (maxGD - minGD)) * size.width;
      canvas.drawLine(
        Offset(zeroX, 0),
        Offset(zeroX, size.height),
        strongPaint,
      );

      // Define colors for visual quadrants
      final greenPaint = Paint()
        ..color = AppTheme.accentGreen.withValues(alpha: 0.05)
        ..style = PaintingStyle.fill;
      final redPaint = Paint()
        ..color = AppTheme.redForm.withValues(alpha: 0.05)
        ..style = PaintingStyle.fill;

      // Top Right: Positive GD, Upper half points
      // We adjust Rect to follow the zeroX divider
      canvas.drawRect(
        Rect.fromLTRB(zeroX, 0, size.width, size.height / 2),
        greenPaint,
      );

      // Bottom Left: Negative GD, Lower half points
      canvas.drawRect(
        Rect.fromLTRB(0, size.height / 2, zeroX, size.height),
        redPaint,
      );
    }
  }

  void _drawLabel(
    Canvas canvas,
    Size size,
    String text,
    Offset offset,
    double rotation,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: AppTheme.primaryPurple.withValues(alpha: 0.3),
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.rotate(rotation);
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.minGD != minGD ||
        oldDelegate.maxGD != maxGD ||
        oldDelegate.minPts != minPts ||
        oldDelegate.maxPts != maxPts;
  }
}
