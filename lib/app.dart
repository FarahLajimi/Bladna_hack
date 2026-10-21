import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_config.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/progress_repository.dart';
import 'features/auth/welcome_screen.dart';
import 'features/explore/explore_screen.dart';
import 'features/splash/splash_screen.dart';
import 'services/auth/auth_service.dart';
import 'state/game_controller.dart';
import 'state/session_controller.dart';

class BladnaApp extends StatelessWidget {
  const BladnaApp({
    super.key,
    required this.repository,
    this.clock,
    this.auth = const UnconfiguredAuthService(),
    this.config = const AppConfig(),
  });

  final ProgressRepository repository;
  final DateTime Function()? clock;

  /// Swap for a FirebaseAuthService once configured (docs/FIREBASE_SETUP.md).
  final AuthService auth;
  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppConfig>.value(value: config),
        ChangeNotifierProvider(create: (_) => GameController(repository: repository, clock: clock)),
        ChangeNotifierProvider(create: (_) => SessionController(prefs: repository.prefs, auth: auth)),
      ],
      child: MaterialApp(
        title: 'BLADNA',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const _Root(),
      ),
    );
  }
}

/// Splash → sign-in (first time) → the map.
class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  late bool _splash = context.read<AppConfig>().showSplash;

  @override
  Widget build(BuildContext context) {
    final signedIn = context.select<SessionController, bool>((s) => s.isSignedIn);
    final Widget child = _splash
        ? SplashScreen(key: const ValueKey('splash'), onDone: () => setState(() => _splash = false))
        : (signedIn ? const ExploreScreen(key: ValueKey('explore')) : const WelcomeScreen(key: ValueKey('welcome')));
    return AnimatedSwitcher(duration: const Duration(milliseconds: 380), child: child);
  }
}
