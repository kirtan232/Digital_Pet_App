import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:digital_pet_app/main.dart';

void main() {
  testWidgets('App launches to the digital pet screen', (tester) async {
    await tester.pumpWidget(const DigitalPetApp());

    expect(find.byType(DigitalPetScreen), findsOneWidget);
    expect(find.text('Digital Pet'), findsOneWidget);
  });

  testWidgets('Pet starts with initial state and neutral mood', (tester) async {
    await tester.pumpWidget(const DigitalPetApp());

    expect(find.text('Pip'), findsOneWidget);
    expect(find.text('Neutral'), findsOneWidget);
    expect(find.text('Happiness'), findsOneWidget);
    expect(find.text('Hunger'), findsOneWidget);
    expect(find.text('50 / 100'), findsNWidgets(2));
    expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
    expect(find.text('Status: Playing'), findsOneWidget);
  });

  testWidgets('Pet image is tinted with the neutral mood color', (tester) async {
    await tester.pumpWidget(const DigitalPetApp());

    final filtered = tester.widget<ColorFiltered>(find.byType(ColorFiltered));
    expect(
      filtered.colorFilter,
      const ColorFilter.mode(Colors.yellow, BlendMode.modulate),
    );
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('Confirming a name updates the pet name', (tester) async {
    await tester.pumpWidget(const DigitalPetApp());

    await tester.enterText(find.byType(TextField), '  Mochi  ');
    await tester.tap(find.text('Confirm'));
    await tester.pump();

    expect(find.text('Mochi'), findsOneWidget);
    expect(find.text('Pip'), findsNothing);
  });

  testWidgets('Blank name is ignored', (tester) async {
    await tester.pumpWidget(const DigitalPetApp());

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('Confirm'));
    await tester.pump();

    expect(find.text('Pip'), findsOneWidget);
  });

  group('Care actions', () {
    Future<void> tapTimes(WidgetTester tester, String label, int times) async {
      for (var i = 0; i < times; i++) {
        await tester.tap(find.text(label));
        await tester.pump();
      }
    }

    testWidgets('Play raises happiness by 10 and hunger by 5', (tester) async {
      await tester.pumpWidget(const DigitalPetApp());

      await tapTimes(tester, 'Play', 1);

      expect(find.bySemanticsLabel('Happiness: 60 out of 100'), findsOneWidget);
      expect(find.bySemanticsLabel('Hunger: 55 out of 100'), findsOneWidget);
    });

    testWidgets('Feed lowers hunger by 10 and raises happiness by 10',
        (tester) async {
      await tester.pumpWidget(const DigitalPetApp());

      await tapTimes(tester, 'Feed', 1);

      expect(find.bySemanticsLabel('Hunger: 40 out of 100'), findsOneWidget);
      expect(find.bySemanticsLabel('Happiness: 60 out of 100'), findsOneWidget);
    });

    testWidgets('Overfeeding (hunger below 30) costs 20 happiness',
        (tester) async {
      await tester.pumpWidget(const DigitalPetApp());

      // 50 -> 40 -> 30 (happiness +10, +10), then 30 -> 20 is overfed (-20).
      await tapTimes(tester, 'Feed', 3);

      expect(find.bySemanticsLabel('Hunger: 20 out of 100'), findsOneWidget);
      expect(find.bySemanticsLabel('Happiness: 50 out of 100'), findsOneWidget);
    });

    testWidgets('Meters clamp at 0 and 100', (tester) async {
      await tester.pumpWidget(const DigitalPetApp());

      // Play 6x: happiness 50 -> 100 (clamped), hunger 50 -> 80.
      await tapTimes(tester, 'Play', 6);
      expect(find.bySemanticsLabel('Happiness: 100 out of 100'), findsOneWidget);

      // Feed 10x: hunger 80 -> 0 (clamped), never negative.
      await tapTimes(tester, 'Feed', 10);
      expect(find.bySemanticsLabel('Hunger: 0 out of 100'), findsOneWidget);
    });

    testWidgets('Mood and tint follow happiness', (tester) async {
      await tester.pumpWidget(const DigitalPetApp());

      // 50 -> 80: above 70 is Happy/green.
      await tapTimes(tester, 'Play', 3);

      expect(find.text('Happy'), findsOneWidget);
      final filtered = tester.widget<ColorFiltered>(find.byType(ColorFiltered));
      expect(
        filtered.colorFilter,
        const ColorFilter.mode(Colors.green, BlendMode.modulate),
      );
    });
  });

  testWidgets('Meters and mood expose accessible labels', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const DigitalPetApp());

    expect(find.bySemanticsLabel('Mood: Neutral'), findsOneWidget);
    expect(find.bySemanticsLabel('Happiness: 50 out of 100'), findsOneWidget);
    expect(find.bySemanticsLabel('Hunger: 50 out of 100'), findsOneWidget);
    handle.dispose();
  });
}
