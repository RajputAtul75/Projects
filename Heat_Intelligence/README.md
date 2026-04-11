# Heat Intelligence

Heat Intelligence is a Flutter app for monitoring heat risk, alerts, and map-based hotspot visualization.

## Setup

1. Install Flutter and Android Studio with at least one Android emulator.
2. From the project root, run `flutter pub get`.
3. Configure your Google Maps API key (required for map rendering).

### Weather API key (real-time weather)

The app supports real-time weather from OpenWeather when a weather API key is
provided at build/run time.

Run with:

```bash
flutter run -d emulator-5554 --dart-define=WEATHER_API_KEY=your_openweather_api_key
```

If no key is provided, the app falls back to backend or local dummy data.

### Android API key

Set one of these:

1. Add to `android/local.properties`:

```
GOOGLE_MAPS_API_KEY=your_real_android_maps_key
```

2. Or set environment variable before running:

```
set GOOGLE_MAPS_API_KEY=your_real_android_maps_key
```

The manifest uses a placeholder and reads from one of the two sources above.

### iOS API key

Update this value in both files:

- `ios/Flutter/Debug.xcconfig`
- `ios/Flutter/Release.xcconfig`

Replace:

```
GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY_HERE
```

with your real iOS Maps key.

## Run on emulator

1. Start emulator:

```
flutter emulators --launch Pixel_6
```

2. Run app:

```
flutter run -d emulator-5554
```
