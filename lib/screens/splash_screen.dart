import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _introController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Main entry animation
    _introController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _introController, curve: const Interval(0.2, 1.0, curve: Curves.easeIn)));

    // Continuous pulse glow animation
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _introController.forward();

    Future.delayed(const Duration(milliseconds: 3500), () async {
      if (mounted) {
        // Wait safely for Firebase Auth to initialize its local IndexedDB state
        final user = await FirebaseAuth.instance.authStateChanges().first;
        if (mounted) {
          if (user != null) {
            context.go('/home');
          } else {
            context.go('/login');
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _introController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B0024), // Very deep purple/black
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Gradient Vibe
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  Color(0xFF4B006E), // Inner glow purple
                  Color(0xFF1A0027), // Outer dark edge
                ],
              ),
            ),
          ),

          // Animated particle-like faint grid overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: CustomPaint(
                painter: _GridPainter(),
              ),
            ),
          ),

          // Core content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // The main pulsating logo without white edges
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Hero(
                        tag: 'efl_logo',
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00FF85).withValues(alpha: 0.2), // Subtle green EPL accent glow
                                blurRadius: 60,
                                spreadRadius: 10,
                              ),
                              BoxShadow(
                                color: const Color(0xFF00D2FF).withValues(alpha: 0.15), // Subtle cyan glow
                                blurRadius: 40,
                                spreadRadius: -5,
                              )
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            'assets/efootballlogo/efllogo.jpeg',
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.high,
                            // Optionally apply a blend mode if the jpeg itself has white corners we want to hide
                            // colorFilter: const ColorFilter.mode(Colors.black, BlendMode.dstIn),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                    // Classy text treatment
                    Text(
                      "THE NEW HOME OF",
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 6,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF00FF85), Color(0xFF00D2FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        "EFOOTBALL MANAGER",
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: Colors.white, // Required for ShaderMask to take full effect over the text
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    // subtle loading indicator
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.2)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0;

    const step = 40.0;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
