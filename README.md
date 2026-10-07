# Pickr

Personal NFL survivor sheet for the 2026 season. One phone, one set of picks, saved on the device. No account and no server.

Weeks 1–4 are final. Week 5 is the open week. Weeks 6–18 have no matchups yet. The app opens on Week 1.

When a week ends, add that week's scores in `lib/data/schedule.dart` and set `currentWeek` in `lib/data/season.dart` to the next week.

## Run

```bash
cd ~/flutterApps/pickr
flutter pub get
flutter run
```

iOS Simulator:

```bash
open -a Simulator
flutter devices
flutter run -d <device-id>
```

Android emulator:

```bash
flutter emulators
flutter emulators --launch <emulator-id>
flutter run -d <emulator-id>
```

## Test

```bash
flutter test
```
