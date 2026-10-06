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
    expect(find.text('Mood: Neutral'), findsOneWidget);
    expect(find.text('Happiness: 50'), findsOneWidget);
    expect(find.text('Hunger: 50'), findsOneWidget);
    expect(find.text('Status: Playing'), findsOneWidget);
  });
}
