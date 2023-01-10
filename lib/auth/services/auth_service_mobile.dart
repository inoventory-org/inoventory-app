import 'dart:developer' as developer;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:inoventory_ui/auth/services/auth_service.dart';
import 'package:inoventory_ui/config/constants.dart';
import 'package:openid_client/openid_client.dart';
import 'package:openid_client/openid_client_io.dart' as io;
import 'package:url_launcher/url_launcher.dart';

class AuthServiceImpl extends AuthService {
  late final FlutterSecureStorage secureStorage;
  late final Client client;
  late final Issuer issuer;
  List<String>? scopes;
  late io.Authenticator authenticator;
  late Credential? _credential;
  Future<void> Function()? onLoginSuccess;

  AuthServiceImpl._create(this.scopes, this.onLoginSuccess);

  /// Public factory --- needed due to async initialization
  static Future<AuthService> create(
      {List<String> scopes = const [],
      Future<void> Function()? onLoginSuccess}) async {
    // Call the private constructor
    var component = AuthServiceImpl._create(scopes, onLoginSuccess);
    var uri = Uri.parse(KeycloakConf.baseUrlWithRealm);
    var clientId = Constants.keycloakConf.clientId;

    component.secureStorage = const FlutterSecureStorage();
    component.issuer = await Issuer.discover(uri);
    component.client = Client(component.issuer, clientId);
    component.authenticator = io.Authenticator(component.client,
        scopes: scopes, port: 4000, urlLancher: component._urlLauncher);

    // Should find credentials when initialized directly after a redirect
    await component.authenticate();

    // Return the fully initialized object
    return component;
  }

  @override
  Future<Credential?> get credential async {
    return _credential;
  }

  @override
  Future<void> authenticate({List<String> scopes = const []}) async {
    authenticator = io.Authenticator(client,
        scopes: scopes, port: 4000, urlLancher: _urlLauncher);
    try {
      _credential = await authenticator.authorize();
    } catch (e) {
      developer.log("An error occurred during the login flow", error: e);
    }

    closeInAppWebView();
    developer.log("finished auth flow");
  }

  Future<void> _urlLauncher(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.inAppWebView);
    } catch (e) {
      developer.log("Could not launch URL ${Uri.parse(url)}", error: e);
    }
  }

  @override
  Future<TokenResponse?> getTokenResponse(
      {forceRefresh = false, List<String> scopes = const []}) async {
    return await _credential?.getTokenResponse(forceRefresh);
  }

  @override
  Future<Credential?> getRedirectResult(
      {List<String> scopes = const []}) async {
    return null;
  }

  @override
  void logout() {
    final logoutUrl = _credential?.generateLogoutUrl();
    if (logoutUrl == null) {
      return;
    }
    _credential?.createHttpClient().get(logoutUrl);
  }
}
