# CrowdSync

CrowdSync is an Android-first Flutter app for synchronized local audio rooms.
One Android phone hosts a room, nearby Android phones join over local Wi-Fi /
hotspot transport through Google Nearby Connections, and every client plays the
same local audio file on a shared timeline.

## Architecture

- Flutter owns UI, app state, room orchestration, QR flow, and screens.
- Kotlin owns the timing-sensitive sync module through `crowdsync/native_sync`.
- Nearby Connections is used in star topology: every client connects directly to
  the host.
- Host transfers the selected local audio file to clients, then broadcasts
  timestamped play/pause/seek state.
- Clients maintain a native clock offset estimate using RTT samples and correct
  playback drift with micro-seeks.
- Flashlight pulse/strobe/bass-sim timing is scheduled natively on Android.

## Version 1 Scope

- Android only.
- Local MP3/audio files only.
- No iOS support.
- No Spotify, YouTube Music, or cloud backend.
- No internet audio streaming.
- Optimized for 2-4 phones on the same hotspot/Wi-Fi during MVP validation.

## Run

```bash
cd C:\Users\god88\CrowdSync
C:\Users\god88\develop\flutter\bin\flutter.bat pub get
C:\Users\god88\develop\flutter\bin\flutter.bat run
```

Build a debug APK:

```bash
C:\Users\god88\develop\flutter\bin\flutter.bat build apk --debug
```

The APK is generated at:

```text
build\app\outputs\flutter-apk\app-debug.apk
```

## Device Setup

- Use Android phones on the same Wi-Fi network or connect clients to the host
  phone hotspot.
- Enable Bluetooth, Wi-Fi, and Location services before creating or joining a
  room. Nearby Connections often requires Location services even though audio is
  not cloud-tracked.
- Grant Nearby devices, Bluetooth, Location, Camera, and Audio/media permissions
  when prompted.
- On the host, choose a local audio file after creating the room. The host sends
  that file to connected clients before playback.

## Validation Checklist

- Host creates room and QR code.
- Client joins by room ID/password or QR scan.
- Host-selected audio arrives on client.
- Host play/pause/seek updates clients.
- Client sync quality shows RTT and drift.
- Manual recalibration changes stored device offset.
- Host flashlight modes trigger opted-in clients.

## Native Module

Android code lives in:

```text
android\app\src\main\kotlin\com\crowdsync\app\
```

The current Kotlin module provides:

- monotonic native clock timestamps
- clock offset / RTT / drift estimation
- host-time to local-time conversion
- native flashlight scheduling

Next native migration targets:

- move audio scheduling from `just_audio` orchestration to ExoPlayer/Oboe
- move low-level room networking from Flutter plugin callbacks to native Nearby
  Connections callbacks
- add a foreground media service for long sessions

## Launch Strategy

Version 1: **CrowdSync for Android**. Validate sync, reviews, and retention.

Version 2: Android host with iOS client-only support.

Version 3: Full cross-platform host/client only after the sync engine is proven.
