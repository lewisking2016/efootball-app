import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../models/match_model.dart' as model;
import '../../models/team_model.dart';
import '../../theme/app_theme.dart';
import '../submission_screen.dart';

class FixturesCalendarView extends StatefulWidget {
  final String tournamentId;
  const FixturesCalendarView({super.key, required this.tournamentId});

  @override
  State<FixturesCalendarView> createState() => _FixturesCalendarViewState();
}

class _FixturesCalendarViewState extends State<FixturesCalendarView> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final matches = context.watch<List<model.Match>>().where((m) => m.tournamentId == widget.tournamentId).toList();
    final teams = context.watch<List<Team>>();

    // Map matches to dates
    Map<DateTime, List<model.Match>> eventSource = {};
    for (var match in matches) {
      final date = DateTime(match.date.year, match.date.month, match.date.day);
      if (eventSource[date] == null) eventSource[date] = [];
      eventSource[date]!.add(match);
    }

    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2024, 1, 1),
          lastDay: DateTime.utc(2026, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          eventLoader: (day) {
            final normalizedDay = DateTime(day.year, day.month, day.day);
            return eventSource[normalizedDay] ?? [];
          },
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
            setState(() => _calendarFormat = format);
          },
          calendarStyle: CalendarStyle(
            markerDecoration: BoxDecoration(color: AppTheme.accentGreen, shape: BoxShape.circle),
            todayDecoration: BoxDecoration(color: AppTheme.primaryPurple.withValues(alpha: 0.3), shape: BoxShape.circle),
            selectedDecoration: BoxDecoration(color: AppTheme.primaryPurple, shape: BoxShape.circle),
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: true,
            titleCentered: true,
            formatButtonDecoration: BoxDecoration(
              border: Border.all(color: AppTheme.primaryPurple),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _selectedDay == null || eventSource[DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)] == null
              ? const Center(child: Text("Select a date with matches to view details"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: eventSource[DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)]!.length,
                  itemBuilder: (context, index) {
                    final match = eventSource[DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)]![index];
                    final homeTeam = teams.firstWhere((t) => t.id == match.homeTeamId, orElse: () => Team(id: '', name: 'Unknown', shortName: 'UNK', logoUrl: '', managerId: '', managerName: ''));
                    final awayTeam = teams.firstWhere((t) => t.id == match.awayTeamId, orElse: () => Team(id: '', name: 'Unknown', shortName: 'UNK', logoUrl: '', managerId: '', managerName: ''));

                    return _buildMatchCard(context, match, homeTeam, awayTeam);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMatchCard(BuildContext context, model.Match match, Team home, Team away) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => MatchSubmissionScreen(match: match)));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildTeamLogo(home.logoUrl),
              const SizedBox(width: 8),
              Expanded(child: Text(home.name, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  match.status == 'FT' && match.homeScore != null && match.awayScore != null
                      ? "${match.homeScore} - ${match.awayScore}"
                      : "VS",
                  style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(child: Text(away.name, textAlign: TextAlign.left, style: const TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(width: 8),
              _buildTeamLogo(away.logoUrl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamLogo(String url) {
    if (url.isEmpty) return CircleAvatar(radius: 15, backgroundColor: AppTheme.cardColorLight);
    return SizedBox(
      width: 30,
      height: 30,
      child: url.endsWith('.svg') ? SvgPicture.asset(url) : Image.asset(url),
    );
  }
}
