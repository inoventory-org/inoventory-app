
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:inoventory_ui/auth/services/auth_service.dart';
import 'package:openid_client/openid_client.dart';
import 'package:openid_client/openid_client_io.dart' as io;
import 'package:inoventory_ui/config/constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;



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
  static Future<AuthService> create({List<String> scopes = const [],
  Future<void> Function()? onLoginSuccess})  async {

    // Call the private constructor
    var component = AuthServiceImpl._create(scopes, onLoginSuccess);
    var uri = Uri.parse(KeycloakConf.baseUrlWithRealm);
    var clientId = Constants.keycloakConf.clientId;

    component.secureStorage = const FlutterSecureStorage();
    component.issuer = await Issuer.discover(uri);
    component.client = Client(component.issuer, clientId);
    component.authenticator
    = io.Authenticator(component.client,
        scopes: scopes,
        port: 4000, urlLancher: component._urlLauncher);

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
    authenticator
    = io.Authenticator(client,
        scopes: scopes,
        port: 4000, urlLancher: _urlLauncher);
    try {
      _credential = await authenticator.authorize();
    } catch (e) {
      developer.log("An error occurred during the login flow", error: e);
    }


    developer.log("finished auth flow");
    closeInAppWebView();
    developer.log("Should have closed window");
  }

    Future<void> _urlLauncher(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.inAppWebView);
    } catch (e) {
      developer.log("Could not launch URL ${Uri.parse(url)}", error: e);
    }
  }

  @override
  Future<TokenResponse?> getTokenResponse({List<String> scopes = const []}) async {
     return await _credential?.getTokenResponse(true);
  }

  @override
  Future<Credential?> getRedirectResult({List<String> scopes = const []}) async {
    return null;
  }

  Future<void> _storeToken(TokenResponse? tr) async {
    await secureStorage.write(key: "access_token", value: tr?.accessToken);
    await secureStorage.write(key: "refresh_token", value: tr?.refreshToken);
    await secureStorage.write(key: "token_type", value: tr?.tokenType);
  }

}


// import 'dart:html';
//
// import 'package:dio/dio.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:inoventory_ui/auth/jwt.dart';
// import 'package:inoventory_ui/auth/services/auth_service.dart';
// import 'package:inoventory_ui/config/constants.dart';
//
// import 'package:url_launcher/url_launcher.dart';
// import 'dart:developer' as developer;
// import 'package:openid_client/openid_client_io.dart';
//
// class OIDCAuthService extends AuthService {
//   final FlutterSecureStorage secureStorage;
//   final timeoutDuration = const Duration(seconds: 10);
//   final Dio dio;
//
//   OIDCAuthService(this.dio, this.secureStorage);
//
//   @override
//   Future<JWT?> login() async {
//     final issuer = await Issuer.discover(
//         Uri.parse("${KeycloakConf.baseUrl}/realms/inoventory/"));
//     final client = Client(issuer, Constants.keycloakConf.clientId);
//
//     /** This authenticator automatically uses the recommended PKCE, which
//      * does not require specifying a redirect url.
//      * The authenticator automatically starts a local HTTP server and redirects
//      * to http:/localhost:<port>/ -> This URL must be configured as a valid
//      * redirect URL at the IdP.
//      * See more: https://stackoverflow.com/questions/60814356/authenticate-flutter-app-with-keycloak-and-openid-client
//      */
//     final authenticator = Authenticator(
//       client,
//       port: 4000,
//       urlLancher: _urlLauncher,
//     );
//
//     // starts the authentication
//     final creds = await authenticator.authorize();
//
//     // close the webview when finished
//     closeInAppWebView();
//
//     try {
//       TokenResponse tr = await creds.getTokenResponse();
//       final isLoggedIn = (tr.accessToken != null);
//       if (isLoggedIn) {
//         return JWT(tr.accessToken, tr.refreshToken, tr.tokenType);
//       }
//     } catch (e) {
//       developer.log("An error occurred while logging in: ${e.toString()}",
//           error: e);
//     }
//
//     await clearStorage();
//     return null;
//   }
//
//   @override
//   Future<JWT?> attemptToRefreshLogin() async {
//     final refreshToken = await secureStorage.read(key: "refreshToken");
//     if (refreshToken == null) {
//       developer.log("No stored refresh token found");
//       return null;
//     }
//     final tokenType = await secureStorage.read(key: "tokenType");
//     final issuer = await Issuer.discover(
//         Uri.parse("${KeycloakConf.baseUrl}/realms/inoventory/"));
//     final client = Client(issuer, Constants.keycloakConf.clientId);
//     final credential = client.createCredential(
//       accessToken: null, // force use refresh to get new token
//       tokenType: tokenType,
//       refreshToken: refreshToken,
//     );
//
//     credential.validateToken(validateClaims: true, validateExpiry: true);
//     try {
//       final tr = await credential.getTokenResponse();
//       final jwt = JWT(tr.accessToken, tr.refreshToken, tr.tokenType);
//       return jwt;
//     } catch (e) {
//       developer.log("An error occurred while refreshing login: ${e.toString()}",
//           error: e);
//     }
//     await clearStorage();
//     return null;
//   }
//
//
//   Future<void> _urlLauncher(String url) async {
//     try {
//       await launchUrl(Uri.parse(url), mode: LaunchMode.inAppWebView);
//     } catch (e) {
//       developer.log("Could not launch URL ${Uri.parse(url)}", error: e);
//     }
//   }
//
//   @override
//   FlutterSecureStorage _getSecureStorage() {
//     return secureStorage;
//   }
//
//   @override
//   Dio _getDioClient() {
//     return dio;
//   }
//
//   @override
//   Future<Credential?> getRedirectResult(Client client, {List<String> scopes = const []}) {
//     // TODO: implement getRedirectResult
//     throw UnimplementedError();
//   }
// }