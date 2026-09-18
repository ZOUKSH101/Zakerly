import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zakerly/core/app_services.dart';
import 'package:zakerly/ui/features/settings/settings_dialog.dart';
import 'package:zakerly/ui/features/sign_in/sign_in_screen.dart';
import 'package:zakerly/ui/theme.dart';

Widget _app(AppServices s, Widget home, {Brightness brightness = Brightness.dark}) {
  return Services(
    services: s,
    child: MaterialApp(theme: buildTheme(brightness), home: home),
  );
}

void main() {
  // Real metrics: the default test font draws every glyph as a full square,
  // which makes any layout look wider than it is.
  setUpAll(() async {
    final bytes = File('assets/fonts/ReadexPro-Variable.ttf').readAsBytesSync();
    final loader = FontLoader(ZType.fontFamily)
      ..addFont(Future.value(ByteData.sublistView(Uint8List.fromList(bytes))));
    await loader.load();
  });

  Future<void> setSize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('settings opens on General and every section fits at 1440x900', (tester) async {
    await setSize(tester, const Size(1440, 900));
    final s = AppServices.demo();
    addTearDown(s.scheduler.dispose);

    await tester.pumpWidget(_app(
      s,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showSettingsDialog(context),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // General is first, with Appearance and Language visible at once.
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Show tutorial again'), findsOneWidget);

    for (final section in ['General', 'Plan', 'Model keys', 'Account']) {
      await tester.tap(find.text(section).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: section);
      final scrollables = tester.stateList<ScrollableState>(find.byType(Scrollable));
      for (final sc in scrollables) {
        if (sc.position.axis == Axis.vertical) {
          expect(sc.position.maxScrollExtent, 0, reason: '$section should fit without scrolling');
        }
      }
    }
  });

  testWidgets('settings degrades to tabs on a phone without overflow', (tester) async {
    await setSize(tester, const Size(390, 844));
    final s = AppServices.demo();
    addTearDown(s.scheduler.dispose);

    await tester.pumpWidget(_app(
      s,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showSettingsDialog(context),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    for (final section in ['Plan', 'Model keys', 'Account', 'General']) {
      await tester.tap(find.text(section).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: section);
    }
  });

  for (final size in const [Size(1440, 900), Size(390, 844)]) {
    for (final b in Brightness.values) {
      testWidgets('sign-in lays out cleanly at $size in ${b.name}', (tester) async {
        await setSize(tester, size);
        final s = AppServices.demo();
        addTearDown(s.scheduler.dispose);
        await tester.pumpWidget(_app(s, const SignInScreen(), brightness: b));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Continue with Google'), findsOneWidget);
      });
    }
  }
}
