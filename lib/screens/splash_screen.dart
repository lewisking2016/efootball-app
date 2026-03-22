import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

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
      backgroundColor: const Color(0xFF3D195B), // Authentic EPL Purple
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Subtle EPL secondary glow
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  const Color(0xFF5D2A8E).withValues(alpha: 0.3), // Lighter purple glow
                  const Color(0xFF3D195B),
                ],
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
                          width: Responsive.sp(context, 160),
                          height: Responsive.sp(context, 160),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00FF85).withValues(alpha: 0.3), // EPL Green accent
                                blurRadius: Responsive.sp(context, 50),
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            'assets/efootballlogo/efllogo.jpeg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: Responsive.sp(context, 40)),
                    // Classy text treatment
                    Text(
                      "THE NEW HOME OF",
                      style: GoogleFonts.outfit(
                        fontSize: Responsive.sp(context, 12),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 6,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF38003C), Color(0xFFE90052)], // EPL Purple to Pink gradient
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        "EFOOTBALL MANAGER",
                        style: GoogleFonts.outfit(
                          fontSize: Responsive.sp(context, 26),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: Responsive.sp(context, 40)),
                     SizedBox(
                      width: Responsive.sp(context, 30),
                      height: Responsive.sp(context, 30),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.4)),
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

