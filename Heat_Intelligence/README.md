# Heat Intelligence

Heat Intelligence is a Flutter app for monitoring heat risk, alerts, and map-based hotspot visualization.

## Setup

1. Install Flutter and Android Studio with at least one Android emulator.
2. From the project root, run `flutter pub get`.
3. No map API key is required. The app now uses Leaflet tiles (OpenStreetMap/Carto/Esri).

### Real-time weather source

The app uses Open-Meteo (free, keyless) for real-time weather by default.

No API key is required.

If the weather API is unavailable, the app falls back to backend or local dummy data.

### Map provider

Maps are rendered with `flutter_map` (Leaflet) and free tile sources.
No Google Maps key or platform-specific map setup is needed.

### Search any city for heat zones

On the Map tab, use the search icon in the top bar and type any city name.
The app geocodes that city, fetches heat risk/zone data for the selected point,
and the same location context is reflected across map-based views.

Use the location icon in the same top bar to switch back to your current GPS location.

## Run on emulator

1. Start emulator:

```
flutter emulators --launch Pixel_6
```

2. Run app:

```
flutter run -d emulator-5554
```
