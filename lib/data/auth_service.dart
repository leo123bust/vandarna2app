import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/firebase_config.dart';
import '../domain/models.dart';

abstract class AuthService {
  Stream<AppUser?> userChanges();
  Future<void> signIn(String email, String password);
  Future<void> register(String username, String email, String password);
  Future<void> signInWithGoogle();
  Future<void> resetPassword(String email);
  Future<void> signOut();
  Future<void> updatePhoto(String path);
}

/// Demo mode: a single local guest profile. Real accounts need Firebase (see README).
class LocalAuthService implements AuthService {
  static const _msg = 'Акаунтите изискват конфигуриран Firebase (виж README).';

  @override
  Stream<AppUser?> userChanges() => Stream.value(
        AppUser(uid: 'local-guest', username: 'Гост (демо)', createdAt: DateTime.now(), isGuest: true),
      );
  @override
  Future<void> signIn(String email, String password) => Future.error(UnsupportedError(_msg));
  @override
  Future<void> register(String username, String email, String password) => Future.error(UnsupportedError(_msg));
  @override
  Future<void> signInWithGoogle() => Future.error(UnsupportedError(_msg));
  @override
  Future<void> resetPassword(String email) => Future.error(UnsupportedError(_msg));
  @override
  Future<void> signOut() async {}
  @override
  Future<void> updatePhoto(String path) => Future.error(UnsupportedError(_msg));
}

class FirebaseAuthService implements AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  AppUser? _map(User? u) {
    if (u == null) return null;
    final name = (u.displayName?.isNotEmpty ?? false) ? u.displayName! : (u.email?.split('@').first ?? 'Потребител');
    return AppUser(
      uid: u.uid,
      username: name,
      email: u.email,
      photoUrl: u.photoURL,
      createdAt: u.metadata.creationTime ?? DateTime.now(),
    );
  }

  Future<void> _ensureProfile(User u, {String? username}) => _db.collection('users').doc(u.uid).set({
        'username': username ?? u.displayName ?? u.email?.split('@').first ?? 'Потребител',
        'photoUrl': u.photoURL,
        'createdAt': (u.metadata.creationTime ?? DateTime.now()).millisecondsSinceEpoch,
      }, SetOptions(merge: true));

  @override
  Stream<AppUser?> userChanges() => _auth.userChanges().map(_map);

  @override
  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  @override
  Future<void> register(String username, String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
    final user = cred.user!;
    await user.updateDisplayName(username.trim());
    await _ensureProfile(user, username: username.trim());
  }

  @override
  Future<void> signInWithGoogle() async {
    final google = GoogleSignIn(
      serverClientId: FirebaseConfig.googleServerClientId.isEmpty ? null : FirebaseConfig.googleServerClientId,
    );
    final account = await google.signIn();
    if (account == null) return; // cancelled
    final tokens = await account.authentication;
    final credential = GoogleAuthProvider.credential(accessToken: tokens.accessToken, idToken: tokens.idToken);
    final result = await _auth.signInWithCredential(credential);
    await _ensureProfile(result.user!);
  }

  @override
  Future<void> resetPassword(String email) => _auth.sendPasswordResetEmail(email: email.trim());

  @override
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  @override
  Future<void> updatePhoto(String path) async {
    final user = _auth.currentUser!;
    final ref = FirebaseStorage.instance.ref('avatars/${user.uid}.jpg');
    await ref.putFile(File(path), SettableMetadata(contentType: 'image/jpeg'));
    final url = await ref.getDownloadURL();
    await user.updatePhotoURL(url);
    await _db.collection('users').doc(user.uid).set({'photoUrl': url}, SetOptions(merge: true));
  }
}
