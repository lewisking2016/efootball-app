import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/match_model.dart';
import '../../models/standings_model.dart';
import '../../models/team_model.dart';
import '../../models/tournament_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/team_logo.dart';

class StandingsTableView extends StatefulWidget {
  final String tournamentId;

  const StandingsTableView({super.key, required this.tournamentId});

  @override
  State<StandingsTableView> createState() => _StandingsTableViewState();
}

class _StandingsTableViewState extends State<StandingsTableView> {
  String _currentTab = 'Full';

  List<StandingsEntry> _buildLiveStandings({
    required String tournamentId,
    required List<Team> teams,
    required List<Match> matches,
    required List<StandingsEntry> savedStandings,
  }) {
    final previousPositions = {
      for (final standing in savedStandings.where(
        (s) => s.tournamentId == tournamentId,
      ))
        standing.teamId: standing.position,
    };
    final stats = {
      for (final team in teams)
        team.id: _StandingsDraft(
          teamId: team.id,
          tournamentId: tournamentId,
          previousPosition: previousPositions[team.id] ?? 0,
        ),
    };

    final finalMatches =
        matches
            .where(
              (match) =>
                  match.tournamentId == tournamentId &&
                  (match.status == 'FT' || match.status == 'Finished') &&
                  match.homeScore != null &&
                  match.awayScore != null,
            )
            .toList()
          ..sort((a, b) {
            final byDate = a.date.compareTo(b.date);
            if (byDate != 0) return byDate;
            return a.id.compareTo(b.id);
          });

    for (final match in finalMatches) {
      final home = stats.putIfAbsent(
        match.homeTeamId,
        () => _StandingsDraft(
          teamId: match.homeTeamId,
          tournamentId: tournamentId,
          previousPosition: previousPositions[match.homeTeamId] ?? 0,
        ),
      );
      final away = stats.putIfAbsent(
        match.awayTeamId,
        () => _StandingsDraft(
          teamId: match.awayTeamId,
          tournamentId: tournamentId,
          previousPosition: previousPositions[match.awayTeamId] ?? 0,
        ),
      );

      home.apply(match.homeScore!, match.awayScore!);
      away.apply(match.awayScore!, match.homeScore!);
    }

    final entries = stats.values.map((draft) => draft.toEntry()).toList()
      ..sort((a, b) {
        if (b.points != a.points) return b.points.compareTo(a.points);
        if (b.goalDifference != a.goalDifference) {
          return b.goalDifference.compareTo(a.goalDifference);
        }
        if (b.goalsFor != a.goalsFor) return b.goalsFor.compareTo(a.goalsFor);
        return a.teamId.compareTo(b.teamId);
      });

    return entries
        .asMap()
        .entries
        .map(
          (entry) => StandingsEntry(
            position: entry.key + 1,
            previousPosition: entry.value.previousPosition,
            teamId: entry.value.teamId,
            tournamentId: entry.value.tournamentId,
            played: entry.value.played,
            won: entry.value.won,
            drawn: entry.value.drawn,
            lost: entry.value.lost,
            goalsFor: entry.value.goalsFor,
            goalsAgainst: entry.value.goalsAgainst,
            goalDifference: entry.value.goalDifference,
            points: entry.value.points,
            form: entry.value.form,
          ),
        )
        .toList();
  }

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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    type,
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.primaryPurple
                          : Colors.grey.shade600,
                      fontWeight: isSelected
                          ? FontWeight.w900
                          : FontWeight.w600,
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
    if (result == 'W') {
      bgColor = AppTheme.accentGreen;
    } else if (result == 'L') {
      bgColor = Colors.red;
    } else {
      bgColor = Colors.grey.shade300;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: Responsive.sp(context, 20),
      height: Responsive.sp(context, 20),
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Center(
        child: Text(
          result,
          style: TextStyle(
            color: result == 'D' ? Colors.black : Colors.white,
            fontSize: Responsive.sp(context, 10),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTrajectoryIcon(int prev, int current) {
    if (prev == 0) return const SizedBox();
    if (current < prev) {
      return const Icon(Icons.arrow_drop_up, color: Colors.green, size: 20);
    }
    if (current > prev) {
      return const Icon(Icons.arrow_drop_down, color: Colors.red, size: 20);
    }
    return Icon(Icons.remove, color: Colors.grey.shade400, size: 16);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final standings = context.watch<List<StandingsEntry>>();
    final allTeams = context.watch<List<Team>>();
    final allMatches = context.watch<List<Match>>();
    final tournaments = context.watch<List<Tournament>>();

    final selectedTournament = tournaments.firstWhere(
      (t) => t.id == widget.tournamentId,
      orElse: () => Tournament(
        id: '',
        name: 'Loading...',
        region: '',
        type: TournamentType.epl,
        createdAt: DateTime.now(),
      ),
    );

    final teamMap = {for (final team in allTeams) team.id: team};

    final tournamentTeams = allTeams
        .where((team) => team.tournamentId == widget.tournamentId)
        .toList();

    if (allTeams.isEmpty) {
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: ListView.builder(
          itemCount: 15,
          shrinkWrap: true,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      );
    }

    final sortedStandings = _buildLiveStandings(
      tournamentId: widget.tournamentId,
      teams: tournamentTeams,
      matches: allMatches,
      savedStandings: standings,
    );

    return Container(
      color: AppTheme.lightBackground,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1000),
                padding: EdgeInsets.all(isTablet ? 32 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedTournament.name.toUpperCase(),
                      style: TextStyle(
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
                  borderRadius: isTablet
                      ? BorderRadius.circular(20)
                      : BorderRadius.zero,
                  boxShadow: isTablet
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ]
                      : [],
                ),
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: DataTable(
                      key: ValueKey(_currentTab),
                      columnSpacing: Responsive.sp(context, 18),
                      horizontalMargin: 16,
                      headingTextStyle: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: Responsive.sp(context, 12),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                      dataTextStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textColorLight,
                        fontSize: Responsive.sp(context, 13),
                      ),
                      showCheckboxColumn: false,
                      headingRowColor: WidgetStateProperty.resolveWith<Color>(
                        (states) => Colors.grey.shade50,
                      ),
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
                          ],
                        ],
                        if (_currentTab == 'Form')
                          const DataColumn(label: Text('Form')),
                      ],
                      rows: sortedStandings.asMap().entries.map((entry) {
                        final index = entry.key;
                        final standing = entry.value;
                        final position = index + 1;
                        final team =
                            teamMap[standing.teamId] ??
                            Team(
                              id: standing.teamId,
                              name: 'Unknown',
                              shortName: 'UNK',
                              logoUrl: '',
                              managerId: '',
                              managerName: 'Unknown',
                            );

                        return DataRow(
                          onSelectChanged: (selected) {
                            if (selected == true) {
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
                                    color: position <= 4
                                        ? Colors.blue.shade700
                                        : (position == 5
                                              ? Colors.orange
                                              : Colors.transparent),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    position.toString(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  _buildTrajectoryIcon(
                                    standing.previousPosition,
                                    position,
                                  ),
                                ],
                              ),
                            ),
                            DataCell(
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: isTablet ? 220 : 180,
                                  maxWidth: isTablet ? 280 : 220,
                                ),
                                child: Row(
                                  children: [
                                    TeamLogo(logoData: team.logoUrl, size: 32),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            team.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              color: AppTheme.primaryPurple,
                                              fontSize: Responsive.sp(
                                                context,
                                                15,
                                              ),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            team.managerName.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: Responsive.sp(
                                                context,
                                                9,
                                              ),
                                              color: Colors.grey.shade500,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_currentTab != 'Form') ...[
                              DataCell(
                                Text(
                                  standing.played.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  standing.won.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  standing.drawn.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  standing.lost.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (_currentTab == 'Full') ...[
                                DataCell(
                                  Text(
                                    standing.goalsFor.toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    standing.goalsAgainst.toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    standing.goalDifference.toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    standing.points.toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                            if (_currentTab == 'Form')
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: standing.form
                                      .map(_buildFormIcon)
                                      .toList(),
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
          ),
        ],
      ),
    );
  }
}

class _StandingsDraft {
  _StandingsDraft({
    required this.teamId,
    required this.tournamentId,
    required this.previousPosition,
  });

  final String teamId;
  final String tournamentId;
  final int previousPosition;
  int played = 0;
  int won = 0;
  int drawn = 0;
  int lost = 0;
  int goalsFor = 0;
  int goalsAgainst = 0;
  int points = 0;
  final List<String> _form = [];

  void apply(int scored, int conceded) {
    played += 1;
    goalsFor += scored;
    goalsAgainst += conceded;

    if (scored > conceded) {
      won += 1;
      points += 3;
      _form.add('W');
    } else if (scored == conceded) {
      drawn += 1;
      points += 1;
      _form.add('D');
    } else {
      lost += 1;
      _form.add('L');
    }
  }

  int get goalDifference => goalsFor - goalsAgainst;

  List<String> get form => _form.length <= 5
      ? List<String>.from(_form)
      : _form.sublist(_form.length - 5);

  StandingsEntry toEntry() {
    return StandingsEntry(
      position: 0,
      previousPosition: previousPosition,
      teamId: teamId,
      tournamentId: tournamentId,
      played: played,
      won: won,
      drawn: drawn,
      lost: lost,
      goalsFor: goalsFor,
      goalsAgainst: goalsAgainst,
      goalDifference: goalDifference,
      points: points,
      form: form,
    );
  }
}
