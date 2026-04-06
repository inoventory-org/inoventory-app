# Inoventory - Flutter App

The frontend application for Inoventory, built with Flutter.

## ✨ Features
- **Barcode Scanning**: Integrated barcode scanner for rapid product identification.
- **Product Metadata**: Automatic details (images, ingredients, nutrition) via [Open Food Facts](https://world.openfoodfacts.org/).
- **Inventory Tracking**: Manage items, quantities, and expiration dates.
- **Push Notifications**: Automated alerts for expiring items (via FCM).
- **Material 3 Design**: Modern, responsive UI with Material 3 principles.
- **Multi-Platform**: Support for Android, iOS, and Web.

## 🚀 Tech Stack
- **Framework**: Flutter 3.6.2
- **Persistence & Auth**: [Supabase Flutter](https://pub.dev/packages/supabase_flutter)
- **Dependency Injection**: [GetIt](https://pub.dev/packages/get_it) & [Injectable](https://pub.dev/packages/injectable)
- **Networking**: [Dio](https://pub.dev/packages/dio)
- **Messaging**: [Firebase Messaging](https://pub.dev/packages/firebase_messaging)
- **Scanner**: [Mobile Scanner](https://pub.dev/packages/mobile_scanner)

## 🛠 Setup & Development

### 1. Secret Keys
A password for Open Food Facts is required for product contributions.
1. Create `lib/config/secrets.dart`.
2. Retrieve the `OPEN_FOOD_FACTS_PASSWORD` from the project's CI/CD variables.
3. Supplement the file with the credentials.

### 2. Environment Configuration
Create a `.env` file in the project root:
```properties
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

### 3. Code Generation
This project uses code generation for DI and serialization.
Run the build_runner:
```bash
# Continuous watch
flutter packages pub run build_runner watch --delete-conflicting-outputs

# One-time build
flutter packages pub run build_runner build --delete-conflicting-outputs
```

## 🌐 Running the Web Version
The web version must start on port **50000** for proper local testing:
```bash
flutter run -d chrome --web-port=50000
```
Or configure your IDE (Android Studio / VS Code) to use `--web-port=50000`.

## 🧪 Testing
Run tests using:
```bash
flutter test
```
See `test/` for unit, widget, and integration tests.
