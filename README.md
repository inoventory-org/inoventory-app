# inoventory_ui

inoventory UI

Running at: https://www.inoventory.railabouni.fra.ics.inovex.io/

## Secret Keys
In order to be able to add products to open food facts, a password is needed. 
It must be manually supplemented to the file `lib/config/secrets.dart`
For now, the password needs to be manually retrieved from the [repository's CI/CD variables](https://gitlab.inovex.de/railabouni/inoventory-ui/-/settings/ci_cd) (provided you have access).
The variable is called `OPEN_FOOD_FACTS_PASSWORD`

## Web Version

If running the web version, the run configuration must be edited so that the app starts at port 50000. 

This is done by editing the run configuration in Android Studio and adding the commandline argument next to ´additional run args´:
´--web-port=50000´


## Dependency Injection
This projects uses [*GetIt*](https://pub.dev/packages/get_it) and [*Injectable*](https://pub.dev/packages/injectable) for Dependency Injection.

*GetIt* is a service locator. It is initialized in `config/injection.dart`. To access a registered service service call `getIt<MyService>()`.

*Injectable* is a code generator for GetIt. To register a service annotate it with `@Injectable` or `@Injectable(as: MyService)` for an interface implementation.

For the code generation to run on file changes run
`flutter packages pub run build_runner watch`
or use
`flutter packages pub run build_runner build`
for manual code generation.
