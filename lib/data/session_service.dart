import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class SessionService {
  static const _rememberUntilField = 'rememberSessionUntil';
  static const _rememberEnabledField = 'rememberSessionEnabled';
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
    final expiresAt = rememberMe
        ? DateTime.now().add(rememberedDuration)
        : null;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      _rememberEnabledField: rememberMe,
      _rememberUntilField: expiresAt == null
          ? FieldValue.delete()
          : Timestamp.fromDate(expiresAt),
    }, SetOptions(merge: true));
  }

  static Future<bool> hasValidRememberedSession(User? user) async {
    if (user == null) return false;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = snapshot.data();
    final enabled = data?[_rememberEnabledField] == true;
    final rememberUntil = data?[_rememberUntilField];

    if (!enabled || rememberUntil is! Timestamp) return false;

    return DateTime.now().isBefore(rememberUntil.toDate());
  }

  static Future<bool> keepOrEndCurrentSession(User? user) async {
    if (user == null) return false;
    if (await hasValidRememberedSession(user)) return true;

    await clearRememberPreference();
    await FirebaseAuth.instance.signOut();
    return false;
  }

  static Future<void> clearRememberPreference() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      _rememberEnabledField: false,
      _rememberUntilField: FieldValue.delete(),
    }, SetOptions(merge: true));
  }
}
