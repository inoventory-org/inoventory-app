import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:inoventory_ui/config/injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit(ignoreUnregisteredTypes: [Dio])
void configureDependencies() {
  getIt.registerSingleton<Dio>(Dio());
  getIt.init();
}
