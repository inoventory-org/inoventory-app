# inoventory_ui

inoventory UI

Running at: http://10.100.253.181/

## Web Version

If running the web version, the run configuration must be edited so that the app starts at port 50000. 

This is done by editing the run configuration in Android Studio and adding the commandline argument next to ´additional run args´:
´--web-port=50000´


## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Dependency Injection
This projects uses [*GetIt*](https://pub.dev/packages/get_it) and [*Injectable*](https://pub.dev/packages/injectable) for Dependency Injection.

*GetIt* is a service locator. It is initialized in `config/injection.dart`. To access a registered service service call `getIt<MyService>()`.

*Injectable* is a code generator for GetIt. To register a service annotate it with `@Injectable` or `@Injectable(as: MyService)` for an interface implementation.

For the code generation to run on file changes run
`flutter packages pub run build_runner watch`
or use
`flutter packages pub run build_runner build `
for manual code generation.