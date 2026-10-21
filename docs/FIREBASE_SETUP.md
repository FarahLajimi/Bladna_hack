# Enabling real accounts with Firebase Authentication

This build ships **no** identity provider: the sign-in screens validate input and then explain that accounts are not configured. Guests play with a local profile. Follow these steps to connect Firebase. Nothing here requires a secret in the source code — Firebase Android config values identify the app; restrict them in the Firebase/Google Cloud console.

## 1. Firebase console

1. https://console.firebase.google.com → **Add project** (e.g. `bladna`).
2. **Build → Authentication → Get started → Sign-in method → Email/Password → Enable.**
3. **Project settings → Your apps → Add app → Android**, package name `tn.greenhackathon2026.bladna`.
4. Download `google-services.json`. Put it at `android_overrides/app/google-services.json` (the workflow copies it into the generated Android folder).
5. In the same settings page note: **Web API key**, **App ID**, **Project ID**, **Sender ID**.

## 2. Code

`pubspec.yaml` → add under dependencies:

```yaml
  firebase_core: ^3.0.0
  firebase_auth: ^5.0.0
```
(check pub.dev for the current versions).

Create `lib/firebase_options.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';

const firebaseAndroidOptions = FirebaseOptions(
  apiKey: 'YOUR_WEB_API_KEY',
  appId: 'YOUR_APP_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
);
```

Create `lib/services/auth/firebase_auth_service.dart`:

```dart
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'auth_service.dart';

class FirebaseAuthService implements AuthService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;

  @override
  bool get isConfigured => true;

  @override
  String get providerName => 'Firebase Authentication';

  @override
  AuthUser? get currentUser => _map(_auth.currentUser);

  AuthUser? _map(fb.User? u) => u == null ? null : AuthUser(uid: u.uid, email: u.email ?? '', displayName: u.displayName);

  @override
  Future<AuthUser> signIn({required String email, required String password}) async {
    try {
      final c = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return _map(c.user)!;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthFailure(e.message ?? 'Sign-in failed.');
    }
  }

  @override
  Future<AuthUser> createAccount({required String email, required String password, String? displayName}) async {
    try {
      final c = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (displayName != null && displayName.isNotEmpty) await c.user?.updateDisplayName(displayName);
      return AuthUser(uid: c.user!.uid, email: email, displayName: displayName);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthFailure(e.message ?? 'Account creation failed.');
    }
  }

  @override
  Future<void> sendPasswordReset(String email) => _auth.sendPasswordResetEmail(email: email);

  @override
  Future<void> signOut() => _auth.signOut();
}
```

In `lib/main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth/firebase_auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseAndroidOptions);
  final repository = await ProgressRepository.open();
  runApp(BladnaApp(repository: repository, auth: FirebaseAuthService()));
}
```

## 3. Notes

- `firebase_auth` may need a higher Android `minSdkVersion` than the Flutter default; if the build says so, set it in `android/app/build.gradle(.kts)` (or add that file to `android_overrides/`).
- Progress stays local even when signed in. Syncing it to an account (e.g. Cloud Firestore keyed by `uid`) is a separate feature and is **not** implemented.
- Test sign-in, account creation, password reset and sign-out on a device before claiming they work.
