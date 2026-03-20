import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'submission_screen.dart';
import 'matches_screen.dart';
import 'explore_screen.dart';
import 'latest_news_screen.dart';
import 'tournaments_screen.dart';
import 'more_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 2; // Default to Matches (center)

  final List<Widget> _screens = [
    const LatestNewsScreen(),
    const TournamentsScreen(),
    const MatchesMainScreen(), // The core screen we built
    const ExploreScreen(),
    const MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primaryPurple,
          unselectedItemColor: Colors.grey.shade400,
          showUnselectedLabels: true,
          selectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
          unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 11),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.article_outlined),
              activeIcon: Icon(Icons.article),
              label: 'LATEST',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_outlined),
              activeIcon: Icon(Icons.emoji_events),
              label: 'LEAGUES',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == 2 ? AppTheme.primaryPurple : Colors.transparent,
                ),
                child: Icon(
                  Icons.sports_soccer, 
                  size: 26,
                  color: _currentIndex == 2 ? Colors.white : AppTheme.primaryPurple.withOpacity(0.6),
                ),
              ),
              label: 'MATCHES',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'EXPLORE',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz),
              activeIcon: Icon(Icons.more_horiz, size: 28),
              label: 'MORE',
            ),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 2 ? FloatingActionButton.extended(
        backgroundColor: AppTheme.accentGreen,
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MatchSubmissionScreen()));
        },
        icon: const Icon(Icons.add_a_photo, color: AppTheme.primaryPurple),
        label: const Text("Submit Score", style: TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold)),
      ) : null,
    );
  }
}
