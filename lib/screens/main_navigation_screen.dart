import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../data/firebase_service.dart';
import '../data/notification_service.dart';
import 'submission_screen.dart';
import 'matches_screen.dart';
import 'explore_screen.dart';
import 'tournaments_screen.dart';
import 'more_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 1; // Default to Matches (was 2)

  @override
  void initState() {
    super.initState();
    _checkTeamAndPermissions();
  }

  void _checkTeamAndPermissions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await NotificationService.saveTokenToFirestore(user.uid);
      
      if (mounted) {
        final firebaseService = context.read<FirebaseService>();
        final profile = await firebaseService.getUserProfile(user.uid);
        
        if (mounted) {
          if (profile == null || (!profile.isAdmin && profile.teamId == null)) {
            context.go('/pick-team');
          }
        }
      }
    }
  }

  final List<Widget> _screens = [
    const TournamentsScreen(),
    const MatchesMainScreen(),
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
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -5))
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
          unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 11),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_outlined, size: 24),
              activeIcon: Icon(Icons.emoji_events, size: 24),
              label: 'LEAGUES',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Icon(
                  _currentIndex == 1 ? Icons.sports_soccer : Icons.sports_soccer_outlined,
                  size: 28,
                  color: _currentIndex == 1 ? AppTheme.primaryPurple : Colors.grey.shade400,
                ),
              ),
              label: 'MATCHES',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined, size: 24),
              activeIcon: Icon(Icons.explore, size: 24),
              label: 'EXPLORE',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz_outlined, size: 24),
              activeIcon: Icon(Icons.more_horiz, size: 24),
              label: 'MORE',
            ),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 1 ? FloatingActionButton.extended(
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
