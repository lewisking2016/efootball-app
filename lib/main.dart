import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/team_profile_screen.dart';
import 'data/firebase_service.dart';
import 'models/team_model.dart';
import 'models/standings_model.dart';
import 'screens/create_tournament_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Seed db initially if it's empty
  await FirebaseService().seedInitialDatabase();

  runApp(const EFootballApp());
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SplashScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
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
              position: Tween<Offset>(begin: const Offset(0.0, 0.1), end: Offset.zero).animate(animation),
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
          return FadeTransition(
            opacity: animation,
            child: child,
          );
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
      ],
      child: MaterialApp.router(
        title: 'eFootball Pro League',
        theme: AppTheme.lightTheme,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
