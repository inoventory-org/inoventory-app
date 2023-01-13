import 'package:dio/dio.dart';
import 'package:inoventory_ui/config/injection.config.dart';
import 'package:inoventory_ui/ean/barcode_scanner.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

final getIt = GetIt.I;

@InjectableInit()
void configureDependencies() {
  getIt.registerSingleton<BarcodeScanner>(BarcodeScanner());
  getIt.registerSingleton<Dio>(Dio());
  getIt.init();
}
