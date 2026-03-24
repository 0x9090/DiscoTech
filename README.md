# DiscoTech - Garmin Watch Visualizer

A sound-reactive color visualizer for Garmin smartwatches. Designed for clubs,
raves, and festivals — DiscoTech turns your wrist into a light show.

The app uses the watch's **accelerometer** to detect bass vibrations and music
energy, translating physical vibration into colorful animated patterns on your
watch face. At loud venues, the bass literally shakes your wrist, and DiscoTech
picks that up.

## Supported Devices

- **Fenix 8** series (Fenix 8, Fenix 8 Solar, 47mm variants)
- **Fenix 7** series (standard, S, X, Pro variants)
- **Epix 2** / Epix Pro series
- **Enduro 3**
- **Venu 2** / Venu 2 Plus / Venu 3 series (AMOLED — looks amazing)
- **Forerunner** 265, 955, 965

## Visual Patterns

Cycle through **10 patterns** using the UP/DOWN buttons:

| # | Pattern | Description |
|---|---------|-------------|
| 1 | **Rainbow Pulse** | Expanding/contracting rainbow rings that breathe with the bass |
| 2 | **Spiral Galaxy** | Four rotating rainbow spiral arms |
| 3 | **Concentric Rings** | Pulsing colored rings radiating outward |
| 4 | **Starburst** | Radiating colored lines from center, like a star exploding |
| 5 | **Color Wave** | Horizontal sine-wave bands of color flowing across the screen |
| 6 | **Diamond Twist** | Nested rotating diamond shapes in rainbow colors |
| 7 | **Radar Sweep** | Rotating beam with a color trail over ring markers |
| 8 | **Plasma Field** | Psychedelic flowing color blobs (classic plasma effect) |
| 9 | **Disco Ball** | Grid of flashing colored squares with sparkle effects |
| 10 | **Fireworks** | Bursting particle effects in rainbow colors |

All patterns are rainbow-based and react to detected vibrations/movement.

## Controls

| Input | Action |
|-------|--------|
| **UP** button | Next pattern |
| **DOWN** button | Previous pattern |
| **SELECT/START** button | Toggle auto-cycle mode (rotates patterns every ~10s) |
| **BACK** button | Exit app |
| **Tap** (touchscreen) | Trigger a manual flash/beat |

## How It Works

Garmin's Connect IQ SDK does not provide direct microphone access. Instead,
DiscoTech reads the **accelerometer** at high frequency. In loud environments
(clubs, concerts, raves), bass frequencies create physical vibrations that the
accelerometer detects. The app interprets these vibration spikes as "beats" and
amplifies the visual animation accordingly.

Even without strong bass, the patterns animate continuously with a base energy
level, so the visuals are always moving and colorful. You can also tap the
screen on touchscreen models to manually trigger flash effects.

## Prerequisites

- [Garmin Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) (v6.2.0+)
- Java JDK 8+ (required by the SDK)
- A Garmin device or the Connect IQ Simulator

### Install the SDK

1. Download the SDK from https://developer.garmin.com/connect-iq/sdk/
2. Extract it and add the `bin/` directory to your `PATH`:
   ```bash
   export PATH=$PATH:/path/to/connectiq-sdk/bin
   ```
3. Download device files for your target device using the SDK Manager:
   ```bash
   sdkmanager
   ```

## Building

### Command Line

```bash
# Generate a developer key (first time only)
connectiq-sdk/bin/generatekey -o developer_key.der

# Build for a specific device (e.g., Fenix 8)
monkeyc -o DiscoTech.prg \
  -f monkey.jungle \
  -y developer_key.der \
  -d fenix8

# Build for Fenix 7 Pro
monkeyc -o DiscoTech.prg \
  -f monkey.jungle \
  -y developer_key.der \
  -d fenix7pro

# Build for Venu 3 (AMOLED)
monkeyc -o DiscoTech.prg \
  -f monkey.jungle \
  -y developer_key.der \
  -d venu3
```

### Using the Simulator

```bash
# Start the simulator
connectiq &

# Build and push to simulator
monkeyc -o DiscoTech.prg -f monkey.jungle -y developer_key.der -d fenix8
monkeydo DiscoTech.prg fenix8
```

### Using Visual Studio Code (Recommended)

1. Install the **Monkey C** extension for VS Code
2. Open this project folder in VS Code
3. Press `Ctrl+Shift+P` → "Monkey C: Build Current Project"
4. Select your target device
5. Run in the simulator with "Monkey C: Run on Simulator"

## Installing on Your Watch

### Via USB (Sideload)

1. Build the `.prg` file as described above
2. Connect your watch via USB
3. Copy the `.prg` file to: `GARMIN/APPS/` on the watch storage
4. Safely eject and disconnect
5. The app appears in your watch's app list

### Via Connect IQ Store (For Distribution)

1. Build an `.iq` package:
   ```bash
   monkeyc -e -o DiscoTech.iq \
     -f monkey.jungle \
     -y developer_key.der \
     -r
   ```
2. Upload to https://apps.garmin.com/developer/
3. Users install through the Connect IQ app on their phone

## Project Structure

```
DiscoTech/
├── manifest.xml              # App metadata, supported devices, permissions
├── monkey.jungle             # Build configuration
├── README.md                 # This file
├── source/
│   ├── DiscoTechApp.mc       # App entry point
│   ├── DiscoTechView.mc      # Main view with pattern rendering engine
│   └── DiscoTechDelegate.mc  # Button/input handling
└── resources/
    ├── strings.xml           # Localized strings
    └── drawables/
        ├── launcher_icon.xml # Icon reference
        └── launcher_icon.png # App icon (rainbow circle)
```

## Tips for Best Experience

- **AMOLED displays** (Venu 3, Epix Pro) look dramatically better since each
  pixel emits its own light — colors are vivid and blacks are true black
- **Auto-cycle mode** (press SELECT) is great for hands-free use on the dance
  floor
- **Battery**: The app refreshes at ~30fps and uses the accelerometer, so it
  will drain battery faster than normal watch usage. Good for a night out, not
  for all-day wear
- **Wrist placement**: Wear the watch slightly loose for better bass vibration
  pickup, or tap the screen to manually trigger effects

## License

MIT License. Do whatever you want with it.
