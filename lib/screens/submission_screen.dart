import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../models/team_model.dart';
import '../models/match_model.dart';
import '../models/tournament_model.dart';
import '../models/app_user_model.dart';
import '../data/firebase_service.dart';
import '../widgets/line_decoration.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MatchSubmissionScreen extends StatefulWidget {
  final Match? match; // If provided, we are updating an existing fixture
  const MatchSubmissionScreen({super.key, this.match});

  @override
  State<MatchSubmissionScreen> createState() => _MatchSubmissionScreenState();
}

class _MatchSubmissionScreenState extends State<MatchSubmissionScreen> {
  String? _selectedTournamentId;
  String? _selectedMatchId;
  String? _selectedHomeTeamId;
  String? _selectedAwayTeamId;
  DateTime _selectedDate = DateTime.now();
  int _homeScore = 0;
  int _awayScore = 0;

  @override
  void initState() {
    super.initState();
    if (widget.match != null) {
      _selectedTournamentId = widget.match!.tournamentId;
      _selectedMatchId = widget.match!.id;
      _selectedHomeTeamId = widget.match!.homeTeamId;
      _selectedAwayTeamId = widget.match!.awayTeamId;
      _selectedDate = widget.match!.date;
      _homeScore = widget.match!.homeScore ?? 0;
      _awayScore = widget.match!.awayScore ?? 0;
    }
  }

