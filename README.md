# Mac Remote Control

A Flutter client for controlling a Mac through an authenticated WebSocket bridge, with screens for system status, media, files and command macros. An optional Personal OS API supplies task and chat features.

**Status:** client prototype from January 2026. This repository contains the mobile/desktop client, not the Mac server. The previously linked `anudeepadi/system` server repository returned 404 on 22 September 2026, so a complete public client/server setup is currently unavailable.

## Run the client

Install Flutter and the platform SDK for your device. The package declares Dart `>=3.0.0 <4.0.0`; use a Flutter version that resolves the checked-in dependencies.

```bash
git clone https://github.com/anudeepadi/mac-remote-control.git
cd mac-remote-control
flutter pub get
flutter devices
flutter run -d DEVICE_ID
```

Replace `DEVICE_ID` with a device shown by `flutter devices`. Without a compatible server, the interface can be inspected but Mac commands cannot complete.

## Connect to your Mac

The login screen accepts your own WebSocket URL and authentication token. The client protocol is defined in [system_mcp_client.dart](lib/services/system_mcp_client.dart) and [messages.dart](lib/models/messages.dart). The original bridge used port 3001; optional Personal OS requests used port 8765. These ports do not establish server availability or compatibility.

A minimal connected walkthrough is: sign in to your bridge, read system status, change volume, then verify the resulting Mac state. Only describe these controls as working after the server responds and the Mac state changes. Tasks/chat require the separate Personal OS service.

## Source map

- [Authentication and saved connection settings](lib/services/auth_service.dart)
- [System client](lib/services/system_mcp_client.dart)
- [Screens](lib/ui/screens)
- [Macros](lib/services/macro_provider.dart)
- [File browser](lib/services/file_browser_provider.dart)

No real device screenshots or server acceptance results are bundled. The old screenshot table was descriptive text, and has been removed. `flutter build apk` and `flutter build ios` are platform build entry points; release signing and server integration remain separate work.

The Dart package/import identifier remains `system_app` for compatibility.

## License

See [LICENSE](LICENSE) for the existing terms.

## Credits

The original project credits Flutter, Lucide Icons, JetBrains Mono and fl_chart. Their existing licenses and notices remain applicable.
