import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/session_service.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _crestController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _crestController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..repeat();
    _fade = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOutCubic,
    );
    _slide = Tween(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(_fade);

    _introController.forward();
    _routeAfterAuthSettles();
  }

  Future<void> _routeAfterAuthSettles() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    final user = await FirebaseAuth.instance.authStateChanges().first;
    final keepSession = await SessionService.keepOrEndCurrentSession(user);
    if (!mounted) return;
    context.go(keepSession ? '/home' : '/login');
  }

  @override
  void dispose() {
    _introController.dispose();
    _crestController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _SplashAmbientBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _SplashCrest(controller: _crestController, size: 130),
                          const SizedBox(height: 28),
                          Text(
                            "EFOOTBALL 2.0",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.accentGreen,
                              fontSize: Responsive.sp(context, 30),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "LEAGUES. TEAMS. RESULTS.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 30,
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 5,
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.accentGreen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Preparing matchday",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.58),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashAmbientBackground extends StatelessWidget {
  const _SplashAmbientBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF21002B),
            Color(0xFF38003C),
            Color(0xFF4E0075),
            Color(0xFF111E6A),
          ],
          stops: [0.0, 0.42, 0.74, 1.0],
        ),
      ),
      child: CustomPaint(painter: _SplashAmbientPainter(), child: child),
    );
  }
}

class _SplashAmbientPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final blueSweep = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0x002FD8FF), Color(0x552FD8FF), Color(0x00FFFFFF)],
      ).createShader(Offset.zero & size);

    final whiteSweep = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.13),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Offset.zero & size);

    final bluePath = Path()
      ..moveTo(size.width * 0.64, 0)
      ..cubicTo(
        size.width,
        size.height * 0.18,
        size.width * 0.72,
        size.height * 0.58,
        size.width,
        size.height * 0.78,
      )
      ..lineTo(size.width, size.height)
      ..cubicTo(
        size.width * 0.54,
        size.height * 0.74,
        size.width * 0.84,
        size.height * 0.23,
        size.width * 0.32,
        0,
      )
      ..close();

    final whitePath = Path()
      ..moveTo(0, size.height * 0.24)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.18,
        size.width * 0.62,
        size.height * 0.34,
        size.width,
        size.height * 0.27,
      )
      ..lineTo(size.width, size.height * 0.41)
      ..cubicTo(
        size.width * 0.62,
        size.height * 0.49,
        size.width * 0.3,
        size.height * 0.34,
        0,
        size.height * 0.42,
      )
      ..close();

    canvas.drawPath(bluePath, blueSweep);
    canvas.drawPath(whitePath, whiteSweep);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SplashCrest extends StatelessWidget {
  const _SplashCrest({required this.controller, required this.size});

  final AnimationController controller;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = controller.value * math.pi * 2;
        return Transform.translate(
          offset: Offset(0, math.sin(t) * 5),
          child: Transform.rotate(
            angle: math.sin(t) * 0.022,
            child: Container(
              width: size,
              height: size,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  transform: GradientRotation(t),
                  colors: const [
                    Color(0xFFFFFFFF),
                    Color(0xFF2FD8FF),
                    Color(0xFF00FF85),
                    Color(0xFFFFFFFF),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2FD8FF).withValues(alpha: 0.28),
                    blurRadius: 38,
                    spreadRadius: 3,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/efootballlogo/efllogo.jpeg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
