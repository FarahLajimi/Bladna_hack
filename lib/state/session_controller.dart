import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth/auth_service.dart';

enum SessionKind { none, guest, account }

/// Who is playing. A GUEST is a local profile on this device (no account,
/// nothing synced). An ACCOUNT exists only when a real provider is configured.
/// Only the session kind and display name are stored — never a password.
class SessionController extends ChangeNotifier {
  SessionController({required SharedPreferences prefs, AuthService auth = const UnconfiguredAuthService()})
      : _prefs = prefs,
        _auth = auth {
    _load();
  }

  static const String key = 'bladna.session.v1';

  final SharedPreferences _prefs;
  final AuthService _auth;

  SessionKind _kind = SessionKind.none;
  String _name = '';
  String? _email;

  AuthService get auth => _auth;
  SessionKind get kind => _kind;
  bool get isSignedIn => _kind != SessionKind.none;
  bool get isGuest => _kind == SessionKind.guest;
  String get displayName => _name.isEmpty ? 'Field explorer' : _name;
  String? get email => _email;

  void _load() {
    final user = _auth.currentUser;
    if (user != null) {
      _kind = SessionKind.account;
      _name = user.displayName ?? '';
      _email = user.email;
      return;
    }
    final raw = _prefs.getString(key);
    if (raw == null) return;
    try {
      final m = jsonDecode(raw);
      if (m is Map && m['kind'] == 'guest') {
        _kind = SessionKind.guest;
        _name = m['name'] is String ? m['name'] as String : '';
      }
    } catch (_) {
      // Corrupt session: start signed out.
    }
  }

  Future<void> continueAsGuest(String name) async {
    _kind = SessionKind.guest;
    _name = name.trim();
    _email = null;
    await _prefs.setString(key, jsonEncode({'kind': 'guest', 'name': _name}));
    notifyListeners();
  }

  /// Throws [AuthNotConfigured] or [AuthFailure].
  Future<void> signIn(String email, String password) async {
    final user = await _auth.signIn(email: email.trim(), password: password);
    _setAccount(user);
  }

  Future<void> createAccount(String name, String email, String password) async {
    final user = await _auth.createAccount(email: email.trim(), password: password, displayName: name.trim());
    _setAccount(user);
  }

  Future<void> sendPasswordReset(String email) => _auth.sendPasswordReset(email.trim());

  void _setAccount(AuthUser user) {
    _kind = SessionKind.account;
    _name = user.displayName ?? '';
    _email = user.email;
    _prefs.remove(key);
    notifyListeners();
  }

  /// Signs out. Local game progress is NOT erased: it stays on this device
  /// and is there again when the player comes back.
  Future<void> signOut() async {
    if (_kind == SessionKind.account) await _auth.signOut();
    await _prefs.remove(key);
    _kind = SessionKind.none;
    _email = null;
    notifyListeners();
  }
}
