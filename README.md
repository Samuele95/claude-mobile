<p align="center">
  <img src="https://img.shields.io/github/license/Samuele95/claude-mobile?style=flat-square" alt="License" />
  <img src="https://img.shields.io/github/v/release/Samuele95/claude-mobile?style=flat-square" alt="Release" />
  <img src="https://img.shields.io/github/actions/workflow/status/Samuele95/claude-mobile/ci.yml?branch=master&style=flat-square&label=CI" alt="CI" />
  <img src="https://img.shields.io/github/stars/Samuele95/claude-mobile?style=flat-square" alt="Stars" />
</p>

# Claude Mobile

An open-source Android terminal client for running [Claude Code](https://docs.anthropic.com/en/docs/claude-code) remotely over SSH. Connect to your development server from your phone with a full terminal emulator, touch-optimized toolbar, file management, and a home screen widget for quick prompts.

> **Run Claude Code from anywhere** — on the bus, on the couch, or away from your desk.

---

## Install

**Download the latest APK** from the [Releases page](https://github.com/Samuele95/claude-mobile/releases) and sideload it on your Android device.

```bash
# Or install via ADB
adb install claude-mobile-v*.apk
```

Requires Android 8.0+ (API 26).

---

## Features

### Terminal Emulator
- Full xterm-compatible terminal via the `xterm` package
- **Smart toolbar** — arrow keys, Tab, Esc, Ctrl modifier, clipboard paste, command palette, file attach
- **Command palette** with common Claude Code commands (`/compact`, `/clear`, `/review`, `/cost`, etc.)
- **Claude Mode selector** — Standard Shell, Skip Permissions, or Custom Prompt
- Catppuccin color schemes (Mocha dark, AMOLED black, Latte light)
- JetBrainsMono font with configurable size (8–24pt)

### Multi-Session Support
- Multiple concurrent SSH sessions with a tab bar
- Per-session terminal state and SFTP connections
- Session reconnect and connection info panel

### File Management
- Dual-pane browser — local phone storage + remote server via SFTP
- Upload, download, create directories, rename, delete
- Attach files directly to the terminal session

### Connection Management
- **SSH key** authentication (Ed25519, auto-generated)
- **Password** authentication with secure storage
- Multiple server profiles — add, edit, delete
- Auto-reconnect with exponential backoff (1s → 16s, up to 5 attempts)

### Home Screen Widget
- Quick-prompt widget for one-shot Claude queries
- Type a prompt, get a response — no need to open the app

### Quality of Life
- Wake lock keeps screen on during sessions
- Haptic feedback on toolbar actions (toggleable)
- Task completion notifications when Claude goes idle
- Theme-aware terminal colors follow your app theme choice

---

## Screenshots

> Coming soon — contributions welcome! Add screenshots to `assets/screenshots/` and open a PR.

---

## Architecture

```
lib/
├── main.dart                     # Entry point, edge-to-edge UI
├── app.dart                      # Root widget, connection-based routing
├── core/
│   ├── models/                   # ServerProfile, ConnectionState, Session, TransferItem
│   ├── providers.dart            # Riverpod providers
│   ├── ssh/
│   │   ├── ssh_service.dart      # SSH connection, PTY, auto-reconnect
│   │   ├── connection_manager.dart # Multi-session orchestration
│   │   └── sftp_service.dart     # SFTP file ops with progress tracking
│   └── storage/
│       ├── key_manager.dart      # Ed25519 key generation & storage
│       └── profile_repository.dart # Profile CRUD (FlutterSecureStorage)
├── features/
│   ├── connection/               # Server list, add/edit sheet, public key display
│   ├── terminal/                 # Terminal screen, smart toolbar, command palette
│   ├── files/                    # Dual-pane file browser (local + remote)
│   ├── settings/                 # Preferences (theme, font, wake lock, auto-reconnect)
│   └── widget/                   # Home screen quick-prompt service
└── theme/
    ├── app_theme.dart            # Material 3 theme definitions
    └── terminal_theme.dart       # Catppuccin terminal palettes (dark, amoled, light)
```

**Design:** SSH transport (`dartssh2`) → Services (`SshService`, `SftpService`, `ConnectionManager`) → UI (Riverpod + Flutter widgets)

**State management:** Riverpod with `AsyncNotifier` for profiles, `StreamProvider` for connection state and transfer progress.

---

## Build from Source

### Prerequisites

- Flutter 3.41+ / Dart 3.11+
- Android SDK — Build-Tools 35, NDK 28.2, CMake 3.22
- Java 21 (OpenJDK / Temurin)

### Commands

```bash
git clone https://github.com/Samuele95/claude-mobile.git
cd claude-mobile
flutter pub get

# Debug build
flutter build apk --debug

# Release build
flutter build apk --release

# Run analysis
flutter analyze
```

The APK will be at `build/app/outputs/flutter-apk/`.

---

## Usage

1. Open the app and tap **Add Server**
2. Enter your server's hostname/IP, port, and username
3. Choose an authentication method:
   - **SSH Key** — tap the key icon to copy your public key, then add it to `~/.ssh/authorized_keys` on your server
   - **Password** — enter your password (stored encrypted on-device)
4. Select a **Claude Mode** (Standard Shell, Skip Permissions, or Custom Prompt)
5. Tap **Test** to verify the connection, then **Save**
6. Tap the server card to connect — Claude Code launches automatically

---

## Dependencies

| Package | Purpose |
|---|---|
| [`dartssh2`](https://pub.dev/packages/dartssh2) | SSH/SFTP client |
| [`xterm`](https://pub.dev/packages/xterm) | Terminal emulator widget |
| [`pinenacl`](https://pub.dev/packages/pinenacl) | Ed25519 key generation |
| [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) | State management |
| [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage) | Encrypted credential storage |
| [`wakelock_plus`](https://pub.dev/packages/wakelock_plus) | Screen wake lock |
| [`home_widget`](https://pub.dev/packages/home_widget) | Android home screen widget |
| [`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications) | Idle notifications |
| [`file_picker`](https://pub.dev/packages/file_picker) | Local file selection |
| [`share_plus`](https://pub.dev/packages/share_plus) | Share public key |

---

## Contributing

Contributions are welcome! Please read the [Contributing Guide](CONTRIBUTING.md) before opening a PR.

---

## License

[MIT](LICENSE) — free for personal and commercial use.
