import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/matches_screen.dart';
import 'screens/team_profile_screen.dart';
import 'data/firebase_service.dart';
import 'data/notification_service.dart';
import 'data/session_service.dart';
import 'models/team_model.dart';
import 'models/standings_model.dart';
import 'models/match_model.dart';
import 'models/tournament_model.dart';
import 'screens/create_tournament_screen.dart';
import 'screens/join_tournament_screen.dart';
import 'screens/pick_team_screen.dart';
// Removed unused import
import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart'; // Added for kIsWeb and defaultTargetPlatform

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      // 1. Handle Automations (Postponements / Auto-Results)
      await FirebaseService().handleDelayedMatches();

      // 2. Handle Reminders
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final matches = await FirebaseService().getTeamMatchesTodaySync(
          user.uid,
        );
        if (matches.isNotEmpty) {
          await NotificationService.initialize();
          await NotificationService.showLocalNotification(
            "⚽ Match Day Today!",
            "Your team plays today! Don't forget to submit the result.",
          );
        }
      }
    } catch (e) {
      debugPrint("Background Task Error: $e");
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }

  // Default to session-only auth. The login screen upgrades this to LOCAL
  // only when the user opts into the 30-day remember-me window.
  try {
    await SessionService.prepareAuthPersistence(rememberMe: false);
  } catch (e) {
    debugPrint("Persistence init error: $e");
  }

  // Run the app first so the UI isn't blocked by permission dialogs or background setup
  runApp(const EFootballApp());

  // Initialize Push Notifications asynchronously
  setupNotifications();

  // Initialize Workmanager for Free Background Tasks (Android only for now)
  setupWorkmanager();
}

Future<void> setupNotifications() async {
  try {
    await NotificationService.initialize();
  } catch (e) {
    debugPrint("Notification init error: $e");
  }
}

Future<void> setupWorkmanager() async {
  try {
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android)) {
      await Workmanager().initialize(callbackDispatcher);
      await Workmanager().registerPeriodicTask(
        "match-day-check",
        "checkTodayMatches",
        frequency: const Duration(hours: 3), // Remind the user every 3 hours
        constraints: Constraints(networkType: NetworkType.connected),
      );
    }
  } catch (e) {
    debugPrint("Workmanager init error: $e");
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SplashScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AuthScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.1),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
      ),
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const MainNavigationScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: '/team/:id',
      builder: (context, state) {
        final teamId = state.pathParameters['id']!;
        return TeamProfileScreen(teamId: teamId);
      },
    ),
    GoRoute(
      path: '/create-tournament',
      builder: (context, state) => const CreateTournamentScreen(),
    ),
    GoRoute(
      path: '/join-tournament',
      builder: (context, state) => JoinTournamentScreen(
        initialTournamentId: state.uri.queryParameters['tournamentId'],
      ),
    ),
    GoRoute(
      path: '/league/:id',
      builder: (context, state) {
        final tournamentId = state.pathParameters['id']!;
        return MatchesMainScreen(tournamentId: tournamentId);
      },
    ),
    GoRoute(
      path: '/pick-team',
      builder: (context, state) => const PickTeamScreen(),
    ),
  ],
);

class EFootballApp extends StatelessWidget {
  const EFootballApp({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();

    return MultiProvider(
      providers: [
        Provider<FirebaseService>.value(value: firebaseService),
        StreamProvider<List<Team>>(
          create: (_) => firebaseService.getTeams(),
          initialData: const [],
        ),
        StreamProvider<List<StandingsEntry>>(
          create: (_) => firebaseService.getStandings(),
          initialData: const [],
        ),
        StreamProvider<List<Match>>(
          create: (_) => firebaseService.getMatches(),
          initialData: const [],
        ),
        StreamProvider<List<Tournament>>(
          create: (_) => firebaseService.getTournaments(),
          initialData: const [],
        ),
      ],
      child: MaterialApp.router(
        title: 'EFL Manager',
        theme: AppTheme.lightTheme,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
