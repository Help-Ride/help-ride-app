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