  Future<void> _submitMatch() async {
    final firebaseService = context.read<FirebaseService>();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final profile = await firebaseService.getUserProfile(user.uid);
    final isAdmin = profile?.isAdmin ?? false;
    final userTeamId = profile?.teamId;

    if (widget.match != null && !isAdmin) {
      if (widget.match!.homeTeamId != userTeamId && widget.match!.awayTeamId != userTeamId) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Access Denied: You can only submit scores for matches involving your team."), backgroundColor: Colors.red),
          );
        }
        return;
      }
    } else if (widget.match == null && !isAdmin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Only admins can create manual results."), backgroundColor: Colors.red),
        );
      }
      return;
    }

    if (_selectedHomeTeamId == null || _selectedAwayTeamId == null || _selectedTournamentId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a tournament and teams.")),
      );
      return;
    }

    try {
      await firebaseService.submitMatchResult(
        matchId: _selectedMatchId,
        tournamentId: _selectedTournamentId!,
        homeTeamId: _selectedHomeTeamId!,
        awayTeamId: _selectedAwayTeamId!,
        homeScore: _homeScore,
        awayScore: _awayScore,
        isAdmin: isAdmin,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Match Result Saved!"), backgroundColor: AppTheme.accentGreen),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<List<Tournament>>(); // watched for reactivity
    final allTeams = context.watch<List<Team>>();
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<AppUser?>(
      future: context.read<FirebaseService>().getUserProfile(user?.uid ?? ''),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final isAdmin = profile?.isAdmin ?? false;
        final userTeamId = profile?.teamId;

        bool isAuthorized = isAdmin;
        if (!isAuthorized && widget.match != null) {
          isAuthorized = widget.match!.homeTeamId == userTeamId || widget.match!.awayTeamId == userTeamId;
        }

        // ADDITIONAL LOCK: If already FT, only Admin can edit
        final isLocked = (widget.match?.status == 'FT') && !isAdmin;
        final canSubmit = isAuthorized && !isLocked;

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.match?.status == 'FT' ? "Edit Result" : "Enter Match Result"),
            backgroundColor: AppTheme.primaryPurple,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.of(context).pop();
                } else {
                  context.go('/home');
                }
              },
            ),
          ),
          body: Stack(
            children: [
              const LineDecoration(opacity: 0.05, spacing: 40),
              SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isLocked)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lock_clock_outlined, color: Colors.orange),
                            SizedBox(width: 8),
                            Expanded(child: Text("This result is finalized. Only admins can edit it.", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12))),
                          ],
                        ),
                      )
                    else if (!isAuthorized && widget.match != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lock_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Expanded(child: Text("Only the managers of these teams or admins can submit scores.", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12))),
                          ],
                        ),
                      ),
                    const Text("Select Fixture", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryPurple)),
                    const SizedBox(height: 16),
                    // Date Selection
                    InkWell(
                      onTap: widget.match != null ? null : () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2027),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked;
                            _selectedMatchId = null; // Reset selection
                            _selectedHomeTeamId = null;
                            _selectedAwayTeamId = null;
                            _selectedTournamentId = null;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: AppTheme.primaryPurple),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('EEEE, d MMMM yyyy').format(_selectedDate),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            if (widget.match == null) const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Fixture Dropdown
                    StreamBuilder<List<Match>>(
                      stream: context.read<FirebaseService>().getMatches(),
                      builder: (context, snapshot) {
                        final allMatches = snapshot.data ?? [];
                        final dailyMatches = allMatches.where((m) {
                          return m.status == 'Pending' && 
                                 m.date.year == _selectedDate.year && 
                                 m.date.month == _selectedDate.month && 
                                 m.date.day == _selectedDate.day;
                        }).toList();

                        // Ensure displayMatches contains our selected match if we're editing or have one selected
                        List<Match> displayMatches = widget.match != null ? [widget.match!] : List<Match>.from(dailyMatches);
                        if (_selectedMatchId != null && !displayMatches.any((m) => m.id == _selectedMatchId)) {
                          final matchInAll = allMatches.where((m) => m.id == _selectedMatchId).firstOrNull;
                          if (matchInAll != null) displayMatches.add(matchInAll);
                        }

                        // NEW: Auto-select if only one match and none selected
                        if (widget.match == null && dailyMatches.length == 1 && _selectedMatchId == null) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() {
                                _selectedMatchId = dailyMatches.first.id;
                                _selectedHomeTeamId = dailyMatches.first.homeTeamId;
                                _selectedAwayTeamId = dailyMatches.first.awayTeamId;
                                _selectedTournamentId = dailyMatches.first.tournamentId;
                              });
                            }
                          });
                        }

                        return IgnorePointer(
                          ignoring: widget.match != null,
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: "Fixture", border: OutlineInputBorder()),
                            initialValue: displayMatches.any((m) => m.id == _selectedMatchId) ? _selectedMatchId : null,
                            hint: const Text("Select a match for this day"),
                            items: displayMatches.map((m) {
                              final home = allTeams.firstWhere((t) => t.id == m.homeTeamId, orElse: () => Team(id: '', name: 'TBD', shortName: '', logoUrl: '', managerId: '', managerName: ''));
                              final away = allTeams.firstWhere((t) => t.id == m.awayTeamId, orElse: () => Team(id: '', name: 'TBD', shortName: '', logoUrl: '', managerId: '', managerName: ''));
                              return DropdownMenuItem(
                                value: m.id,
                                child: Text("${home.name} vs ${away.name}"),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                final selected = displayMatches.firstWhere((m) => m.id == val);
                                setState(() {
                                  _selectedMatchId = val;
                                  _selectedHomeTeamId = selected.homeTeamId;
                                  _selectedAwayTeamId = selected.awayTeamId;
                                  _selectedTournamentId = selected.tournamentId;
                                });
                              }
                            },
                          ),
                        );
                      }
                    ),
                    const SizedBox(height: 40),
                    const Text("Final Score", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryPurple)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildScoreField(
                          label: "Home",
                          initialValue: _homeScore,
                          onChanged: (val) => _homeScore = val,
                          enabled: !isLocked,
                        ),
                        const SizedBox(width: 32),
                        const Text("-", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 32),
                        _buildScoreField(
                          label: "Away",
                          initialValue: _awayScore,
                          onChanged: (val) => _awayScore = val,
                          enabled: !isLocked,
                        ),
                      ],
                    ),
                    const SizedBox(height: 60),
                    ElevatedButton(
                      onPressed: canSubmit ? _submitMatch : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canSubmit ? AppTheme.primaryPurple : Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: canSubmit ? 4 : 0,
                      ),
                      child: Text(
                        isLocked ? "RESULT LOCKED" : (isAuthorized ? "SAVE RESULT" : "SUBMISSION LOCKED"), 
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScoreField({required String label, required int initialValue, required Function(int) onChanged, bool enabled = true}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        SizedBox(
          width: 80,
          child: TextFormField(
            enabled: enabled,
            initialValue: initialValue.toString(),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (val) => onChanged(int.tryParse(val) ?? 0),
          ),
        ),
      ],
    );
  }
}
