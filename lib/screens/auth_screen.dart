import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      if (kIsWeb) {
        // Web uses Firebase's robust built-in browser popup provider
        final authProvider = GoogleAuthProvider();
        await FirebaseAuth.instance.signInWithPopup(authProvider);
      } else {
        // Native Mobile (iOS/Android) uses the local system account prompt
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        
        if (googleUser == null) {
          setState(() => _isLoading = false);
          return; // User canceled
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await FirebaseAuth.instance.signInWithCredential(credential);
      }
      
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Authentication Failed: $e', style: const TextStyle(color: Colors.white))));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.headerGradient,
        ),
        child: Stack(
          children: [
            // Background Pattern
            Opacity(
              opacity: 0.1,
              child: Center(
                child: Icon(Icons.sports_soccer, size: 500, color: Colors.white.withOpacity(0.2)),
              ),
            ),
            
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Hero(
                        tag: 'logo',
                        child: Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/ca/EFootball_logo.svg/512px-EFootball_logo.svg.png',
                          width: 180,
                          color: Colors.white,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (_, __, ___) => const Icon(Icons.sports_esports, size: 100, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 48),
                      Text(
                        "EFOOTBALL™ 2025/26",
                        style: GoogleFonts.outfit(
                          color: AppTheme.accentGreen, 
                          fontSize: 28, 
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "THE EVOLUTION OF REALISM",
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.8), 
                          fontSize: 12, 
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 64),
                      if (_isLoading)
                        const CircularProgressIndicator(color: AppTheme.accentGreen)
                      else
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
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 10,
                              shadowColor: Colors.black.withOpacity(0.3),
                            ),
                            onPressed: _signInWithGoogle,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () => context.go('/home'),
                        child: Text(
                          "ENTER AS GUEST", 
                          style: GoogleFonts.outfit(
                            color: Colors.white70, 
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white30,
                          )
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
