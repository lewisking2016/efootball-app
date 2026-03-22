import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/tournament_model.dart';
import 'widgets/standings_table.dart';
import 'widgets/results_list.dart';
import 'widgets/fixtures_list.dart';
import 'widgets/fixtures_calendar_view.dart';
import 'widgets/league_stats_view.dart';
import '../../widgets/line_decoration.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/firebase_service.dart';
import 'package:go_router/go_router.dart';

class MatchesMainScreen extends StatefulWidget {
  final String? tournamentId;
  const MatchesMainScreen({super.key, this.tournamentId});

  @override
  State<MatchesMainScreen> createState() => _MatchesMainScreenState();
}

class _MatchesMainScreenState extends State<MatchesMainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedTournamentId;
  bool _isCalendarView = false;

  @override
  void initState() {
    super.initState();
    _selectedTournamentId = widget.tournamentId;
    _tabController = TabController(length: 4, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final tournaments = context.watch<List<Tournament>>();
    final firebaseService = context.read<FirebaseService>(); // Changed from _firebaseService to a local var

    // Auto-select first tournament if none selected
    if (_selectedTournamentId == null && tournaments.isNotEmpty) {
      _selectedTournamentId = tournaments.first.id;
    }

    final selectedTournament = tournaments.firstWhere(
      (t) => t.id == _selectedTournamentId,
      orElse: () => tournaments.isNotEmpty ? tournaments.first : Tournament(id: '', name: 'Loading...', region: '', type: TournamentType.epl, createdAt: DateTime.now()),
    );

    if (tournaments.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.lightBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events_outlined, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 20),
              Text('No tournaments yet', style: GoogleFonts.outfit(fontSize: 20, color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Create a tournament from the Leagues tab', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade500)),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.home),
                label: const Text("RETURN TO LEAGUES"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: NestedScrollView(
        headerSliverBuilder: (context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: isTablet ? 320.0 : 220.0,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.primaryPurple,
              leading: (widget.tournamentId != null || Navigator.canPop(context))
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.of(context).pop();
                      } else {
                        context.go('/home');
                      }
                    },
                    tooltip: "Back to Home",
                  )
                : null,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.getTournamentGradient(_selectedTournamentId ?? ''),
                  ),
                  child: SafeArea(
                    child: Stack(
                      children: [
                        const LineDecoration(opacity: 0.05),
                        Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 800),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      iconSize: 20, // Smaller icon
                                      icon: Icon(_isCalendarView ? Icons.list : Icons.calendar_month, color: Colors.white),
                                      onPressed: () => setState(() => _isCalendarView = !_isCalendarView),
                                      tooltip: _isCalendarView ? "Switch to List View" : "Switch to Calendar View",
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4), // Reduced from 8
                                 Row(
                                   mainAxisAlignment: MainAxisAlignment.center,
                                   children: [
                                     const SizedBox(width: 48), // Spacer to balance Delete icon
                                     Expanded(
                                       child: Container(
                                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                         decoration: BoxDecoration(
                                           color: Colors.white.withValues(alpha: 0.1),
                                           borderRadius: BorderRadius.circular(12),
                                         ),
                                         child: DropdownButton<String>(
                                           value: _selectedTournamentId,
                                           dropdownColor: AppTheme.primaryPurple,
                                           icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                                           underline: const SizedBox(),
                                           alignment: Alignment.center,
                                           isExpanded: true, // Added
                                           style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1),
                                           items: tournaments.map<DropdownMenuItem<String>>((Tournament t) {
                                             return DropdownMenuItem<String>(
                                               value: t.id,
                                               child: Center(child: Text(t.name.toUpperCase())),
                                             );
                                           }).toList(),
                                           onChanged: (String? newValue) {
                                             if (newValue != null) {
                                               setState(() => _selectedTournamentId = newValue);
                                             }
                                           },
                                         ),
                                       ),
                                     ),
                                     FutureBuilder<bool>(
                                       future: firebaseService.isAdmin(FirebaseAuth.instance.currentUser?.uid ?? ''),
                                       builder: (context, snapshot) {
                                         if (snapshot.data == true) {
                                           return IconButton(
                                             padding: EdgeInsets.zero,
                                             icon: const Icon(Icons.delete_forever_outlined, color: Colors.white70),
                                             onPressed: () => _showDeleteConfirmation(context, firebaseService),
                                             tooltip: "Delete League",
                                           );
                                         }
                                         return const SizedBox(width: 48); // Balance
                                       },
                                     ),
                                   ],
                                 ),
                                const SizedBox(height: 12), // Reduced from 24
                                Hero(
                                  tag: 'tournament_logo',
                                  child: Icon(
                                    selectedTournament.type == TournamentType.uefa ? Icons.star : Icons.emoji_events,
                                    color: Colors.white,
                                    size: isTablet ? 80 : 40, // Reduced from 100/60
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppTheme.primaryPurple,
                    indicatorWeight: 4,
                    labelColor: AppTheme.primaryPurple,
                    unselectedLabelColor: Colors.grey.shade400,
                    labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
                    unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16),
                    tabs: const [
                      Tab(text: "RESULTS"),
                      Tab(text: "MATCHES"),
                      Tab(text: "TABLE"),
                      Tab(text: "STATS"),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: _selectedTournamentId == null
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  ResultsListView(tournamentId: _selectedTournamentId!),
                   _isCalendarView
                       ? FixturesCalendarView(tournamentId: _selectedTournamentId!)
                       : FixturesListView(
                           tournamentId: _selectedTournamentId!,
                           onTournamentChanged: (val) => setState(() => _selectedTournamentId = val),
                         ),
                  StandingsTableView(tournamentId: _selectedTournamentId!),
                  LeagueStatsView(tournamentId: _selectedTournamentId!),
                ],
              ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, FirebaseService firebaseService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete League?"),
        content: const Text("This will permanently remove this league, all its matches, and the current standings table. This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_selectedTournamentId != null) {
                await firebaseService.deleteTournament(_selectedTournamentId!);
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("League deleted successfully")),
                  );
                  context.go('/home'); // Back to main list
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.redForm, foregroundColor: Colors.white),
            child: const Text("DELETE PERMANENTLY"),
          ),
        ],
      ),
    );
  }
}
