# SYSTEM

> **Control Your Mac From Anywhere**

A futuristic cross-platform mobile app for remote macOS control. Features a "Hacker Console meets Premium SaaS Dashboard" aesthetic with deep space dark mode and glassmorphism design.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)

## Features

### System Control
- **107+ Mac Control Tools** - Volume, brightness, screenshots, app launching, and more
- **Real-time System Status** - Battery, WiFi, storage, and running applications
- **Media Controls** - Spotify/Apple Music playback with Now Playing display
- **Quick Actions** - One-tap access to common commands (Sleep, DND, Lock, etc.)

### Task Management
- **Personal OS Integration** - AI-powered task management with REST API
- **Priority-based Tasks** - P0-P3 priority system with status tracking
- **Daily Focus** - AI-generated daily priorities and recommendations
- **AI Chat** - Natural language interface for task management

### Authentication
- **Secure Login** - Token-based WebSocket authentication
- **Remember Me** - Persistent credentials with local storage
- **Session Management** - Easy logout and reconnection

### Modern UI/UX
- **Glassmorphism Design** - Frosted glass effects with neon accents
- **Dark & Light Themes** - Full theme support with system detection
- **Responsive Layout** - Optimized for phones and tablets
- **Smooth Animations** - Fluid transitions and micro-interactions

## Screenshots

| Login | Monitor | Tools | Tasks |
|-------|---------|-------|-------|
| Secure authentication | Dashboard with system status | 100+ Mac control tools | AI-powered tasks |

## Architecture

```
lib/
├── main.dart                 # App entry point with auth flow
├── services/
│   ├── auth_service.dart     # Authentication & session management
│   ├── system_provider.dart  # WebSocket connection to Mac
│   ├── personal_os_provider.dart  # REST API for tasks/AI
│   ├── macro_provider.dart   # Command sequences
│   └── file_browser_provider.dart # Remote file access
├── theme/
│   └── system_theme.dart     # Colors, typography, styling
├── ui/
│   ├── system_app_shell.dart # Main navigation shell
│   ├── screens/
│   │   ├── login_screen.dart    # Authentication
│   │   ├── monitor_screen.dart  # Dashboard
│   │   ├── tools_screen.dart    # Mac control tools
│   │   ├── tasks_screen.dart    # Task management
│   │   ├── uplink_screen.dart   # AI chat
│   │   └── settings_screen.dart # Configuration
│   └── widgets/
│       ├── glass_container.dart  # Glassmorphism card
│       ├── now_playing_card.dart # Media player
│       └── quick_actions_grid.dart # Action buttons
└── models/
    └── now_playing.dart      # Media data model
```

## Getting Started

### Prerequisites

