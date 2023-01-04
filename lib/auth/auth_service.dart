import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:inoventory_ui/auth/jwt.dart';
import 'package:inoventory_ui/config/constants.dart';
import 'package:openid_client/openid_client_io.dart' as oidc;
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;

abstract class AuthService {

  Future<JWT?> login();
  Future<JWT?> attemptToRefreshLogin();
  FlutterSecureStorage _getSecureStorage();
  Dio _getDioClient();

  Future<bool> authenticate() async {
    final refreshedJwt = await attemptToRefreshLogin();
    if (refreshedJwt?.accessToken != null) {
      developer.log("Successfully refreshed token");
      await storeToken(refreshedJwt);
      return true;
    }

    final jwt = await login();
    if (jwt?.accessToken == null) {
      return false;
    }

    await storeToken(jwt);
    return true;
  }

  Future<void> logout() async {
    final secureStorage = _getSecureStorage();
    final dio = _getDioClient();
    final accessToken = await secureStorage.read(key: "accessToken");
    final refreshToken = await secureStorage.read(key: "refreshToken");
    final body = {
      'client_id': Constants.keycloakConf.clientId,
      'refresh_token': refreshToken,
    };

    await dio.post(Constants.keycloakConf.endSessionUrl,
        options: Options(headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "Authorization": "Bearer $accessToken",
        }),
        data: body);
    await clearStorage();
  }

  Future<void> storeToken(JWT? jwt) async {
    final secureStorage = _getSecureStorage();
    await secureStorage.write(
        key: 'accessToken', value: jwt?.accessToken);
    await secureStorage.write(
        key: 'refreshToken', value: jwt?.refreshToken);
    await secureStorage.write(
        key: 'tokenType', value: jwt?.tokenType);
  }

  Future<void> clearStorage() async {
    await _getSecureStorage().deleteAll();
  }

}

class OIDCAuthService extends AuthService {
  final FlutterSecureStorage secureStorage;
  final timeoutDuration = const Duration(seconds: 10);
  final Dio dio;

  OIDCAuthService(this.dio, this.secureStorage);

  @override
  Future<JWT?> login() async {
    final issuer = await oidc.Issuer.discover(
        Uri.parse("${KeycloakConf.baseUrl}/realms/inoventory/"));
    final client = oidc.Client(issuer, Constants.keycloakConf.clientId);

    /** This authenticator automatically uses the recommended PKCE, which
     * does not require specifying a redirect url.
     * The authenticator automatically starts a local HTTP server and redirects
     * to http:/localhost:<port>/ -> This URL must be configured as a valid
     * redirect URL at the IdP.
     * See more: https://stackoverflow.com/questions/60814356/authenticate-flutter-app-with-keycloak-and-openid-client
     */
    final authenticator = oidc.Authenticator(
      client,
      port: 4000,
      urlLancher: _urlLauncher,
    );

    // starts the authentication
    final creds = await authenticator.authorize();

    // close the webview when finished
    closeInAppWebView();

    try {
      oidc.TokenResponse tr = await creds.getTokenResponse();
      final isLoggedIn = (tr.accessToken != null);
      if (isLoggedIn) {
        return JWT(tr.accessToken, tr.refreshToken, tr.tokenType);
      }
    } catch (e) {
      developer.log("An error occurred while logging in: ${e.toString()}",
          error: e);
    }

    await clearStorage();
    return null;
  }

  @override
  Future<JWT?> attemptToRefreshLogin() async {
    final refreshToken = await secureStorage.read(key: "refreshToken");
    if (refreshToken == null) {
      developer.log("No stored refresh token found");
      return null;
    }
    final tokenType = await secureStorage.read(key: "tokenType");
    final issuer = await oidc.Issuer.discover(
        Uri.parse("${KeycloakConf.baseUrl}/realms/inoventory/"));
    final client = oidc.Client(issuer, Constants.keycloakConf.clientId);
    final credential = client.createCredential(
      accessToken: null, // force use refresh to get new token
      tokenType: tokenType,
      refreshToken: refreshToken,
    );

    credential.validateToken(validateClaims: true, validateExpiry: true);
    try {
      final tr = await credential.getTokenResponse();
      final jwt = JWT(tr.accessToken, tr.refreshToken, tr.tokenType);
      return jwt;
    } catch (e) {
      developer.log("An error occurred while refreshing login: ${e.toString()}",
          error: e);
    }
    await clearStorage();
    return null;
  }


  Future<void> _urlLauncher(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.inAppWebView);
    } catch (e) {
      developer.log("Could not launch URL ${Uri.parse(url)}", error: e);
    }
  }

  @override
  FlutterSecureStorage _getSecureStorage() {
    return secureStorage;
  }

  @override
  Dio _getDioClient() {
    return dio;
  }
}

// class FlutterAppAuthService implements AuthService {
//   final FlutterAppAuth appAuth = const FlutterAppAuth();
//   final Dio dio;
//   final FlutterSecureStorage secureStorage;
//   FlutterAppAuthService(this.dio, this.secureStorage);
//
//   Future<AuthState?> refreshLogin() async {
//     final String? refreshToken = await secureStorage.read(key: 'refreshToken');
//     if (refreshToken == null) return null;
//
//     final TokenResponse? result = await appAuth.token(TokenRequest(
//         Constants.keycloakConf.clientId, Constants.keycloakConf.redirectUrl,
//         discoveryUrl: Constants.keycloakConf.discoveryUrl,
//         refreshToken: refreshToken));
//     if (result == null) return null;
//
//     await secureStorage.write(key: 'refreshToken', value: result.refreshToken);
//
//     return AuthState.fromTokenResponse(result);
//   }
//
//   @override
//   Future<AuthState> login() async {
//     try {
//       // Attempts to keep user authenticated, if previously logged and refreshToken has not expired.
//       // final AuthState? authState = await refreshLogin();
//       // if (authState != null) { return authState; }
//
//       final AuthorizationTokenResponse? result =
//           await appAuth.authorizeAndExchangeCode(
//         AuthorizationTokenRequest(
//           Constants.keycloakConf.clientId,
//           Constants.keycloakConf.redirectUrl,
//           discoveryUrl: Constants.keycloakConf.discoveryUrl,
//           promptValues: ['login'],
//           allowInsecureConnections: true,
//           // scopes: ['openid', 'profile', 'offline_access'],
//         ),
//       );
//
//       if (result == null) {return AuthState.empty();}
//
//       await secureStorage.write(
//           key: 'refreshToken', value: result.refreshToken);
//       await secureStorage.write(
//           key: 'accessToken', value: result.accessToken);
//
//       return AuthState.fromTokenResponse(result);
//     } catch (e, s) {
//       developer.log('login error: $e - stack: $s');
//       final response = AuthState.empty();
//       response.errorMessage = e.toString();
//       return response;
//     }
//   }
//
//   @override
//   Future<void> logout() async {
//     final accessToken = await secureStorage.read(key: "accessToken");
//     final refreshToken = await secureStorage.read(key: "refreshToken");
//     final body = {
//       'client_id': Constants.keycloakConf.clientId,
//       'refreshToken': refreshToken,
//     };
//     await dio.post(Constants.keycloakConf.endSessionUrl, options: Options(headers: {
//       "Content-Type": "application/x-www-form-urlencoded",
//       "Authorization": "Bearer $accessToken",
//     }), data: body);
//     await secureStorage.deleteAll();
//   }
// }
//
