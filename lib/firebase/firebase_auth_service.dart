import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService {
  static const _webClientId =
      '679587606372-dparr4ipppihjculmvl2pi013584mm09.apps.googleusercontent.com';
  static const _iosClientId =
      '679587606372-om64k2vf3lbscg1j5n1fluroiv2jradu.apps.googleusercontent.com';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
    clientId: defaultTargetPlatform == TargetPlatform.iOS ? _iosClientId : null,
    serverClientId: _webClientId,
  );
  static Future<User?>? _restore;

  User? get currentUser => _auth.currentUser;

  static Future<User?> ensureRestored() {
    _restore ??= FirebaseAuthService().restoreSession();
    return _restore!.then((_) => FirebaseAuth.instance.currentUser);
  }

  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<User?> restoreSession() async {
    final existing = _auth.currentUser;
    if (existing != null) return existing;
    try {
      final googleUser = await _googleSignIn.signInSilently();
      if (googleUser == null) return _auth.currentUser;
      final credential = await _credentialFor(googleUser);
      final signedIn = await _auth.signInWithCredential(credential);
      return signedIn.user ?? _auth.currentUser;
    } catch (_) {
      return _auth.currentUser;
    }
  }

  Future<UserCredential> loginWithGoogle() async {
    final silent = await _googleSignIn.signInSilently();
    if (silent != null) {
      try {
        return await _auth.signInWithCredential(await _credentialFor(silent));
      } catch (_) {}
    }

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('google-canceled');
    }

    return await _auth.signInWithCredential(await _credentialFor(googleUser));
  }

  Future<AuthCredential> _credentialFor(GoogleSignInAccount googleUser) async {
    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception('google-empty-token');
    }
    return GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: idToken,
    );
  }

  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}
