/// Authentication seam.
///
/// This build ships [UnconfiguredAuthService]: the sign-in and account
/// screens are real, but no identity provider is connected, so every account
/// call fails with [AuthNotConfigured] and the UI says so. Players can use a
/// clearly labelled local guest profile instead.
///
/// To enable real accounts, implement this interface with Firebase
/// Authentication (see docs/FIREBASE_SETUP.md for the exact steps and a
/// ready-to-paste implementation) and pass it to BladnaApp.
///
/// Passwords are only ever handed to the provider's SDK — BLADNA never
/// stores them, locally or anywhere else.
abstract class AuthService {
  /// True when a real provider is connected.
  bool get isConfigured;

  /// Human-readable provider name ("Firebase Authentication", …).
  String get providerName;

  /// The signed-in account, or null.
  AuthUser? get currentUser;

  Future<AuthUser> signIn({required String email, required String password});

  Future<AuthUser> createAccount({required String email, required String password, String? displayName});

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();
}

class AuthUser {
  const AuthUser({required this.uid, required this.email, this.displayName});
  final String uid;
  final String email;
  final String? displayName;
}

class AuthNotConfigured implements Exception {
  const AuthNotConfigured();

  @override
  String toString() =>
      'Account sign-in is not configured in this build yet. Continue as a guest — your progress stays on this phone.';
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

class UnconfiguredAuthService implements AuthService {
  const UnconfiguredAuthService();

  @override
  bool get isConfigured => false;

  @override
  String get providerName => 'Not configured';

  @override
  AuthUser? get currentUser => null;

  @override
  Future<AuthUser> signIn({required String email, required String password}) async => throw const AuthNotConfigured();

  @override
  Future<AuthUser> createAccount({required String email, required String password, String? displayName}) async =>
      throw const AuthNotConfigured();

  @override
  Future<void> sendPasswordReset(String email) async => throw const AuthNotConfigured();

  @override
  Future<void> signOut() async {}
}

/// Form validation shared by the sign-in screens.
class AuthValidators {
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Enter your email address.';
    if (!_email.hasMatch(s)) return 'That email address doesn\'t look right.';
    return null;
  }

  static String? password(String? v) {
    final s = v ?? '';
    if (s.isEmpty) return 'Enter your password.';
    if (s.length < 8) return 'Use at least 8 characters.';
    return null;
  }

  static String? name(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Choose a name for your field book.';
    if (s.length > 30) return 'Keep it under 30 characters.';
    return null;
  }
}
