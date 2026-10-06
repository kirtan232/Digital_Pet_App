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
  static const int initialEnergy = 70;

  // Energy rules (advanced feature).
  static const int playEnergyCost = 15;
  static const int restEnergyGain = 25;

  // How often hunger grows. Shorten (e.g. 5 seconds) only while testing by
  // hand; it must be 30 seconds for submission.
  static const Duration hungerTickInterval = Duration(seconds: 30);

  // Happiness must stay above winThreshold this long, without dropping, to
  // win. Shorten only while testing by hand; must be 3 minutes for submission.
  static const Duration winDuration = Duration(minutes: 3);
  static const int winThreshold = 80;

  // Pet state: the single source of truth for everything the UI shows.
  String _petName = initialName;
  int _happiness = initialHappiness;
  int _hunger = initialHunger;
  int _energy = initialEnergy;
  bool _gameOver = false;
  bool _hasWon = false;

  // Owned by this State object, so it must be disposed in dispose().
  final TextEditingController _nameController = TextEditingController();

  // The single periodic hunger timer. Created in initState, never in build.
  Timer? _hungerTimer;

  // One-shot win timer; only exists while happiness is above winThreshold.
  Timer? _highMoodTimer;

  @override
  void initState() {
    super.initState();
    _startHungerTimer();
  }

  @override
  void dispose() {
    _hungerTimer?.cancel();
    _highMoodTimer?.cancel();
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
  /// at 100 and costs 20 happiness instead. Energy slowly recovers +5.
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
      _energy = _clampMeter(_energy + 5);
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

  /// Playing also needs enough energy.
  bool get _canPlay => _canCare && _energy >= playEnergyCost;

  /// Feed: hunger -10, energy +5. Happiness +10, unless the pet ends up
  /// overfed (hunger below 30), which costs 20 happiness instead.
  void _feedPet() {
    if (!_canCare) return;

    final nextHunger = _clampMeter(_hunger - 10);
    final happinessChange = nextHunger < 30 ? -20 : 10;
    final nextHappiness = _clampMeter(_happiness + happinessChange);
    final nextEnergy = _clampMeter(_energy + 5);

    setState(() {
      _hunger = nextHunger;
      _happiness = nextHappiness;
      _energy = nextEnergy;
    });
    _updateOutcome();
  }

  /// Play: happiness +10, hunger +5, energy -15. Blocked when too tired.
  void _playWithPet() {
    if (!_canPlay) return;

    final nextHappiness = _clampMeter(_happiness + 10);
    final nextHunger = _clampMeter(_hunger + 5);
    final nextEnergy = _clampMeter(_energy - playEnergyCost);

    setState(() {
      _happiness = nextHappiness;
      _hunger = nextHunger;
      _energy = nextEnergy;
    });
    _updateOutcome();
  }

  /// Rest: energy +25, hunger +5 (resting still makes the pet hungry).
  void _restPet() {
    if (!_canCare) return;

    final nextEnergy = _clampMeter(_energy + restEnergyGain);
    final nextHunger = _clampMeter(_hunger + 5);

    setState(() {
      _energy = nextEnergy;
      _hunger = nextHunger;
    });
    _updateOutcome();
  }

  /// Re-checks win/loss. Called after every action and every hunger tick.
  void _updateOutcome() {
    if (!_canCare) return;

    // Loss: starving and miserable.
    if (_hunger == 100 && _happiness <= 10) {
      _stopAllTimers();
      setState(() => _gameOver = true);
      return;
    }

    // "Above 80" is strict: exactly 80 cancels the win countdown.
    if (_happiness <= winThreshold) {
      _highMoodTimer?.cancel();
      _highMoodTimer = null;
      return;
    }

    // First crossing above 80 starts a fresh countdown; staying above keeps
    // the existing one running (??= does not restart it).
    _highMoodTimer ??= Timer(winDuration, _onWinTimerDone);
  }

  void _onWinTimerDone() {
    _highMoodTimer = null;
    if (!mounted || !_canCare || _happiness <= winThreshold) return;
    _stopAllTimers();
    setState(() => _hasWon = true);
  }

  /// Restores the starting meters and clears the outcome. The pet keeps its
  /// name. Old timers are cancelled first, then exactly one fresh hunger
  /// timer starts; the win timer only restarts on the next crossing above 80.
  void _resetPet() {
    _stopAllTimers();
    setState(() {
      _happiness = initialHappiness;
      _hunger = initialHunger;
      _energy = initialEnergy;
      _gameOver = false;
      _hasWon = false;
    });
    _startHungerTimer();
  }

  void _stopAllTimers() {
    _hungerTimer?.cancel();
    _hungerTimer = null;
    _highMoodTimer?.cancel();
    _highMoodTimer = null;
  }

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

  /// Tint for the pet image. Neutral uses white, which BlendMode.modulate
  /// leaves unchanged, so the pet shows its natural colors.
  Color get _petTint {
    if (_happiness > 70) return Colors.green;
    if (_happiness >= 30) return Colors.white;
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
              const SizedBox(height: 12),
              _buildMeter(label: 'Energy', value: _energy, color: Colors.blue),
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
        colorFilter: ColorFilter.mode(_petTint, BlendMode.modulate),
        child: Image.asset(
          'assets/images/cute_cat.png',
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
        FilledButton(onPressed: _confirmName, child: const Text('Confirm')),
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
            children: [Text(label), Text('$shown / 100')],
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

  /// Feed, Play and Rest are disabled (onPressed: null) after an outcome;
  /// Play is also disabled when energy is too low. Reset always works.
  Widget _buildCareActions() {
    final tooTired = _canCare && !_canPlay;
    return Column(
      children: [
        Wrap(
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
              onPressed: _canPlay ? _playWithPet : null,
              icon: const Icon(Icons.sports_baseball),
              label: const Text('Play'),
            ),
            FilledButton.icon(
              onPressed: _canCare ? _restPet : null,
              icon: const Icon(Icons.bedtime),
              label: const Text('Rest'),
            ),
            OutlinedButton.icon(
              onPressed: _resetPet,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset'),
            ),
          ],
        ),
        if (tooTired) ...[
          const SizedBox(height: 8),
          Text(
            '$_petName is too tired to play. Let them rest!',
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  /// Status line, plus a banner explaining the result once the game ends.
  Widget _buildOutcomeStatus(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final status = Text(
      'Status: $_outcomeLabel',
      textAlign: TextAlign.center,
      style: textTheme.titleMedium,
    );
    if (_canCare) return status;

    final won = _hasWon;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        status,
        const SizedBox(height: 8),
        Semantics(
          liveRegion: true,
          child: Card(
            color: won ? Colors.green.shade100 : Colors.red.shade100,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    won ? Icons.emoji_events : Icons.heart_broken,
                    color: won ? Colors.green.shade800 : Colors.red.shade800,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      won
                          ? '$_petName stayed happy for 3 minutes. You win!'
                          : '$_petName got too hungry and sad. Game over.',
                      style: textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
