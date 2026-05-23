import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const _rememberedUidKey = 'remembered_uid';
  static const _rememberUntilKey = 'remember_until_ms';
  static const rememberedDuration = Duration(days: 30);

  static Future<void> prepareAuthPersistence({required bool rememberMe}) async {
    if (!kIsWeb) return;

    await FirebaseAuth.instance.setPersistence(
      rememberMe ? Persistence.LOCAL : Persistence.SESSION,
    );
  }

  static Future<void> saveRememberPreference({
    required User user,
    required bool rememberMe,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (!rememberMe) {
      await clearRememberPreference();
      return;
    }

    final expiresAt = DateTime.now().add(rememberedDuration);
    await prefs.setString(_rememberedUidKey, user.uid);
    await prefs.setInt(_rememberUntilKey, expiresAt.millisecondsSinceEpoch);
  }

  static Future<bool> hasValidRememberedSession(User? user) async {
    if (user == null) return false;

    final prefs = await SharedPreferences.getInstance();
    final rememberedUid = prefs.getString(_rememberedUidKey);
    final rememberUntilMs = prefs.getInt(_rememberUntilKey);

    if (rememberedUid != user.uid || rememberUntilMs == null) return false;

    final rememberUntil = DateTime.fromMillisecondsSinceEpoch(rememberUntilMs);
    return DateTime.now().isBefore(rememberUntil);
  }

  static Future<bool> keepOrEndCurrentSession(User? user) async {
    if (user == null) return false;
    if (await hasValidRememberedSession(user)) return true;

    await clearRememberPreference();
    await FirebaseAuth.instance.signOut();
    return false;
  }

  static Future<void> clearRememberPreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rememberedUidKey);
    await prefs.remove(_rememberUntilKey);
  }
}
