import 'package:bladna/app.dart';
import 'package:bladna/core/app_config.dart';
import 'package:bladna/data/repositories/progress_repository.dart';
import 'package:bladna/features/explore/explore_screen.dart';
import 'package:bladna/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The map has looping animations, so tests advance time with pump(duration).
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> launch(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final repo = ProgressRepository(await SharedPreferences.getInstance());
  await tester.pumpWidget(BladnaApp(
    repository: repo,
    clock: () => DateTime(2026, 10, 21, 9),
    config: const AppConfig(networkTiles: false, showSplash: false),
  ));
  await settle(tester);
}

Future<void> tapVisible(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
  await settle(tester);
}

Future<void> enterAsGuest(WidgetTester tester) async {
  await tapVisible(tester, find.text('Continue as guest'));
  await tester.enterText(find.byType(TextField).last, 'Tester');
  await tapVisible(tester, find.text('Start exploring'));
}

void main() {
  testWidgets('sign-in is the entry point and explains missing configuration', (tester) async {
    await launch(tester);
    expect(find.text('Continue as guest'), findsOneWidget);
    expect(find.byType(ExploreScreen), findsNothing);

    await tester.enterText(find.byType(TextFormField).at(0), 'farah@example.tn');
    await tester.enterText(find.byType(TextFormField).at(1), 'longpassword');
    await tapVisible(tester, find.widgetWithText(Material, 'Sign in').last);
    expect(find.textContaining('not configured'), findsWidgets);
    expect(find.byType(ExploreScreen), findsNothing);
  });

  testWidgets('guest lands directly on the map; tapping a place opens its panel', (tester) async {
    await launch(tester);
    await enterAsGuest(tester);
    expect(find.byType(ExploreScreen), findsOneWidget);
    final game = tester.element(find.byType(ExploreScreen)).read<GameController>();
    expect(game.progress.onboardingDone, isTrue);

    await tapVisible(tester, find.byKey(const ValueKey('site-medina')));
    expect(find.text('Medina of Tunis'), findsWidgets);
    expect(find.text('Field Training'), findsWidgets);
  });

  testWidgets('a mission opens as a focused activity and returns to the map', (tester) async {
    await launch(tester);
    await enterAsGuest(tester);
    await tapVisible(tester, find.byKey(const ValueKey('site-medina')));
    await tapVisible(tester, find.textContaining('Investigate:'));
    expect(find.text('Medina of Tunis · sorting'), findsOneWidget);
    await tapVisible(tester, find.byTooltip('Back to the map'));
    expect(find.byType(ExploreScreen), findsOneWidget);
    expect(find.text('Medina of Tunis'), findsWidgets, reason: 'the place stays selected');
  });
}
