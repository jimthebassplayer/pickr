# Pickr

Personal NFL survivor sheet for the 2026 season. One phone, one set of picks, saved on the device. No account and no server.

Weeks 1–4 are final. Week 5 is the open week. Weeks 6–18 can be looked at any time, with or without earlier picks. Week 6 has spreads; later weeks leave that spot blank until a line is posted. A week cannot be picked until every earlier week has a pick, and weeks 6–18 stay look-only. The app opens on Week 1. Tap a selected team again to clear that week only. A hollow star on a team marks a favorite; filled yellow means it is one. Favorites sort under the selected game.

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
