import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Firebase values are injected at build time with --dart-define (see README / workflow).
/// Nothing secret is committed. Without them the app runs in local demo mode.
class FirebaseConfig {
  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const senderId = String.fromEnvironment('FIREBASE_SENDER_ID');
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static const googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  static bool get isConfigured => apiKey.isNotEmpty && appId.isNotEmpty && projectId.isNotEmpty;

  static const options = FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: senderId,
    projectId: projectId,
    storageBucket: storageBucket,
  );
}

/// Returns true when Firebase was initialised successfully.
Future<bool> initFirebase() async {
  if (!FirebaseConfig.isConfigured) return false;
  try {
    await Firebase.initializeApp(options: FirebaseConfig.options);
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: kReleaseMode ? AndroidProvider.playIntegrity : AndroidProvider.debug,
      );
    } catch (e) {
      debugPrint('App Check not active: $e');
    }
    return true;
  } catch (e) {
    debugPrint('Firebase init failed: $e');
    return false;
  }
}

/// Asks for notification permission and stores the FCM token on the user profile.
Future<void> registerForPush(String uid) async {
  try {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    final token = await messaging.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({'fcmToken': token}, SetOptions(merge: true));
    }
  } catch (e) {
    debugPrint('Push registration failed: $e');
  }
}
