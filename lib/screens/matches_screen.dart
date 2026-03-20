import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'widgets/standings_table.dart';
import 'widgets/fixtures_list.dart';
import 'widgets/league_stats_view.dart';

class MatchesMainScreen extends StatefulWidget {
  const MatchesMainScreen({super.key});

  @override
  State<MatchesMainScreen> createState() => _MatchesMainScreenState();
}

class _MatchesMainScreenState extends State<MatchesMainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTournament = 'epl';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1); // Default to Table
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
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.getTournamentGradient(_selectedTournament),
                  ),
                  child: SafeArea(
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 800),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButton<String>(
                                value: _selectedTournament,
                                dropdownColor: AppTheme.primaryPurple,
                                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                                underline: const SizedBox(),
                                alignment: Alignment.center,
                                style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1),
                                items: <String>['epl', 'champions_league', 'la_liga', 'serie_a', 'fa_cup']
                                    .map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Center(child: Text(value.replaceAll('_', ' ').toUpperCase())),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() => _selectedTournament = newValue);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                            Hero(
                              tag: 'tournament_logo',
                              child: Icon(
                                _selectedTournament == 'champions_league' ? Icons.star : Icons.emoji_events,
                                color: Colors.white,
                                size: isTablet ? 120 : 80,
                              ),
                            ),
                          ],
                        ),
                      ),
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
        body: TabBarView(
          controller: _tabController,
          children: const [
            FixturesListView(),
            StandingsTableView(),
            LeagueStatsView(),
          ],
        ),
      ),
    );
  }
}
