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

  testWidgets('Meters and mood expose accessible labels', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const DigitalPetApp());

    expect(find.bySemanticsLabel('Mood: Neutral'), findsOneWidget);
    expect(find.bySemanticsLabel('Happiness: 50 out of 100'), findsOneWidget);
    expect(find.bySemanticsLabel('Hunger: 50 out of 100'), findsOneWidget);
    handle.dispose();
  });
}
