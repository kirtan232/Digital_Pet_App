# Digital Pet — In-Class Activity 07

A Flutter pet-care app that turns user actions and time into visible state changes, built with `StatefulWidget`, `setState()`, and lifecycle-aware timers. Two teams co-build one app in this repository:

- **Team 1 · Care Systems** — care actions, bounded meters, hunger and win timers, outcomes, reset, energy system, state tests.
- **Team 2 · Pet Personality** — derived pet messages, mood feedback, motion/accessibility polish, interaction tests. *(section below to be completed by Team 2)*

## Team

| Member | Team | Role | Pathway |
|---|---|---|---|
| _name_ | Team 1 | _role_ | Undergraduate |
| _name_ | Team 1 | _role_ | Undergraduate |
| _name_ | Team 2 | _role_ | _pathway_ |

## Run it

```
cd digital_pet_app
flutter pub get
flutter run              # launch on emulator/device
flutter test             # run the automated tests
flutter build apk --release
```

The app source is in [`digital_pet_app/lib/main.dart`](digital_pet_app/lib/main.dart) and the tests are in [`digital_pet_app/test/widget_test.dart`](digital_pet_app/test/widget_test.dart).

---

## Team 1 · Care Systems

Branch: `team1/care-systems`

### State model

All pet state lives in `_DigitalPetScreenState`, which is the single source of truth. Mood label, mood color, mood icon and the pet tint are **computed from happiness** on each build, never stored separately.

| Field | Start | Range |
|---|---|---|
| `_petName` | `Pip` | 1–20 characters, blank names ignored |
| `_happiness` | 50 | 0–100 |
| `_hunger` | 50 | 0–100 |
| `_energy` | 70 | 0–100 |
| `_gameOver` / `_hasWon` | `false` | — |

Every change goes through `_clampMeter()` so no meter can leave 0–100. Each action works out its new values first and then updates all affected fields together in **one** `setState()` call. `_updateOutcome()` runs after every action and every timer tick.

### Mood bands

| Happiness | Mood | Pet image tint | Icon |
|---|---|---|---|
| > 70 | Happy | Green | 😊 green |
| 30–70 | Neutral | Natural colors (no tint)* | 😐 yellow |
| < 30 | Unhappy | Red | 😞 red |

The tint uses `ColorFiltered` with `BlendMode.modulate`. The mood is always shown as text and an icon too, so color is never the only signal.

\* **Design choice:** in the neutral band the pet shows its natural colors instead of a yellow tint, because yellow on the gray cat looked muddy. The yellow mood icon and the "Neutral" label still mark the 30–70 band.

### Care rules (Team 1's chosen balance)

| Event | Happiness | Hunger | Energy |
|---|---|---|---|
| **Feed** | +10, or **−20** if hunger ends below 30 (overfed) | −10 | +5 |
| **Play** | +10 | +5 | −15 (disabled below 15 energy) |
| **Rest** | — | +5 | +25 |
| **Hunger tick** (every 30 s) | −20 only if hunger was already 100 | +5 (stops at 100) | +5 |
| **Reset** | back to 50 | back to 50 | back to 70 |

The overflow rule follows the course starter: a tick from 95 → 100 has no penalty, but a later tick that would push hunger past 100 keeps it at 100 and costs 20 happiness.

### Timers and outcomes

- **Hunger timer:** a single `Timer.periodic(30 s)` is created in `initState()`, never in `build()`. It is cancelled in `dispose()` and when the game ends. `_startHungerTimer()` always cancels any existing timer first, so exactly one is ever running.
- **Win:** happiness must stay **strictly above 80** for **3 minutes in a row**. A one-shot timer starts on the first crossing above 80. It is cancelled as soon as happiness is 80 or lower, and a fresh 3-minute timer starts on the next crossing. Actions that keep happiness above 80 do not restart it.
- **Loss:** hunger is 100 **and** happiness is 10 or lower.
- **On either outcome:** both timers stop, Feed/Play/Rest are disabled, and a banner explains the result (announced to screen readers).
- **Reset:** always available. It cancels all timers, restores the starting meters and clears the outcome, then starts exactly one fresh hunger timer. The pet keeps its name.
- **Cleanup:** `dispose()` cancels both timers and disposes the `TextEditingController`.

Durations live in one place (`hungerTickInterval = 30 s`, `winDuration = 3 min`) and are set to the production values.

### Advanced feature: Energy system (undergraduate pathway)

An energy meter (0–100, starts at 70) adds a resource trade-off to the care loop:

