import 'package:flutter/foundation.dart' show kIsWeb;


class KeycloakConf {
  static const baseUrl = "http://10.100.255.76:8081";
  static const realm = "inoventory";
  static const baseUrlWithRealm = "$baseUrl/realms/$realm";
  final authorizationUrl = "$baseUrlWithRealm/protocol/openid-connect/auth";
  final discoveryUrl = "$baseUrlWithRealm/.well-known/openid-configuration";
  final endSessionUrl = "$baseUrlWithRealm/protocol/openid-connect/logout";
  final clientId = "app";
  static final redirectSchema = "com.railabouni.inoventory";
  final redirectUrl = kIsWeb ? "http://localhost:50000/auth" : "$redirectSchema://auth";
}

abstract class Constants {
  static const inoventoryBackendUrl = "http://10.100.255.76:8080";
  // static const inoventoryBackendUrl = "http://localhost:8080";
  // static const inoventoryBackendUrl = "http://10.0.2.2:8080";
  // static const inoventoryBackendUrl = "http://ec2-18-157-81-199.eu-central-1.compute.amazonaws.com";
  static const darkMode = true;
  static final keycloakConf = KeycloakConf();
  static const accessTokenRefreshIntervalSeconds = 60;
}