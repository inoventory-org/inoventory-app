# Agent Context - Inoventory App (Frontend)

This file provide specific context for AI agents working on the Inoventory Flutter application.

## 🏛 Architecture & State Management
- **Dependency Injection**: We use [GetIt](https://pub.dev/packages/get_it) as a service locator, integrated with [Injectable](https://pub.dev/packages/injectable) for automated code generation. 
- **Initialization**: DI is configured in `lib/config/injection.dart`.
- **API Communication**: The backend is consumed via `Dio`. Service classes (e.g., `ProductService`) handle the logic and networking.
- **Supabase**: Used for authentication and primary database interaction.

## 🎨 Design & UI
- **Design System**: Strictly follow **Material 3** principles.
- **Widgets**: Reusable UI components are located in `lib/shared/widgets/`.
- **Navigation**: Standard Flutter Navigator is used, routes are often defined in feature directories.

## 📂 Key Directories
- `lib/inventory/`: Core inventory management screens and logic.
- `lib/barcode/`: Scanning logic and Open Food Facts communication.
- `lib/auth/`: Supabase authentication wrappers and profile management.
- `lib/config/`: Configuration (DI, Environment, API endpoints).

## 🚦 Constraints & Known Issues
- **Web Port**: Local development for Web **must** use port 50000 (`--web-port=50000`) for consistency with backend CORS/Auth configurations.
- **Code Generation**: Always run `build_runner` after modifying files with `@Injectable`, `@module`, or other generation-based annotations.
- **Secrets**: Do not commit `lib/config/secrets.dart` to the repository.

## 💡 Tips for Agents
- When adding a new feature, favor the existing feature-based directory structure (e.g., `lib/feature_name/screens/`, `lib/feature_name/widgets/`).
- Use `mocktail` for unit and widget tests.
- Prefer `const` constructors where possible for performance optimization.
