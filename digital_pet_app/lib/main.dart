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
      // Scrollable so the layout still fits small screens and landscape.
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPetHeader(context),
              const SizedBox(height: 24),
              _buildMeter(
                label: 'Happiness',
                value: _happiness,
                color: Colors.green,
              ),
              const SizedBox(height: 12),
              _buildMeter(
                label: 'Hunger',
                value: _hunger,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              _buildOutcomeStatus(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Pet name plus mood shown as icon + text, so color is never the only
  /// signal.
  Widget _buildPetHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(_petName, style: textTheme.headlineMedium),
        const SizedBox(height: 8),
        Semantics(
          label: 'Mood: $_moodLabel',
          excludeSemantics: true,
          child: Chip(
            avatar: Icon(_moodIcon, color: _moodColor),
            label: Text(_moodLabel),
          ),
        ),
      ],
    );
  }

  /// One labeled 0–100 meter: progress bar plus numeric value.
  Widget _buildMeter({
    required String label,
    required int value,
    required Color color,
  }) {
    final shown = _clampMeter(value);
    return Semantics(
      label: '$label: $shown out of 100',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text('$shown / 100'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: shown / 100,
            minHeight: 10,
            color: color,
            backgroundColor: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(5),
          ),
        ],
      ),
    );
  }

  Widget _buildOutcomeStatus(BuildContext context) {
    return Text(
      'Status: $_outcomeLabel',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }
}
