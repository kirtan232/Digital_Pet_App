import 'package:flutter/material.dart';

void main() {
  runApp(const DigitalPetApp());
}

class DigitalPetApp extends StatelessWidget {
  const DigitalPetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Pet',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const DigitalPetScreen(),
    );
  }
}

class DigitalPetScreen extends StatefulWidget {
  const DigitalPetScreen({super.key});

  @override
  State<DigitalPetScreen> createState() => _DigitalPetScreenState();
}

class _DigitalPetScreenState extends State<DigitalPetScreen> {
  // Starting values, reused by reset.
  static const String initialName = 'Pip';
  static const int initialHappiness = 50;
  static const int initialHunger = 50;

  // Pet state: the single source of truth for everything the UI shows.
  String _petName = initialName;
  int _happiness = initialHappiness;
  int _hunger = initialHunger;
  bool _gameOver = false;
  bool _hasWon = false;

  /// Keeps every meter inside 0–100.
  int _clampMeter(int value) => value.clamp(0, 100).toInt();

  // Mood is derived from happiness, never stored separately.
  // Above 70 = happy, 30–70 = neutral, below 30 = unhappy.
  String get _moodLabel {
    if (_happiness > 70) return 'Happy';
    if (_happiness >= 30) return 'Neutral';
    return 'Unhappy';
  }

  Color get _moodColor {
    if (_happiness > 70) return Colors.green;
    if (_happiness >= 30) return Colors.yellow;
    return Colors.red;
  }

  IconData get _moodIcon {
    if (_happiness > 70) return Icons.sentiment_very_satisfied;
    if (_happiness >= 30) return Icons.sentiment_neutral;
    return Icons.sentiment_very_dissatisfied;
  }

  String get _outcomeLabel {
    if (_hasWon) return 'You won!';
    if (_gameOver) return 'Game over';
    return 'Playing';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Digital Pet'),
      ),
      // Temporary readout of the state model; Step 3 replaces it with the
      // real status UI.
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_petName, style: Theme.of(context).textTheme.headlineMedium),
            Icon(_moodIcon, color: _moodColor, size: 48),
            Text('Mood: $_moodLabel'),
            Text('Happiness: ${_clampMeter(_happiness)}'),
            Text('Hunger: ${_clampMeter(_hunger)}'),
            Text('Status: $_outcomeLabel'),
          ],
        ),
      ),
    );
  }
}
