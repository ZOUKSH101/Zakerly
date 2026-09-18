import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zakerly/ui/primitives/primitives.dart';

Widget _wrap(Widget child, {bool reduceMotion = false}) => MaterialApp(
      theme: buildTheme(Brightness.light),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(body: Center(child: child)),
      ),
    );

void main() {
  test('ZRing never turns red', () {
    for (final z in [ZTokens.light, ZTokens.dark]) {
      expect(ZRing.colorForFraction(z, 0.5), z.accent);
      expect(ZRing.colorForFraction(z, 0.8), z.warning);
      expect(ZRing.colorForFraction(z, 1.0), z.warning);
    }
  });

  test('scrim is ~70% black in both themes', () {
    expect(ZTokens.light.scrim, const Color(0xB3000000));
    expect(ZTokens.dark.scrim, const Color(0xB3000000));
  });

  testWidgets('ZSegmented marks the selected segment', (tester) async {
    await tester.pumpWidget(_wrap(SizedBox(
      width: 240,
      child: ZSegmented<int>(
        segments: const [(0, 'One'), (1, 'Two')],
        selected: 1,
        onChanged: (_) {},
      ),
    )));
    expect(
      tester.getSemantics(find.text('Two')),
      isSemantics(isSelected: true, isInMutuallyExclusiveGroup: true),
    );
    expect(
      tester.getSemantics(find.text('One')),
      isSemantics(isSelected: false, isInMutuallyExclusiveGroup: true),
    );
  });

  testWidgets('ZIconButton keeps a 32px chip inside a 44px hit area', (tester) async {
    await tester.pumpWidget(_wrap(ZIconButton(icon: Icons.close, tooltip: 'Close', onPressed: () {})));
    expect(tester.getSize(find.byType(Pressable)), const Size(44, 44));
    expect(tester.getSize(find.byType(AnimatedContainer)), const Size(32, 32));
  });

  testWidgets('ZEmpty draws its pen illustration on, and shows it at once with reduced motion',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const ZEmpty(icon: Icons.chat_bubble_outline, title: 'Nothing yet', art: ZEmptyArt.bubble),
      reduceMotion: true,
    ));
    expect(find.byType(ZPenDrawing), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);

    await tester.pumpWidget(_wrap(
      const ZEmpty(key: ValueKey('b'), icon: Icons.inbox, title: 'Nothing yet'),
    ));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
  });

  testWidgets('showZDialog: exits in ZMotion.exit, and skips the overshoot with reduced motion',
      (tester) async {
    await tester.pumpWidget(_wrap(
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showZDialog<void>(context, builder: (_) => const Text('dialog')),
          child: const Text('open'),
        ),
      ),
      reduceMotion: true,
    ));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(ZMotion.exit);
    expect(find.text('dialog'), findsOneWidget);

    Navigator.of(tester.element(find.text('dialog'))).pop();
    await tester.pump();
    await tester.pump(ZMotion.exit + const Duration(milliseconds: 1));
    expect(find.text('dialog'), findsNothing);
  });
}
