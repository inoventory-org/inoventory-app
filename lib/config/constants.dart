import 'package:flutter/foundation.dart' show kIsWeb;


class KeycloakConf {
  static const baseUrl = "http://10.100.255.76:8081";
  final discoveryUrl = "$baseUrl/realms/inoventory/.well-known/openid-configuration";
  final clientId = "app";
  final redirectUrl = kIsWeb ? "http://localhost" : "com.railabouni.inoventory://auth";
  // final redirectUrl = "http://localhost";
}

abstract class Constants {
  static const inoventoryBackendUrl = "http://10.100.255.76:8080";
  // static const inoventoryBackendUrl = "http://10.0.2.2:8080";
  // static const inoventoryBackendUrl = "http://ec2-18-157-81-199.eu-central-1.compute.amazonaws.com";
  static const darkMode = true;
  static final keycloakConf = KeycloakConf();
}