- Flutter SDK 3.0+
- Dart 3.0+
- Xcode (for iOS)
- Android Studio (for Android)
- [SYSTEM Mac Server](https://github.com/anudeepadi/system) running on your Mac

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/anudeepadi/system-app.git
   cd system-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   # iOS Simulator
   flutter run -d ios

   # Android Emulator
   flutter run -d android

   # Specific device
   flutter run -d <device_id>
   ```

### Configuration

The app connects to two servers:

1. **System-Mac WebSocket Server** (Port 3001)
   - Provides Mac control tools via MCP protocol
   - Requires authentication token from `bridge.config.json`

2. **Personal OS REST API** (Port 8765) - Optional
   - Provides task management and AI chat
   - Uses Bearer token authentication

Configure these in the login screen or use the development defaults.

## Building for Production

### iOS
```bash
flutter build ios --release
```

### Android
```bash
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

### Generate App Icons
```bash
flutter pub run flutter_launcher_icons
```

## Tech Stack

| Category | Technology |
|----------|------------|
| Framework | Flutter 3.x |
| Language | Dart 3.x |
| State Management | Provider |
| HTTP Client | http package |
| WebSocket | web_socket_channel |
| Charts | fl_chart |
| Icons | Lucide Icons |
| Fonts | Google Fonts (JetBrains Mono, Inter) |
| Storage | shared_preferences |

## Server Requirements

This app requires the SYSTEM Mac server running on your Mac:

```bash
# Clone the server
git clone https://github.com/anudeepadi/system.git
cd system

# Install dependencies
npm install

# Build
npm run build

# Start WebSocket server
npm run start:ws
```

The server provides 107+ Mac control tools including:
- Volume, brightness, and display controls
- Screenshot and screen recording
- Music playback (Spotify, Apple Music)
- App launching and window management
- System information and status
- Notifications and clipboard
- Calendar and reminders
- And many more...

## API Endpoints

### WebSocket (System-Mac)
| Message Type | Direction | Description |
|--------------|-----------|-------------|
| `auth` | Client → Server | Authenticate with token |
| `list_tools` | Client → Server | Get available tools |
| `call_tool` | Client → Server | Execute a tool |
| `subscribe` | Client → Server | Subscribe to status/logs/progress |
| `tool_result` | Server → Client | Tool execution result |
| `status` | Server → Client | Mac status update |

### REST API (Personal OS)
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Server health check |
| `/tasks` | GET | List all tasks |
| `/tasks/:id` | GET | Get single task |
| `/tasks/:id/status` | PATCH | Update task status |
| `/focus` | GET | Get daily focus |
| `/priorities` | GET | Get priority distribution |
| `/chat` | POST | AI chat message |

## Tool Categories

| Category | Examples |
|----------|----------|
| System | battery_status, wifi_status, storage_status |
| Media | music_play, music_pause, volume_set |
| Display | brightness_set, dark_mode_toggle, screenshot |
| Power | lock_screen, sleep_display, sleep_mac |
| Apps | open_app, open_url, browser_tabs |
| Communication | notify, say, send_imessage |
| Productivity | calendar_today, reminders_list |
| Notes | notes_list, notes_create |
| Finder | finder_search, finder_downloads |
| Shell | shell, applescript |
| Spotify | spotify_player_* (20+ commands) |
| Raycast | raycast, shortcut_run |

## SDK Usage

### Basic Connection

```dart
import 'package:system_app/services/system_provider.dart';

final provider = SystemProvider();

// Connect
await provider.connect('ws://192.168.x.x:3001', 'your-auth-token');

// List tools
print('Available tools: ${provider.tools.length}');

// Execute a tool
final result = await provider.callTool('battery_status');
print('Battery: ${result.text}');

// Subscribe to updates
provider.subscribe(['status', 'logs', 'progress']);

// Disconnect
provider.disconnect();
```

### With Provider

```dart
Consumer<SystemProvider>(
  builder: (context, provider, _) {
    if (!provider.isConnected) {
      return Text('Disconnected');
    }

    return Column(
      children: [
        Text('Battery: ${provider.status?.battery}'),
        Text('Tools: ${provider.tools.length}'),
        ElevatedButton(
          onPressed: () => provider.callTool('lock_screen'),
          child: Text('Lock Screen'),
        ),
      ],
    );
  },
)
```

### Quick Actions

```dart
final actions = QuickActions(provider);

// Media control
await actions.playPauseMusic();
await actions.nextTrack();
await actions.setVolume(50);

// System control
await actions.toggleDarkMode();
await actions.lockScreen();

// Notifications
await provider.callTool('notify', {'message': 'Hello!', 'title': 'SYSTEM'});
```

## Remote Access

For controlling your Mac from outside the local network:

1. Enable tunnel in SYSTEM config:
   ```json
   {
     "access": "remote"
   }
   ```

2. Restart SYSTEM server - it will create a Cloudflare tunnel

3. Use the tunnel URL (e.g., `wss://xxx.trycloudflare.com`) in the app

## Security

- Bearer token authentication required
- Constant-time token comparison
- 30-second auth timeout
- All connections encrypted (WSS for remote)
- Credentials stored securely in local storage
- Session management with logout functionality

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Flutter](https://flutter.dev/) - UI framework
- [Lucide Icons](https://lucide.dev/) - Beautiful icon set
- [JetBrains Mono](https://www.jetbrains.com/mono/) - Developer font
- [fl_chart](https://pub.dev/packages/fl_chart) - Charts library

---

**SYSTEM** - Built with passion for remote work and productivity.