- **User flow:** play with the pet until it gets tired → Play greys out and the screen says *"Pip is too tired to play. Let them rest!"* → tap **Rest** (or wait) to recover → Play is available again.
- **State that changes:** Play spends `_energy` (−15). Rest restores it (+25) at a cost of +5 hunger. Feed and each hunger tick recover +5. `_canPlay` is derived from `_canCare && _energy >= 15`, so the button state always matches the meter.
- **Why:** it stops players from winning by spamming Play, and makes Rest a real decision because resting also makes the pet hungrier.

*(Undergraduates need two advanced features. Our second one is expected from Team 2's Visual polish & accessible motion work.)*

### Accessibility

- Every meter has a screen-reader label, for example *"Happiness: 50 out of 100"*.
- The mood chip reads *"Mood: Neutral"*, and the pet image reads *"Pip looks neutral"*.
- The outcome banner is a live region, so screen readers announce it when it appears.
- The layout scrolls inside a `SafeArea`, so it still fits small screens and landscape.

### Test evidence

Run `flutter test` from `digital_pet_app/`. **Result: 34 / 34 tests pass.** `flutter analyze` reports no issues. Timer tests use Flutter's fake clock, so the 30-second and 3-minute rules are checked in milliseconds without temporarily changing the production durations.

| Requirement | Automated test(s) |
|---|---|
| Starting state and mood | *Pet starts with initial state and neutral mood* |
| Mood bands and tint | *Neutral pet image keeps its natural colors*, *Mood and tint follow happiness*, *Happiness exactly 70 is still Neutral, untinted*, *Happiness below 30 is Unhappy/red* |
| Name entry | *Confirming a name updates the pet name*, *Blank name is ignored*, *Pet name is limited to 20 characters* |
| Feed / Play deltas | *Play raises happiness by 10 and hunger by 5*, *Feed lowers hunger by 10 and raises happiness by 10*, *Overfeeding (hunger below 30) costs 20 happiness* |
| Meters stay within 0–100 | *Meters clamp at 0 and 100* |
| Hunger timer | *Hunger rises by 5 every 30 seconds*, *Reaching 100 is free; ticks past 100 cost 20 happiness*, *Disposing the screen cancels the hunger timer* |
| Win (strictly > 80 for 3 min) | *Win after 3 minutes above 80, then actions lock*, *Exactly 80 happiness never starts the win timer*, *Dropping to 80 cancels the countdown; next crossing restarts*, *Actions while above 80 do not restart the win countdown* |
| Loss | *Loss when hunger is 100 and happiness is 10 or lower* |
| Timers stop on outcome | *Winning stops the hunger timer; Reset starts a new game*, *Loss…* (no change after 5 more minutes) |
| Reset | *Reset after game over restores meters and unlocks actions*, *Reset keeps the pet name*, *Reset cancels a running win countdown*, *Reset leaves exactly one hunger timer, restarted fresh* |
| Energy system | *Play costs 15 energy*, *Rest gives 25 energy and 5 hunger*, *Feed gives 5 energy*, *Each hunger tick recovers 5 energy*, *Play is disabled below 15 energy until the pet rests*, *Rest is disabled after an outcome*, *Reset restores energy to 70* |
| Accessibility labels | *Meters and mood expose accessible labels* |

**Manual check** (Android emulator, API 37, debug build):

- [x] App launches with the pet, name, mood chip, 3 meters and 4 buttons, with no layout overflow.
- [x] Play ×3 → happiness 80, pet turns green, mood shows "Happy".
- [x] A hunger tick fires live (+5 hunger, +5 energy).
- [x] Neutral pet shows its natural colors.
- [ ] Release APK installed and checked on the target device *(Step 12)*.

### Assets and licensing

- **Pet image:** "Cute Cat" by Sayarina, [OpenClipart](https://openclipart.org/detail/338177/cute-cat), released under the **CC0 1.0 Public Domain Dedication**. File: [`digital_pet_app/assets/images/cute_cat.png`](digital_pet_app/assets/images/cute_cat.png).
- No third-party packages are used beyond the Flutter SDK.

---

## Team 2 · Pet Personality

*To be completed by Team 2: features chosen, user flows, state that drives each effect, and test notes.*

Team 1 left these hooks so Team 2 can add effects without changing the game rules:

- `_moodLabel`, `_moodColor`, `_moodIcon` and `_petTint` are all derived from state.
- `_buildPetImage()`, `_buildPetHeader()`, `_buildMeter()`, `_buildCareActions()` and `_buildOutcomeStatus()` are separate build methods, so each can be wrapped in `AnimatedScale`, `AnimatedSwitcher`, `TweenAnimationBuilder`, and so on.
