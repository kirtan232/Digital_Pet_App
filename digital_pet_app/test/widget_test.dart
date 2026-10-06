import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:digital_pet_app/main.dart';

/// Pumps the app in a tall test window so every control is on screen
/// (the default 800x600 test window cuts off the action buttons).
Future<void> pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const DigitalPetApp());
}

void main() {
  testWidgets('App launches to the digital pet screen', (tester) async {
    await pumpApp(tester);

    expect(find.byType(DigitalPetScreen), findsOneWidget);
    expect(find.text('Digital Pet'), findsOneWidget);
  });

  testWidgets('Pet starts with initial state and neutral mood', (tester) async {
    await pumpApp(tester);

    expect(find.text('Pip'), findsOneWidget);
    expect(find.text('Neutral'), findsOneWidget);
    expect(find.text('Happiness'), findsOneWidget);
    expect(find.text('Hunger'), findsOneWidget);
    expect(find.text('Energy'), findsOneWidget);
    expect(find.text('50 / 100'), findsNWidgets(2));
    expect(find.text('70 / 100'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(3));
    expect(find.text('Status: Playing'), findsOneWidget);
  });

  testWidgets('Pet image is tinted with the neutral mood color', (tester) async {
    await pumpApp(tester);

    final filtered = tester.widget<ColorFiltered>(find.byType(ColorFiltered));
    expect(
      filtered.colorFilter,
      const ColorFilter.mode(Colors.yellow, BlendMode.modulate),
    );
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('Confirming a name updates the pet name', (tester) async {
    await pumpApp(tester);

    await tester.enterText(find.byType(TextField), '  Mochi  ');
    await tester.tap(find.text('Confirm'));
    await tester.pump();

    expect(find.text('Mochi'), findsOneWidget);
    expect(find.text('Pip'), findsNothing);
  });

  testWidgets('Blank name is ignored', (tester) async {
    await pumpApp(tester);

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
      await pumpApp(tester);

      await tapTimes(tester, 'Play', 1);

      expect(find.bySemanticsLabel('Happiness: 60 out of 100'), findsOneWidget);
      expect(find.bySemanticsLabel('Hunger: 55 out of 100'), findsOneWidget);
    });

    testWidgets('Feed lowers hunger by 10 and raises happiness by 10',
        (tester) async {
      await pumpApp(tester);

      await tapTimes(tester, 'Feed', 1);

      expect(find.bySemanticsLabel('Hunger: 40 out of 100'), findsOneWidget);
      expect(find.bySemanticsLabel('Happiness: 60 out of 100'), findsOneWidget);
    });

    testWidgets('Overfeeding (hunger below 30) costs 20 happiness',
        (tester) async {
      await pumpApp(tester);

      // 50 -> 40 -> 30 (happiness +10, +10), then 30 -> 20 is overfed (-20).
      await tapTimes(tester, 'Feed', 3);

      expect(find.bySemanticsLabel('Hunger: 20 out of 100'), findsOneWidget);
      expect(find.bySemanticsLabel('Happiness: 50 out of 100'), findsOneWidget);
    });

    testWidgets('Meters clamp at 0 and 100', (tester) async {
      await pumpApp(tester);

      // Play 3x, Rest, Play 3x: happiness 50 -> 100 (clamped, not 110),
      // hunger 50 -> 85, energy 70 -> 5.
      await tapTimes(tester, 'Play', 3);
      await tapTimes(tester, 'Rest', 1);
      await tapTimes(tester, 'Play', 3);
      expect(find.bySemanticsLabel('Happiness: 100 out of 100'), findsOneWidget);
      expect(find.bySemanticsLabel('Hunger: 85 out of 100'), findsOneWidget);

      // Feed 10x: hunger 85 -> 0 (clamped), never negative.
      await tapTimes(tester, 'Feed', 10);
      expect(find.bySemanticsLabel('Hunger: 0 out of 100'), findsOneWidget);

      // Rest 5x: energy climbs and clamps at 100.
      await tapTimes(tester, 'Rest', 5);
      expect(find.bySemanticsLabel('Energy: 100 out of 100'), findsOneWidget);
    });

    testWidgets('Mood and tint follow happiness', (tester) async {
      await pumpApp(tester);

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

  group('Hunger timer', () {
    // Widget tests run on fake time, so pump(duration) fires timers instantly.
    const tick = Duration(seconds: 30);

    testWidgets('Hunger rises by 5 every 30 seconds', (tester) async {
      await pumpApp(tester);

      await tester.pump(const Duration(seconds: 29));
      expect(find.bySemanticsLabel('Hunger: 50 out of 100'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.bySemanticsLabel('Hunger: 55 out of 100'), findsOneWidget);

      await tester.pump(tick);
      expect(find.bySemanticsLabel('Hunger: 60 out of 100'), findsOneWidget);
    });

    testWidgets('Reaching 100 is free; ticks past 100 cost 20 happiness',
        (tester) async {
      await pumpApp(tester);

      // 10 ticks: 50 -> 100. The 95 -> 100 tick does not reduce happiness.
      for (var i = 0; i < 10; i++) {
        await tester.pump(tick);
      }
      expect(find.bySemanticsLabel('Hunger: 100 out of 100'), findsOneWidget);
      expect(find.bySemanticsLabel('Happiness: 50 out of 100'), findsOneWidget);

      // Next tick would overflow: hunger stays 100, happiness 50 -> 30.
      await tester.pump(tick);
      expect(find.bySemanticsLabel('Hunger: 100 out of 100'), findsOneWidget);
      expect(find.bySemanticsLabel('Happiness: 30 out of 100'), findsOneWidget);
    });

    testWidgets('Disposing the screen cancels the hunger timer',
        (tester) async {
      await pumpApp(tester);
      await tester.pumpWidget(const SizedBox());

      // If the timer were still alive it would call setState on an unmounted
      // State, or the test framework would report a pending timer.
      await tester.pump(tick * 3);
      expect(tester.takeException(), isNull);
    });
  });

  group('Outcomes', () {
    Future<void> tap(WidgetTester tester, String label, [int times = 1]) async {
      for (var i = 0; i < times; i++) {
        await tester.tap(find.text(label));
        await tester.pump();
      }
    }

    bool isEnabled(WidgetTester tester, String label) {
      final button = tester.widget<ButtonStyleButton>(find.ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      ));
      return button.onPressed != null;
    }

    testWidgets('Win after 3 minutes above 80, then actions lock',
        (tester) async {
      await pumpApp(tester);
      await tap(tester, 'Play', 4); // happiness 90, hunger 70

      await tester.pump(const Duration(minutes: 2, seconds: 59));
      expect(find.text('Status: Playing'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Status: You won!'), findsOneWidget);
      expect(find.textContaining('You win!'), findsOneWidget);
      expect(isEnabled(tester, 'Feed'), isFalse);
      expect(isEnabled(tester, 'Play'), isFalse);
    });

    testWidgets('Exactly 80 happiness never starts the win timer',
        (tester) async {
      await pumpApp(tester);
      await tap(tester, 'Play', 3); // happiness exactly 80

      await tester.pump(const Duration(minutes: 4));
      expect(find.text('Status: Playing'), findsOneWidget);
    });

    testWidgets('Dropping to 80 cancels the countdown; next crossing restarts',
        (tester) async {
      await pumpApp(tester);
      await tap(tester, 'Feed', 3); // hunger 20, happiness 50
      await tap(tester, 'Play', 4); // happiness 90 -> countdown starts at 0s

      await tester.pump(const Duration(minutes: 1)); // hunger 50
      await tap(tester, 'Feed', 3); // last feed overfeeds: happiness 80
      expect(find.bySemanticsLabel('Happiness: 80 out of 100'), findsOneWidget);

      await tap(tester, 'Play'); // happiness 90 -> fresh countdown at 60s

      // The cancelled countdown would have finished at 180s.
      await tester.pump(const Duration(seconds: 150)); // now 210s
      expect(find.text('Status: Playing'), findsOneWidget);

      await tester.pump(const Duration(seconds: 30)); // now 240s = 60s + 3min
      expect(find.text('Status: You won!'), findsOneWidget);
    });

    testWidgets('Loss when hunger is 100 and happiness is 10 or lower',
        (tester) async {
      await pumpApp(tester);

      // 10 ticks -> hunger 100; 2 more ticks -> happiness 50 -> 30 -> 10.
      await tester.pump(const Duration(seconds: 30 * 12));
      expect(find.text('Status: Game over'), findsOneWidget);
      expect(find.textContaining('Game over.'), findsOneWidget);
      expect(isEnabled(tester, 'Feed'), isFalse);
      expect(isEnabled(tester, 'Play'), isFalse);

      // Hunger timer is stopped: more time changes nothing.
      await tester.pump(const Duration(minutes: 5));
      expect(find.bySemanticsLabel('Happiness: 10 out of 100'), findsOneWidget);
    });
  });

  group('Reset', () {
    Future<void> tap(WidgetTester tester, String label, [int times = 1]) async {
      for (var i = 0; i < times; i++) {
        await tester.tap(find.text(label));
        await tester.pump();
      }
    }

    testWidgets('Reset after game over restores meters and unlocks actions',
        (tester) async {
      await pumpApp(tester);
      await tester.pump(const Duration(seconds: 30 * 12)); // loss
      expect(find.text('Status: Game over'), findsOneWidget);

      await tap(tester, 'Reset');

      expect(find.text('Status: Playing'), findsOneWidget);
      expect(find.textContaining('Game over.'), findsNothing);
      expect(find.bySemanticsLabel('Happiness: 50 out of 100'), findsOneWidget);
      expect(find.bySemanticsLabel('Hunger: 50 out of 100'), findsOneWidget);

      // Actions work again and the hunger timer is running again.
      await tap(tester, 'Play');
      expect(find.bySemanticsLabel('Happiness: 60 out of 100'), findsOneWidget);
      await tester.pump(const Duration(seconds: 30));
      expect(find.bySemanticsLabel('Hunger: 60 out of 100'), findsOneWidget);
    });

    testWidgets('Reset keeps the pet name', (tester) async {
      await pumpApp(tester);
      await tester.enterText(find.byType(TextField), 'Mochi');
      await tap(tester, 'Confirm');

      await tap(tester, 'Reset');
      expect(find.text('Mochi'), findsOneWidget);
    });

    testWidgets('Reset cancels a running win countdown', (tester) async {
      await pumpApp(tester);
      await tap(tester, 'Play', 4); // happiness 90 -> countdown starts
      await tester.pump(const Duration(minutes: 2));

      await tap(tester, 'Reset');
      // Old countdown would have finished 1 minute from now.
      await tester.pump(const Duration(minutes: 2));
      expect(find.text('Status: Playing'), findsOneWidget);
    });

    testWidgets('Reset leaves exactly one hunger timer, restarted fresh',
        (tester) async {
      await pumpApp(tester);
      await tester.pump(const Duration(seconds: 20));

      await tap(tester, 'Reset');

      // Old timer (due at 30s) was cancelled: nothing at the old tick time.
      await tester.pump(const Duration(seconds: 10));
      expect(find.bySemanticsLabel('Hunger: 50 out of 100'), findsOneWidget);

      // New timer ticks 30s after reset, once (+5, not +10).
      await tester.pump(const Duration(seconds: 20));
      expect(find.bySemanticsLabel('Hunger: 55 out of 100'), findsOneWidget);
    });
  });

  group('Energy system', () {
    Future<void> tap(WidgetTester tester, String label, [int times = 1]) async {
      for (var i = 0; i < times; i++) {
        await tester.tap(find.text(label));
        await tester.pump();
      }
    }

    bool isEnabled(WidgetTester tester, String label) {
      final button = tester.widget<ButtonStyleButton>(find.ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      ));
      return button.onPressed != null;
    }

    testWidgets('Play costs 15 energy', (tester) async {
      await pumpApp(tester);
      await tap(tester, 'Play');
      expect(find.bySemanticsLabel('Energy: 55 out of 100'), findsOneWidget);
    });

    testWidgets('Rest gives 25 energy and 5 hunger', (tester) async {
      await pumpApp(tester);
      await tap(tester, 'Play', 2); // energy 40, hunger 60
      await tap(tester, 'Rest');
      expect(find.bySemanticsLabel('Energy: 65 out of 100'), findsOneWidget);
      expect(find.bySemanticsLabel('Hunger: 65 out of 100'), findsOneWidget);
    });

    testWidgets('Feed gives 5 energy', (tester) async {
      await pumpApp(tester);
      await tap(tester, 'Feed');
      expect(find.bySemanticsLabel('Energy: 75 out of 100'), findsOneWidget);
    });

    testWidgets('Each hunger tick recovers 5 energy', (tester) async {
      await pumpApp(tester);
      await tester.pump(const Duration(seconds: 30));
      expect(find.bySemanticsLabel('Energy: 75 out of 100'), findsOneWidget);
    });

    testWidgets('Play is disabled below 15 energy until the pet rests',
        (tester) async {
      await pumpApp(tester);
      await tap(tester, 'Play', 4); // energy 70 -> 10

      expect(isEnabled(tester, 'Play'), isFalse);
      expect(find.textContaining('too tired to play'), findsOneWidget);

      // Tapping the disabled button changes nothing.
      await tap(tester, 'Play');
      expect(find.bySemanticsLabel('Energy: 10 out of 100'), findsOneWidget);

      await tap(tester, 'Rest'); // energy 35
      expect(isEnabled(tester, 'Play'), isTrue);
      expect(find.textContaining('too tired to play'), findsNothing);
    });

    testWidgets('Rest is disabled after an outcome', (tester) async {
      await pumpApp(tester);
      await tester.pump(const Duration(seconds: 30 * 12)); // loss
      expect(isEnabled(tester, 'Rest'), isFalse);
    });

    testWidgets('Reset restores energy to 70', (tester) async {
      await pumpApp(tester);
      await tap(tester, 'Play', 3);
      await tap(tester, 'Reset');
      expect(find.bySemanticsLabel('Energy: 70 out of 100'), findsOneWidget);
    });
  });

  testWidgets('Meters and mood expose accessible labels', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester);

    expect(find.bySemanticsLabel('Mood: Neutral'), findsOneWidget);
    expect(find.bySemanticsLabel('Happiness: 50 out of 100'), findsOneWidget);
    expect(find.bySemanticsLabel('Hunger: 50 out of 100'), findsOneWidget);
    handle.dispose();
  });
}
