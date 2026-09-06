# 🍕 Impasta

[![Release](https://img.shields.io/github/v/release/ttarner/impasta?style=flat-square&color=FF7A00)](https://github.com/ttarner/impasta/releases)
[![GitHub Pages](https://img.shields.io/badge/GitHub%20Pages-Live%20Demo-brightgreen?style=flat-square&logo=github)](https://ttarner.github.io/impasta/)
[![Docker GHCR](https://img.shields.io/badge/GHCR-ghcr.io%2Fttarner%2Fimpasta-blue?style=flat-square&logo=docker)](https://github.com/ttarner/impasta/pkgs/container/impasta)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)

**Impasta** is a modern, sleek pizza dough calculator and preset manager built with [Flutter](https://flutter.dev/). Designed for both casual home pizzaiolos and passionate bakers, it makes dough formulation effortless, reliable, and completely reproducible.

🌐 **Try the Web App**: [https://ttarner.github.io/impasta/](https://ttarner.github.io/impasta/)

---

## ✨ Features

- ⚖️ **Accurate Dough Calculations**:
  - Calculate total flour, water, yeast, and salt with exact baker's percentages.
  - Customize hydration percentage and yeast type (fresh yeast, active dry, instant).
  - Adjust dough ball weight, number of balls, and pan dough factor.
- 🥘 **Custom Baking Pans**:
  - Add and manage custom pans (rectangular or round) with dimensions.
  - Automatically calculates surface area and suggested dough weight based on thickness factor.
- 📖 **Preset & Recipe Management**:
  - Save, edit, and organize favorite dough configurations.
  - Attach photos to recipes for visual tracking (camera or gallery).
  - Notes, fermentation time, and temperature details.
- 🔒 **100% Client-Side & Privacy First**:
  - Zero external backend or tracking.
  - Powered by [Sembast](https://pub.dev/packages/sembast) (uses IndexedDB in the browser and local storage on mobile).
  - Images are preserved locally (Base64 data URIs in browser IndexedDB, local files on mobile).
- 🌍 **Multi-Language Support**:
  - English, Italian, German, French, Spanish, Portuguese, Japanese, and Turkish.
- 🎨 **Elegant Design**:
  - Dark theme with Hermès-inspired orange accents, responsive layout for mobile, tablet, and desktop browsers.

---

## 🚀 Getting Started

### Run via Docker (GitHub Container Registry)

You can run the web version locally in seconds using Docker:

```bash
docker run -d -p 9000:9000 --name impasta ghcr.io/ttarner/impasta:latest
```

Then visit `http://localhost:9000` in your browser.

#### Using Docker Compose

```bash
docker compose up -d
```

### Local Development

#### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.24.x or higher)
- Google Chrome (for web debugging) or Android/iOS emulator

#### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/ttarner/impasta.git
   cd impasta
   ```

2. Fetch dependencies:
   ```bash
   flutter pub get
   ```

3. Run locally:
   ```bash
   # Run in Chrome
   flutter run -d chrome

   # Run on connected mobile device or emulator
   flutter run
   ```

4. Run static analysis:
   ```bash
   flutter analyze
   ```

---

## 📦 Building

### Web

```bash
# Build for root hosting
flutter build web --release

# Build for GitHub Pages hosting under subpath
flutter build web --release --base-href "/impasta/"
```

The output will be placed in `build/web/`.

### Android APK

```bash
flutter build apk --release
```

The output APK will be in `build/app/outputs/flutter-apk/app-release.apk`.

### iOS IPA (Unsigned)

```bash
flutter build ios --release --no-codesign
```

---

## 🔄 CI/CD & Automation

The repository includes a GitHub Actions workflow (`.github/workflows/release.yml`) that automatically:
1. **Bumps Version**: Increments the patch version in `pubspec.yaml` on pushes to `main`.
2. **Builds Mobile Artifacts**: Compiles Android APK and unsigned iOS IPA.
3. **Builds & Pushes Docker Image**: Builds the web container and publishes it to **GitHub Container Registry** (`ghcr.io/ttarner/impasta`).
4. **Deploys to GitHub Pages**: Builds the static client-side web application and deploys it live to GitHub Pages.
5. **Creates GitHub Release**: Publishes a release with changelog and downloadable binaries.

> [!TIP]
> To enable GitHub Pages on your repository:
> Go to **Repository Settings** > **Pages** > **Build and deployment** > Select **GitHub Actions** as Source.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
