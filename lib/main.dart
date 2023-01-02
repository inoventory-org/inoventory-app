import 'package:flutter/material.dart';
// import 'package:flutter_appauth/flutter_appauth.dart';
// import 'package:inoventory_ui/config/constants.dart';
import 'package:inoventory_ui/routes/InoventoryApp.dart';



void main() {
  // ErrorWidget.builder =
  //     (errorDetails) => ErrorView(errorDetails: errorDetails);
  // FlutterAppAuth appAuth = const FlutterAppAuth();
  // final AuthorizationTokenResponse? result = await appAuth.authorizeAndExchangeCode(
  //   AuthorizationTokenRequest(
  //     Constants.keycloakConf.clientId,
  //     Constants.keycloakConf.redirectUrl,
  //     discoveryUrl: Constants.keycloakConf.discoveryUrl,
  //   ),
  // );
  // print(result);
  runApp(const InoventoryApp());
}
