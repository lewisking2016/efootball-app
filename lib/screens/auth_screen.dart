import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../data/firebase_service.dart';
import '../data/notification_service.dart';
// Removed unused import

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  StreamSubscription<User?>? _authSubscription;
  late final AnimationController _logoController;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null && mounted) {
        context.go('/home');
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _logoController.dispose();
    super.dispose();
  }

  Future<void> _showAdminLoginDialog() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.primaryPurple,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.accentGreen, width: 2),
        ),
        title: Text(
          "ADMIN CLEARANCE",
          style: TextStyle(
            color: AppTheme.accentGreen,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              style: const TextStyle(color: Colors.white),
              decoration: AppTheme.getAuthInputDecoration(
                "Email",
                Icons.email_outlined,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: AppTheme.getAuthInputDecoration(
                "Password",
                Icons.lock_outline,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "CANCEL",
              style: TextStyle(
                color: Colors.white60,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleAdminLogin(
                emailController.text.trim(),
                passwordController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGreen,
              foregroundColor: AppTheme.primaryPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              "ACCESS",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      UserCredential? credential;
      if (kIsWeb) {
        final authProvider = GoogleAuthProvider();
        credential = await FirebaseAuth.instance.signInWithPopup(authProvider);
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          setState(() => _isLoading = false);
          return;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final OAuthCredential oauthCredential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        credential = await FirebaseAuth.instance.signInWithCredential(
          oauthCredential,
        );
      }
      final user = credential.user ?? FirebaseAuth.instance.currentUser;
      if (user != null && mounted) {
        final firebaseService = context.read<FirebaseService>();
        await firebaseService.createOrUpdateUser(user.uid, user.email ?? '');
        await NotificationService.saveTokenToFirestore(user.uid);

        if (mounted) {
          // Skip mandatory league registration as requested
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Authentication Failed: $e',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAdminLogin(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both email and password.")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final firebaseService = context.read<FirebaseService>();
      UserCredential userCredential;

      try {
        userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (authErr) {
        // If the user attempts to sign in as admin and they don't exist, we create them
        // BUT only if they are using the specific admin email/password we defined
        if ((authErr.code == 'user-not-found' ||
                authErr.code == 'invalid-credential') &&
            email == 'admin@admin.com' &&
            password == 'admin123') {
          userCredential = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(email: email, password: password);
        } else {
          rethrow;
        }
      }

      await firebaseService.createOrUpdateUser(
        userCredential.user!.uid,
        userCredential.user!.email!,
        'Global Admin',
        true,
      );
      await NotificationService.saveTokenToFirestore(userCredential.user!.uid);

      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        String message = e.toString();
        if (message.contains('invalid-credential')) {
          message = "Invalid credentials. Access Denied.";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Admin Login Failed: $message"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _AmbientEplBackground(
        child: Stack(
          children: [
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 40,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Hero(
                                  tag: 'logo',
                                  child: _ClassyLogo(
                                    controller: _logoController,
                                    size: Responsive.sp(context, 124),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                Text(
                                  "EFOOTBALL™ 2025/26",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppTheme.accentGreen,
                                    fontSize: Responsive.sp(context, 26),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "THE EVOLUTION OF REALISM",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: Responsive.sp(context, 10),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 3,
                                  ),
                                ),
                                const SizedBox(height: 48),
                                if (_isLoading)
                                  const CircularProgressIndicator(
                                    color: AppTheme.accentGreen,
                                  )
                                else ...[
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 320,
                                    ),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: _PremiumAuthButton(
                                        onPressed: _signInWithGoogle,
                                        icon: Icons.login_rounded,
                                        label: "SIGN IN WITH GOOGLE",
                                        fontSize: Responsive.sp(context, 14),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 320,
                                    ),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: _AdminAuthButton(
                                        onPressed: _showAdminLoginDialog,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 32),
                                Text(
                                  "Sign in to save your results and\ntrack your league progress.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmbientEplBackground extends StatelessWidget {
  const _AmbientEplBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF22002B),
            Color(0xFF38003C),
            Color(0xFF4B0067),
            Color(0xFF101C68),
          ],
          stops: [0.0, 0.42, 0.72, 1.0],
        ),
      ),
      child: CustomPaint(painter: _AmbientEplPainter(), child: child),
    );
  }
}

class _AmbientEplPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final blueRibbon = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x002FD8FF), Color(0x662FD8FF), Color(0x00FFFFFF)],
      ).createShader(Offset.zero & size);

    final whiteMist = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.16),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Offset.zero & size);

    final violetSheen = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0x00FFFFFF), Color(0x668600FF), Color(0x0010D7FF)],
      ).createShader(Offset.zero & size);

    final bluePath = Path()
      ..moveTo(size.width * 0.55, 0)
      ..cubicTo(
        size.width * 0.95,
        size.height * 0.18,
        size.width * 0.65,
        size.height * 0.55,
        size.width,
        size.height * 0.78,
      )
      ..lineTo(size.width, size.height)
      ..cubicTo(
        size.width * 0.55,
        size.height * 0.72,
        size.width * 0.78,
        size.height * 0.24,
        size.width * 0.3,
        0,
      )
      ..close();

    final mistPath = Path()
      ..moveTo(0, size.height * 0.26)
      ..cubicTo(
        size.width * 0.34,
        size.height * 0.2,
        size.width * 0.58,
        size.height * 0.35,
        size.width,
        size.height * 0.28,
      )
      ..lineTo(size.width, size.height * 0.43)
      ..cubicTo(
        size.width * 0.63,
        size.height * 0.5,
        size.width * 0.3,
        size.height * 0.34,
        0,
        size.height * 0.42,
      )
      ..close();

    final violetPath = Path()
      ..moveTo(0, size.height)
      ..cubicTo(
        size.width * 0.26,
        size.height * 0.7,
        size.width * 0.7,
        size.height * 0.82,
        size.width,
        size.height * 0.54,
      )
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(bluePath, blueRibbon);
    canvas.drawPath(mistPath, whiteMist);
    canvas.drawPath(violetPath, violetSheen);

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (var i = -2; i < 8; i++) {
      final y = size.height * 0.12 + i * size.height * 0.13;
      canvas.drawLine(
        Offset(-size.width * 0.15, y),
        Offset(size.width * 1.15, y + size.height * 0.16),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ClassyLogo extends StatelessWidget {
  const _ClassyLogo({required this.controller, required this.size});

  final AnimationController controller;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = controller.value * math.pi * 2;
        return Transform.translate(
          offset: Offset(0, math.sin(t) * 4),
          child: Transform.rotate(
            angle: math.sin(t) * 0.025,
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
                    color: const Color(0xFF2FD8FF).withValues(alpha: 0.26),
                    blurRadius: 34,
                    spreadRadius: 4,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: AppTheme.primaryPurple.withValues(alpha: 0.46),
                    blurRadius: 28,
                    offset: const Offset(0, 16),
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

class _PremiumAuthButton extends StatelessWidget {
  const _PremiumAuthButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.fontSize,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: EdgeInsets.symmetric(vertical: Responsive.sp(context, 17)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFEAF8FF)],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.88),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppTheme.primaryPurple, size: 22),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: fontSize,
                      color: AppTheme.primaryPurple,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminAuthButton extends StatelessWidget {
  const _AdminAuthButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.admin_panel_settings_rounded, size: 18),
      label: Text(
        "LOG IN AS ADMIN",
        style: TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: 1.1,
          fontSize: Responsive.sp(context, 12),
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.34)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white.withValues(alpha: 0.08),
      ),
    );
  }
}
