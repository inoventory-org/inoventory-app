import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:inoventory_ui/config/constants.dart';
import 'package:openid_client/openid_client_io.dart' as oidc;
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;

abstract class AuthService {
  Future<bool> login();
  Future<void> logout();
}

class OIDCAuthService implements AuthService {
  final FlutterSecureStorage secureStorage;
  final timeoutDuration = const Duration(seconds: 10);
  final Dio dio;

  OIDCAuthService(this.dio, this.secureStorage);

  @override
  Future<bool> login() async {
    final successTokenRefresh = await attemptToRefreshLogin();
    if (successTokenRefresh) {
      developer.log("Successfully refreshed token");
      return true;
    }
    developer.log("Trying classic login");
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
      oidc.TokenResponse tokenResponse = await creds.getTokenResponse();
      final isLoggedIn = (tokenResponse.accessToken != null);
      await _saveToken(tokenResponse);
      if (isLoggedIn) {
        return true;
      }
    } catch (e) {
      developer.log("An error occurred while logging in: ${e.toString()}",
          error: e);
    }

    await secureStorage.deleteAll();
    return false;
  }

  @override
  Future<void> logout() async {
    final accessToken = await secureStorage.read(key: "access_token");
    final refreshToken = await secureStorage.read(key: "refresh_token");
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
    await secureStorage.deleteAll();
  }

  Future<bool> attemptToRefreshLogin() async {
    final refreshToken = await secureStorage.read(key: "refresh_token");
    if (refreshToken == null) {
      developer.log("No stored refresh token found");
      return false;
    }
    final tokenType = await secureStorage.read(key: "token_type");

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
      final tokenResponse = await credential.getTokenResponse();
      await _saveToken(tokenResponse);
      return true;
    } catch (e) {
      developer.log("An error occurred while refreshing login: ${e.toString()}",
          error: e);
    }
    await secureStorage.deleteAll();
    return false;
  }

  Future<void> _saveToken(oidc.TokenResponse tokenResponse) async {
    await secureStorage.write(
        key: 'access_token', value: tokenResponse.accessToken);
    await secureStorage.write(
        key: 'refresh_token', value: tokenResponse.refreshToken);
    await secureStorage.write(
        key: 'token_type', value: tokenResponse.tokenType);
  }

  Future<void> _urlLauncher(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.inAppWebView);
    } catch (e) {
      developer.log("Could not launch URL ${Uri.parse(url)}", error: e);
    }
  }
}

// class FlutterAppAuthService implements AuthService {
//   final FlutterAppAuth appAuth = const FlutterAppAuth();
//   final Dio dio;
//   final FlutterSecureStorage secureStorage;
//   FlutterAppAuthService(this.dio, this.secureStorage);
//
//   Future<AuthState?> refreshLogin() async {
//     final String? refreshToken = await secureStorage.read(key: 'refresh_token');
//     if (refreshToken == null) return null;
//
//     final TokenResponse? result = await appAuth.token(TokenRequest(
//         Constants.keycloakConf.clientId, Constants.keycloakConf.redirectUrl,
//         discoveryUrl: Constants.keycloakConf.discoveryUrl,
//         refreshToken: refreshToken));
//     if (result == null) return null;
//
//     await secureStorage.write(key: 'refresh_token', value: result.refreshToken);
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
//           key: 'refresh_token', value: result.refreshToken);
//       await secureStorage.write(
//           key: 'access_token', value: result.accessToken);
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
//     final accessToken = await secureStorage.read(key: "access_token");
//     final refreshToken = await secureStorage.read(key: "refresh_token");
//     final body = {
//       'client_id': Constants.keycloakConf.clientId,
//       'refresh_token': refreshToken,
//     };
//     await dio.post(Constants.keycloakConf.endSessionUrl, options: Options(headers: {
//       "Content-Type": "application/x-www-form-urlencoded",
//       "Authorization": "Bearer $accessToken",
//     }), data: body);
//     await secureStorage.deleteAll();
//   }
// }
//
