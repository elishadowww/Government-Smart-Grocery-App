# government_smart_grocery_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Setup

1. `flutter pub get`
2. Get the latest `pricecatcher.db` **from the project maintainer** and place
   it at `assets/database/pricecatcher.db`. This file is too large to commit
   to git — see `tools/db_builder/README.md` if you're the one building it,
   rather than receiving it.
3. `flutter run`. On first launch the app copies the database from
   `assets/database/` into its local storage automatically; if the file
   isn't there yet, the app tells you so on screen instead of crashing.

Firebase Authentication config (`firebase_options.dart`, `google-services.json`)
is already committed and needs no setup step.
