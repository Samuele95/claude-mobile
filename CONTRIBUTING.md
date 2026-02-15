# Contributing to Claude Carry

Thanks for your interest in contributing! This guide will help you get started.

## Getting Started

### Prerequisites

- Flutter 3.41+ / Dart 3.11+
- Android SDK with Build-Tools 35, NDK 28.2, CMake 3.22 (for Android builds)
- Xcode 16+ (for iOS builds, macOS only)
- Java 21 (OpenJDK / Temurin)

### Setup

```bash
git clone https://github.com/Samuele95/claude-carry.git
cd claude-carry
flutter pub get
flutter analyze   # should show 0 issues
```

## Development Workflow

1. **Fork** the repository and create a branch from `master`
2. **Name your branch** descriptively: `fix/terminal-cursor-offset`, `feat/ios-support`, `docs/add-screenshots`
3. **Make your changes** — keep commits focused and atomic
4. **Run checks** before pushing:
   ```bash
   flutter analyze --fatal-infos
   flutter test
   flutter build apk --debug
   ```
5. **Open a PR** against `master` and fill out the template

## Code Style

- Follow standard Dart/Flutter conventions (`flutter_lints`)
- `flutter analyze --fatal-infos` must pass with zero issues
- Use Riverpod for state management — follow existing provider patterns
- Keep widgets focused — prefer composition over large build methods
- Use `const` constructors wherever possible

## Architecture

The codebase follows a three-layer architecture:

```
SSH transport (dartssh2) → Services (SshService, SftpService) → UI (Riverpod + Flutter)
```

- **`lib/core/`** — models, providers, SSH/SFTP services, storage
- **`lib/features/`** — UI screens and widgets, organized by feature
- **`lib/theme/`** — Material 3 and terminal theme definitions

When adding a new feature, place it in the appropriate `features/` subdirectory and register any providers in `core/providers.dart`.

## What to Contribute

### Good First Issues

Look for issues labeled [`good first issue`](https://github.com/Samuele95/claude-carry/labels/good%20first%20issue).

### Ideas

- **Screenshots** — we need screenshots for the README
- **Tests** — unit and widget tests are sparse
- **Documentation** — usage guides, feature deep-dives
- **Accessibility** — screen reader support, contrast improvements
- **New features** — check the [issues](https://github.com/Samuele95/claude-carry/issues) for feature requests

## Reporting Bugs

Use the [bug report template](https://github.com/Samuele95/claude-carry/issues/new?template=bug_report.yml) and include:

- Steps to reproduce
- Device model and OS version
- App version
- Any error logs or stack traces

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
