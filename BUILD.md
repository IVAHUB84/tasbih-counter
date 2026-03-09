# Tasbih Counter — Build Instructions

## Prerequisites

1. **Garmin Connect IQ SDK** — download from https://developer.garmin.com/connect-iq/sdk/
   - Install SDK, note the install path (e.g. `C:\Users\<you>\AppData\Roaming\Garmin\ConnectIQ`)
   - During install, download at least one device simulator (e.g. Fenix 6)

2. **VS Code Extension** — search "Monkey C" by Garmin in the Extensions marketplace
   - After install, open Command Palette → `Monkey C: Set SDK Path` → point to your SDK folder

3. **Generate icons** (first time only):
   ```
   cd tasbih-counter
   python create_icons.py
   ```

## Build & Run in Simulator

| Action | VS Code Command Palette |
|---|---|
| Build only | `Monkey C: Build Current Project` |
| Run in simulator | `Monkey C: Run in Simulator` |
| Choose device | prompted automatically |

Or via keyboard shortcut: **F5** (runs in simulator).

## Project Structure

```
tasbih-counter/
├── manifest.xml                  ← app metadata, permissions, supported devices
├── resources/
│   ├── strings.xml               ← all UI text (English + Russian + Arabic)
│   ├── drawables.xml             ← bitmap resource registry
│   └── drawables/
│       ├── ic_launcher.png       ← 40×40  app icon
│       ├── ic_reset.png          ← 20×20  (registered, drawn in code)
│       └── ic_settings.png       ← 20×20  (registered, drawn in code)
└── source/
    ├── App.mc                    ← entry point, daily auto-reset logic
    ├── Model/
    │   └── GoalManager.mc        ← all Storage reads/writes (Model layer)
    ├── Views/
    │   ├── MainView.mc           ← counter screen (View layer)
    │   └── SettingsView.mc       ← GoalPickerView number-picker
    └── Delegates/
        ├── MainDelegate.mc       ← touch + button input (Controller layer)
        └── SettingsDelegate.mc   ← settings menu + goal picker delegate

```

## Controls (Main Screen)

| Input | Touch | Button |
|---|---|---|
| Increment | Tap anywhere | START |
| Decrement | — | DOWN |
| Reset | Tap **R** icon (lower-left) | — |
| Settings | Tap **S** icon (lower-right) | — |
| Exit | — | BACK |

## Controls (Goal Picker)

| Button | Action |
|---|---|
| UP | +1 |
| DOWN | −1 |
| START | Save & close |
| BACK | Cancel |

## Storage Keys

| Key | Type | Default | Description |
|---|---|---|---|
| `currentCount` | Number | 0 | Current counter value |
| `dailyGoal` | Number | 33 | Daily target |
| `lastResetDate` | Number | today | Used for auto-reset detection |
| `goalAchieved` | Boolean | false | Prevents repeat vibration |
| `vibrationEnabled` | Boolean | true | User vibration preference |

## Simulating a New Day (auto-reset test)

In the simulator Device menu → **Set Date/Time** → advance the date by 1 day → restart the app.
The counter will be automatically reset to 0.
