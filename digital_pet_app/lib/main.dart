import 'dart:async';

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

  // How often hunger grows. Shorten (e.g. 5 seconds) only while testing by
  // hand; it must be 30 seconds for submission.
  static const Duration hungerTickInterval = Duration(seconds: 30);

  // Pet state: the single source of truth for everything the UI shows.
  String _petName = initialName;
  int _happiness = initialHappiness;
  int _hunger = initialHunger;
  bool _gameOver = false;
  bool _hasWon = false;

  // Owned by this State object, so it must be disposed in dispose().
  final TextEditingController _nameController = TextEditingController();

  // The single periodic hunger timer. Created in initState, never in build.
  Timer? _hungerTimer;

  @override
  void initState() {
    super.initState();
    _startHungerTimer();
  }

  @override
  void dispose() {
    _hungerTimer?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  /// Cancels any old hunger timer first, so exactly one is ever running.
  void _startHungerTimer() {
    _hungerTimer?.cancel();
    _hungerTimer = Timer.periodic(hungerTickInterval, (_) => _onHungerTick());
  }

  /// Hunger +5 per tick. A tick that reaches 100 (e.g. 95 -> 100) costs
  /// nothing extra; once hunger is already maxed, each further tick keeps it
  /// at 100 and costs 20 happiness instead.
  void _onHungerTick() {
    if (!mounted) return;
    if (!_canCare) {
      _hungerTimer?.cancel();
      return;
    }

    setState(() {
      if (_hunger + 5 > 100) {
        _hunger = 100;
        _happiness = _clampMeter(_happiness - 20);
      } else {
        _hunger += 5;
      }
    });
    _updateOutcome();
  }

  /// Confirms the typed name. Blank input is ignored so the pet always has a
  /// name.
  void _confirmName() {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    setState(() {
      _petName = newName;
    });
    _nameController.clear();
    FocusScope.of(context).unfocus();
  }

  /// Keeps every meter inside 0–100.
  int _clampMeter(int value) => value.clamp(0, 100).toInt();

  /// Care actions are locked once the game has a final outcome.
  bool get _canCare => !_gameOver && !_hasWon;

  /// Feed: hunger -10. Happiness +10, unless the pet ends up overfed
  /// (hunger below 30), which costs 20 happiness instead.
  void _feedPet() {
    if (!_canCare) return;

    final nextHunger = _clampMeter(_hunger - 10);
    final happinessChange = nextHunger < 30 ? -20 : 10;
    final nextHappiness = _clampMeter(_happiness + happinessChange);

    setState(() {
      _hunger = nextHunger;
      _happiness = nextHappiness;
    });
    _updateOutcome();
  }

  /// Play: happiness +10, hunger +5.
  void _playWithPet() {
    if (!_canCare) return;

    final nextHappiness = _clampMeter(_happiness + 10);
    final nextHunger = _clampMeter(_hunger + 5);

    setState(() {
      _happiness = nextHappiness;
      _hunger = nextHunger;
    });
    _updateOutcome();
  }

  /// Re-checks win/loss after every state change. Filled in at Step 8.
  void _updateOutcome() {}

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
              const SizedBox(height: 16),
              _buildNameInput(),
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
              const SizedBox(height: 24),
              _buildCareActions(),
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
        _buildPetImage(),
        const SizedBox(height: 12),
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

  /// Light grayscale pet image tinted by mood. BlendMode.modulate multiplies
  /// the image by the mood color, so light areas take the tint and dark
  /// outlines stay dark.
  Widget _buildPetImage() {
    return Semantics(
      label: '$_petName looks ${_moodLabel.toLowerCase()}',
      image: true,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(_moodColor, BlendMode.modulate),
        child: Image.asset(
          'assets/images/pet.png',
          width: 180,
          height: 180,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        ),
      ),
    );
  }

  /// Text field + confirm button for naming the pet.
  Widget _buildNameInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _nameController,
            maxLength: 20,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _confirmName(),
            decoration: const InputDecoration(
              labelText: 'Pet name',
              hintText: 'Enter a new name',
              border: OutlineInputBorder(),
              counterText: '',
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _confirmName,
          child: const Text('Confirm'),
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

  /// Feed and Play buttons; disabled (onPressed: null) after an outcome.
  Widget _buildCareActions() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: _canCare ? _feedPet : null,
          icon: const Icon(Icons.restaurant),
          label: const Text('Feed'),
        ),
        FilledButton.icon(
          onPressed: _canCare ? _playWithPet : null,
          icon: const Icon(Icons.sports_baseball),
          label: const Text('Play'),
        ),
      ],
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
