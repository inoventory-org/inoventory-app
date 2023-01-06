import 'package:inoventory_ui/auth/services/auth_service.dart';
import 'package:inoventory_ui/config/constants.dart';
import 'package:openid_client/openid_client.dart';
import 'package:openid_client/openid_client_browser.dart' as browser;
import 'dart:developer' as developer;

class AuthServiceImpl extends AuthService {
  late final Client client;
  late final Issuer issuer;
  List<String>? scopes;
  late browser.Authenticator authenticator;
  late Credential? _credential;


  AuthServiceImpl._create(this.scopes);

  /// Public factory
  static Future<AuthService> create({List<String> scopes = const []}) async {

    // Call the private constructor
    var component = AuthServiceImpl._create(scopes);

    var uri = Uri.parse(KeycloakConf.baseUrlWithRealm);
    var clientId = Constants.keycloakConf.clientId;
    component.issuer = await Issuer.discover(uri);
    component.client = Client(component.issuer, clientId);
    component.authenticator = browser.Authenticator(component.client, scopes: scopes);

    // Should find credentials when initialized directly after a redirect
    component._credential = await component.getRedirectResult();

    if (await component.credential == null) {
      await component.authenticate();
    }

    final tr = await (await component.credential)?.getTokenResponse();
    developer.log("Access_token found: ${tr?.accessToken ?? "No Token found"}");
    // Return the fully initialized object
    return component;
  }

  @override
  Future<Credential?> get credential async {
    await _updateCredentials();
    developer.log("Credentials: $_credential");
    return _credential;
  }

  @override
  Future<void> authenticate({List<String> scopes = const []}) async {
    authenticator.authorize();
  }


  @override
  Future<TokenResponse?> getTokenResponse({List<String> scopes = const []}) async {
    final c = await authenticator.credential;
    return c?.getTokenResponse();
  }

  @override
  Future<Credential?> getRedirectResult({List<String> scopes = const []}) async {
    _credential = await authenticator.credential;
    return _credential;
  }


  Future<void> _updateCredentials() async {
    _credential = await authenticator.credential;
  }


}


// import 'dart:html';
//
// import 'package:dio/dio.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:inoventory_ui/auth/services/auth_service.dart';
// import 'package:inoventory_ui/auth/jwt.dart';
// import 'package:inoventory_ui/config/constants.dart';
// import 'package:openid_client/openid_client.dart';
// import 'package:openid_client/openid_client_browser.dart' as browser;
// import 'dart:developer' as developer;
//
// class OIDCAuthServiceForWeb extends AuthService {
//   final FlutterSecureStorage secureStorage;
//   final timeoutDuration = const Duration(seconds: 10);
//   final Dio dio;
//   final Client? client;
//   final List<String> scopes;
//   // Credential? credential;
//
//   OIDCAuthServiceForWeb(this.dio, this.secureStorage, {this.client, this.scopes = const []});
//
//   Future<Credential?> get credential async {
//     final client = await getClient();
//     var authenticator = browser.Authenticator(client, scopes: scopes);
//
//     var c = await authenticator.credential;
//
//     return c;
//   }
//
//   Future<TokenResponse?> get tokenResponse async {
//     final credential = await this.credential;
//     if (credential != null) {
//       return await credential.getTokenResponse();
//     }
//   }
//
//   Future<Client> getClient() async {
//     if (client != null) {
//       return client!;
//     }
//     var uri = Uri.parse(KeycloakConf.baseUrlWithRealm);
//     var clientId = Constants.keycloakConf.clientId;
//
//     var issuer = await Issuer.discover(uri);
//     return Client(issuer, clientId);
//   }
//
//   @override
//   Future<Credential> authenticate(Client client,
//       {List<String> scopes = const []}) async {
//     final client = await getClient();
//     var authenticator = browser.Authenticator(client, scopes: scopes);
//
//     authenticator.authorize();
//
//     throw Exception('Will never reach here');
//   }
//
//   @override
//   Future<JWT?> login() async {
//     final issuer = await Issuer.discover(
//         Uri.parse(KeycloakConf.baseUrlWithRealm));
//     final client = Client(issuer, Constants.keycloakConf.clientId);
//
//     // final authenticator = browser.Authenticator(
//     //   client
//     // );
//
//     // get the credential
//     var credentials = await _getRedirectResult(client);
//     developer.log("Credentials: $credentials");
//
//     if (credentials == null) {
//       // starts the authentication
//       // authenticator.authorize(); // this will redirect the browser
//       var credentials = await _performFlow(client);
//       developer.log("finished flow");
//       // credentials = await authenticator.credential;
//       TokenResponse? tr = await credentials.getTokenResponse();
//       developer.log("returning credentials: $credentials");
//       return JWT(tr?.accessToken, tr?.refreshToken, tr?.tokenType);
//       // return JWT(null, null, null);
//     } else {
//       // return the user info
//       try {
//         developer.log("Credentials not null!");
//         TokenResponse tr = await credentials.getTokenResponse();
//         final isLoggedIn = (tr.accessToken != null);
//         if (isLoggedIn) {
//           return JWT(tr.accessToken, tr.refreshToken, tr.tokenType);
//         }
//       } catch (e) {
//         developer.log("An error occurred while logging in: ${e.toString()}",
//             error: e);
//       }
//     }
//     clearStorage();
//     return null;
//   }
//
//   Future<Credential> _performFlow(Client client,
//       {List<String> scopes = const []}) async {
//     var authenticator = browser.Authenticator(client, scopes: scopes);
//
//     authenticator.authorize();
//
//     throw Exception('Will never reach here');
//   }
//
//   Future<Credential?> _getRedirectResult(Client client,
//       {List<String> scopes = const []}) async {
//     var authenticator = browser.Authenticator(client, scopes: scopes);
//
//     var c = await authenticator.credential;
//     print("Got redirect result: ");
//     print(c);
//     return c;
//   }
//
//   @override
//   Future<JWT?> attemptToRefreshLogin() async {
//     developer.log((await secureStorage.readAll()).toString());
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
//   Future<Credential?> getRedirectResult(Client client, {List<String> scopes = const []}) async {
//     var authenticator = browser.Authenticator(client, scopes: scopes);
//
//     var c = await authenticator.credential;
//     print("Got redirect result: ");
//     print(c);
//     return c;
//   }
// }
//
