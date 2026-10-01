# Sokabrain mobile

Flutter client for the Sokabrain vault. It reads the same API as the web app
(`backend/`, port 4010) and adds no endpoints of its own.

## Screens

- **Matches**: day-by-day schedule with a date strip and month header, live
  badges, and a match page with the event timeline.
- **League hub**: table and stats (overview, top scorers, club records) for the
  selected competition and season.
- **Competitions**: browser for every published competition.
- **Team profile**: record, form, seasons, top scorers, upcoming fixtures.
- **Kijiweni**: the fan zone. Browse spaces, read threads, post and like.
- **More**: fan profile, favourite teams, theme, Swahili/English.

## Running

```sh
# backend first, from the repo root
cd backend && npm run dev

# then the app
cd mobile
flutter pub get
flutter run
```

The API base URL defaults to `http://localhost:4010`
(`lib/services/api_service.dart`, `ApiService.setBaseUrl`). That works on the
iOS simulator and macOS. The Android emulator needs `http://10.0.2.2:4010`, and
a physical device needs your machine's LAN address.

## Tests

```sh
flutter analyze
flutter test
```

**The backend must be running for `flutter test`.** The API-decoding tests call
it for real and assert on vault data.

The Kijiweni write test (create a thread, like it, comment) is skipped by
default, because the public API cannot delete what it posts. Run it only
against a database you can throw away:

```sh
flutter test --dart-define=KIJIWENI_WRITE_TESTS=true
```

## Before a release build

- `ios/Runner/Info.plist` sets `NSAllowsArbitraryLoads` so local HTTP works in
  development. Replace it with HTTPS and remove the exception.
- Point the base URL at the production API.
