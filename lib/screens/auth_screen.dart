import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../data/firebase_service.dart';
import '../data/notification_service.dart';
// Removed unused import

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoading = false;

  Future<void> _showAdminLoginDialog() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.primaryPurple,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppTheme.accentGreen, width: 2)),
        title: Text("ADMIN CLEARANCE", style: GoogleFonts.outfit(color: AppTheme.accentGreen, fontWeight: FontWeight.w900, letterSpacing: 2)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              style: const TextStyle(color: Colors.white),
              decoration: AppTheme.getAuthInputDecoration("Email", Icons.email_outlined),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: AppTheme.getAuthInputDecoration("Password", Icons.lock_outline),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CANCEL", style: GoogleFonts.outfit(color: Colors.white60, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleAdminLogin(emailController.text.trim(), passwordController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGreen,
              foregroundColor: AppTheme.primaryPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("ACCESS", style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      if (kIsWeb) {
        final authProvider = GoogleAuthProvider();
        await FirebaseAuth.instance.signInWithPopup(authProvider);
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        
        if (googleUser == null) {
          setState(() => _isLoading = false);
          return;
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await FirebaseAuth.instance.signInWithCredential(credential);
      }
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && mounted) {
        final firebaseService = context.read<FirebaseService>();
        await firebaseService.createOrUpdateUser(user.uid, user.email!);
        await NotificationService.saveTokenToFirestore(user.uid);
        
        if (mounted) {
          // Skip mandatory league registration as requested
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Authentication Failed: $e', style: const TextStyle(color: Colors.white))));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAdminLogin(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter both email and password.")));
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
        if ((authErr.code == 'user-not-found' || authErr.code == 'invalid-credential') && 
            email == 'admin@admin.com' && password == 'admin123') {
          userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
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
        if (message.contains('invalid-credential')) message = "Invalid credentials. Access Denied.";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Admin Login Failed: $message"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppTheme.headerGradient,
        ),
        child: Stack(
          children: [
            Opacity(
              opacity: 0.07,
              child: Center(
                child: Image.asset(
                  'assets/efootballlogo/efllogo.jpeg',
                  height: 600,
                  errorBuilder: (_, _, _) => const SizedBox(),
                ),
              ),
            ),
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
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Hero(
                                  tag: 'logo',
                                  child: Container(
                                    width: 120, // Slightly increased from 100 for better presence
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primaryPurple.withValues(alpha: 0.4),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                          offset: const Offset(0, 5),
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
                                const SizedBox(height: 32),
                                Text(
                                  "EFOOTBALL™ 2025/26",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    color: AppTheme.accentGreen, 
                                    fontSize: 26, 
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "THE EVOLUTION OF REALISM",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withValues(alpha: 0.8), 
                                    fontSize: 10, 
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 3,
                                  ),
                                ),
                                const SizedBox(height: 48),
                                if (_isLoading)
                                  const CircularProgressIndicator(color: AppTheme.accentGreen)
                                else ...[
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 320),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.login, color: AppTheme.primaryPurple),
                                        label: Text(
                                          "SIGN IN WITH GOOGLE", 
                                          style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.primaryPurple, fontWeight: FontWeight.w900, letterSpacing: 1)
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 18),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          elevation: 5,
                                        ),
                                        onPressed: _signInWithGoogle,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 320),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: TextButton(
                                        onPressed: _showAdminLoginDialog,
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        child: const Text("LOG IN AS ADMIN", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 32),
                                Text(
                                  "Sign in to save your results and\ntrack your league progress.",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
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
