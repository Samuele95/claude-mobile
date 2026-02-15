# Claude Mobile

An Android terminal client for running [Claude Code](https://docs.anthropic.com/en/docs/claude-code) remotely over SSH. Connect to your server from your phone, get a full terminal with a touch-friendly toolbar, manage files between devices, and fire off quick prompts from your home screen.

## Features

**Terminal**
- Full terminal emulator via `xterm` with Catppuccin Mocha color scheme
- Smart toolbar: arrow keys, Ctrl modifier, Tab, Esc, command palette, file attach
- Command palette with common Claude Code slash commands (`/compact`, `/clear`, `/review`, etc.)
- JetBrainsMono font, configurable font size
- Auto-launches `claude --dangerously-skip-permissions` on connect

**File Management**
- Dual-pane file browser (local phone storage + remote server via SFTP)
- Upload files from phone to server, download from server to phone
- Create directories, rename, delete on remote server
- Attach local files to the terminal session

**Connection**
- SSH key authentication (Ed25519, auto-generated and stored securely)
- Password authentication
- Multiple server profiles with secure credential storage via `flutter_secure_storage`
- Connection status indicator with auto-reconnect

**Home Screen Widget**
- Quick-prompt widget for one-shot Claude queries
- Type a prompt, get a response without opening the app

**Theming**
- Material 3 / Material You with purple accent
- Dark, AMOLED black, and light themes
- Catppuccin Mocha terminal palette

## Architecture

```
lib/
├── main.dart                          # Entry point, edge-to-edge UI
├── app.dart                           # Root widget, connection-based routing
├── core/
│   ├── models/                        # Data classes (ServerProfile, ConnectionState, TransferItem)
│   ├── providers.dart                 # Riverpod providers
│   ├── ssh/
│   │   ├── ssh_service.dart           # SSH connection, PTY, shell session management
│   │   └── sftp_service.dart          # SFTP file operations with transfer progress
│   └── storage/
│       ├── key_manager.dart           # Ed25519 key generation and storage
│       └── profile_repository.dart    # Server profile CRUD (FlutterSecureStorage)
├── features/
│   ├── connection/                    # Server list, add/edit server sheet, public key display
│   ├── terminal/                      # Terminal screen, smart toolbar, command palette
│   ├── files/                         # Dual-pane file browser (local + remote)
│   ├── settings/                      # Theme, font size preferences
│   └── widget/                        # Home screen quick-prompt service
└── theme/
    ├── app_theme.dart                 # Material 3 theme definitions
    └── terminal_theme.dart            # Catppuccin Mocha terminal colors
```

Three-layer design: **SSH transport** (dartssh2) -> **Services** (SshService, SftpService) -> **UI** (Riverpod providers + Flutter widgets).

State management uses Riverpod with `AsyncNotifier` for profiles and `StreamProvider` for connection state and transfer progress.

## Prerequisites

- Flutter 3.41+ with Dart 3.11+
- Android SDK with Build-Tools 35, NDK 28.2, CMake 3.22
- Java 21 (OpenJDK)

## Build

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release
```

The APK will be at `build/app/outputs/flutter-apk/app-debug.apk`.

## Install

```bash
# Via ADB
adb install build/app/outputs/flutter-apk/app-debug.apk

# Or transfer the APK to your phone and sideload
```

## Usage

1. Open the app and tap **+** to add a server
2. Enter your server's hostname/IP, port, and username
3. Choose authentication method (SSH key or password)
4. If using SSH key, tap the key icon to copy your public key and add it to `~/.ssh/authorized_keys` on your server
5. Tap the server card to connect
6. Claude Code launches automatically in the terminal

## Dependencies

| Package | Purpose |
|---|---|
| `dartssh2` | SSH/SFTP client |
| `xterm` | Terminal emulator widget |
| `pinenacl` | Ed25519 key generation |
| `flutter_riverpod` | State management |
| `flutter_secure_storage` | Encrypted credential storage |
| `home_widget` | Android home screen widget |
| `flutter_local_notifications` | Widget prompt notifications |
| `file_picker` | Local file selection |
| `share_plus` | Share public key |
| `permission_handler` | Storage permissions |

## License

Private use only.
