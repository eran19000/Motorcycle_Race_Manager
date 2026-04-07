# Motorcycle Race Manager

Professional motorcycle track-day management and lap timer app built with Flutter.

## Overview

This project includes:

- Rider onboarding with privacy options and automatic speed-group assignment.
- Live high-contrast race dashboard with large timer and dynamic best-sector / best-lap feedback.
- Internal GPS (default) and external Bluetooth GPS placeholder flow.
- Real-time telemetry simulation mode for quick demos on web.
- Track selection (Israel + world circuits) with map visualization.
- Organizer/admin portal with live leaderboard and rider map.
- Super-admin entry concept for platform-level management.
- Local session snapshot saving and history display.

## Roles and Portals

The app has separate entry flows:

- `Rider`: onboarding, live lap timer, history, AI/premium area.
- `Organizer / Manager`: admin mode, paid track-day group management, live leaderboard and map.
- `Super Admin`: owner-level control area (demo PIN in current build).

## Current Feature Highlights

- High-visibility light theme for outdoor use.
- Center digital timer with selectable precision:
  - centiseconds (`0.01s`)
  - milliseconds (`0.001s`)
- Best sector visual: black background with white text.
- Session best lap visual: green background.
- Finish line capture from current GPS position.
- Speed groups (6 levels): `A+`, `A`, `B+`, `B`, `C`, `D`.
- Organizer group type with paid/unpaid state for track-day access.
- Language selector (Hebrew / English / Arabic) for main navigation flow.

## Maps and Telemetry

- Map powered by OpenStreetMap via `flutter_map`.
- Rider positions are shown in live/admin views.
- Track path is displayed with segment coloring:
  - green = acceleration
  - red = braking
- Coloring uses live telemetry trail when available (fallback to generated demo pattern).

## Tech Stack

- Flutter
- `geolocator`
- `sensors_plus`
- `flutter_blue_plus`
- `flutter_map`
- `latlong2`
- `shared_preferences`
- `intl`

## Run Locally

### Quick start (Windows)

Use the provided launcher:

- `RUN_APP_CHROME.bat`

This script runs:

1. `flutter create .`
2. `flutter pub get`
3. `flutter run -d chrome`

### Manual run

```bash
flutter create .
flutter pub get
flutter run -d chrome
```

## Project Structure

- `lib/screens/` UI pages (onboarding, live, admin, history, AI)
- `lib/services/` telemetry, group management, session history
- `lib/models/` domain models
- `lib/data/` track catalog
- `lib/widgets/` reusable widgets (formatters, map widget)

## Notes

- External Bluetooth GPS integration is currently a placeholder flow.
- AI analysis / Gemini integration is planned and not fully implemented yet.
- Payment and production-grade auth are modeled conceptually; full backend integration is pending.
