# HelpRide

HelpRide is a Flutter application that provides ride discovery, booking, driver workflows, and chat-like interactions. The app is organized around feature modules (auth, rides, ride requests, bookings, driver tools, profiles, and location) and uses GetX for routing/state, Firebase for messaging, Stripe for payments, and push notification services for real-time updates. 【F:lib/app.dart†L1-L30】【F:lib/core/routes/app_routes.dart†L1-L26】【F:lib/main.dart†L1-L44】【F:pubspec.yaml†L1-L70】

## Table of contents

- [Project overview](#project-overview)
- [Architecture](#architecture)
- [Environment configuration](#environment-configuration)
- [Setup](#setup)
- [Running the app](#running-the-app)
- [Testing](#testing)
- [Useful commands](#useful-commands)
- [Project structure](#project-structure)

## Project overview

HelpRide is a multi-role ride platform app with the following core capabilities:

- **Authentication** flows and gated entry into the app.
- **Ride discovery and requests**, including search and request management.
- **Bookings** and booking success flows.
- **Driver tools** for driver-specific workflows.
- **Chat** and **location** features to support ride coordination.

These features are split into dedicated modules under `lib/features`, with shared UI, services, and controllers under `lib/shared`. 【F:lib/core/routes/app_routes.dart†L1-L26】

## Architecture

Key building blocks:

- **GetX** for routing (`GetPage`), dependency injection (`Get.put`), and reactive UI (`Obx`). 【F:lib/app.dart†L1-L30】【F:lib/core/routes/app_routes.dart†L1-L26】
- **Firebase** for initialization and background messaging support. 【F:lib/main.dart†L1-L44】
- **Stripe** for payments via a publishable key configured in `.env`. 【F:lib/main.dart†L1-L44】
- **Push notifications** via a dedicated service that initializes at startup. 【F:lib/main.dart†L1-L44】
- **Local storage** using GetStorage. 【F:lib/main.dart†L1-L44】

## Environment configuration

Create a `.env` file at the repository root. This file is loaded at startup, and it must include the following keys to enable payments:

```
STRIPE_PUBLISHABLE_KEY=pk_test_your_key
STRIPE_MERCHANT_IDENTIFIER=merchant.com.example
```

The `.env` file is referenced as a Flutter asset. 【F:lib/main.dart†L1-L44】【F:pubspec.yaml†L72-L86】

If `STRIPE_PUBLISHABLE_KEY` is missing, the app will log a debug warning. 【F:lib/main.dart†L18-L33】

## Setup

1. Install Flutter (version compatible with Dart SDK `^3.9.2`). 【F:pubspec.yaml†L12-L15】
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Copy or create the `.env` file with the required keys.
4. Configure Firebase for Android/iOS if you plan to use messaging.

## Running the app

```bash
flutter run
```

The app entry point initializes environment variables, Stripe, Firebase, storage, and push notifications before launching `HelpRideApp`. 【F:lib/main.dart†L1-L44】

## Testing

```bash
flutter test
```

## Versioning

Flutter already drives both store versions from `pubspec.yaml`:

- `1.0.1` becomes iOS `CFBundleShortVersionString`
- `3` becomes iOS `CFBundleVersion` and Android `versionCode`

Use the version helper before release builds instead of editing `pubspec.yaml` by hand:

```bash
dart run tool/bump_version.dart build   # 1.0.1+3 -> 1.0.1+4
dart run tool/bump_version.dart patch   # 1.0.1+3 -> 1.0.2+4
dart run tool/bump_version.dart minor
dart run tool/bump_version.dart major
dart run tool/bump_version.dart set 1.2.0
```

Use `build` when you need another upload for the same release train. Use `patch` (or higher) when App Store Connect says the previous version is already approved and the train is closed, like the `1.0.1` rejection shown in Xcode Organizer.

## Android publishing

The Android app is currently configured with package ID `ca.helpride.mobile` and version `1.0.1+3`. Run the version helper before every Play upload so `versionCode` stays ahead of the last release.

1. Create an upload keystore for Play signing:
   ```bash
   keytool -genkey -v \
     -keystore android/upload-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias upload
   ```
2. Copy `android/key.properties.example` to `android/key.properties` and fill in the real passwords, alias, and keystore path.
3. Build the Play bundle:
   ```bash
   flutter build appbundle --release
   ```
4. Upload `build/app/outputs/bundle/release/app-release.aab` to Google Play.

Before submitting to production in Play Console, make sure the store listing, privacy policy, data safety form, and app content declarations are complete. This app requests location permissions and uses push notifications, payments, and file uploads, so those disclosures need to match the app's real behavior.

## Useful commands

```bash
flutter pub get
flutter pub outdated
flutter run
flutter test
```

## Project structure

```
lib/
  app.dart                 # Application root + GetX setup
  main.dart                # App entry point & service initialization
  core/
    routes/                # Route definitions
    theme/                 # App theming
    constants/             # Shared constants
  features/                # Feature modules (auth, rides, bookings, etc.)
  shared/                  # Shared views, controllers, services, bindings
```

Routes are composed from each feature module and attached to the app shell. 【F:lib/core/routes/app_routes.dart†L1-L26】
