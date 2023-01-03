import 'package:dio/dio.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:inoventory_ui/config/constants.dart';
import 'package:inoventory_ui/models/auth_response.dart';
import 'package:openid_client/openid_client_io.dart' as oidc;
import 'package:url_launcher/url_launcher.dart';


abstract class AuthService {
  Future<AuthState> login();
  Future<void> logout();
}

class FlutterAppAuthService implements AuthService {
  final FlutterAppAuth appAuth = const FlutterAppAuth();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final Dio dio;
  FlutterAppAuthService(this.dio);

  Future<AuthState?> refreshLogin() async {
    final String? refreshToken = await secureStorage.read(key: 'refresh_token');
    if (refreshToken == null) return null;

    final TokenResponse? result = await appAuth.token(TokenRequest(
        Constants.keycloakConf.clientId, Constants.keycloakConf.redirectUrl,
        discoveryUrl: Constants.keycloakConf.discoveryUrl,
        refreshToken: refreshToken));
    if (result == null) return null;

    await secureStorage.write(key: 'refresh_token', value: result.refreshToken);

    return AuthState.fromTokenResponse(result);
  }

  @override
  Future<AuthState> login() async {
    try {
      // Attempts to keep user authenticated, if previously logged and refreshToken has not expired.
      // final AuthState? authState = await refreshLogin();
      // if (authState != null) { return authState; }

      final AuthorizationTokenResponse? result =
          await appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          Constants.keycloakConf.clientId,
          Constants.keycloakConf.redirectUrl,
          discoveryUrl: Constants.keycloakConf.discoveryUrl,
          promptValues: ['login'],
          allowInsecureConnections: true,
          // scopes: ['openid', 'profile', 'offline_access'],
        ),
      );

      if (result == null) {return AuthState.empty();}

      await secureStorage.write(
          key: 'refresh_token', value: result.refreshToken);
      await secureStorage.write(
          key: 'access_token', value: result.accessToken);

      return AuthState.fromTokenResponse(result);
    } catch (e, s) {
      print('login error: $e - stack: $s');
      final response = AuthState.empty();
      response.errorMessage = e.toString();
      return response;
    }
  }

  @override
  Future<void> logout() async {
    final accessToken = await secureStorage.read(key: "access_token");
    final refreshToken = await secureStorage.read(key: "refresh_token");
    final body = {
      'client_id': Constants.keycloakConf.clientId,
      'refresh_token': refreshToken,
    };
    await dio.post(Constants.keycloakConf.endSessionUrl, options: Options(headers: {
      "Content-Type": "application/x-www-form-urlencoded",
      "Authorization": "Bearer $accessToken",
    }), data: body);
    await secureStorage.deleteAll();
  }
}

class OIDCAuthService implements AuthService {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final timeoutDuration = const Duration(seconds: 10);
  final Dio dio;

  OIDCAuthService(this.dio);

  @override
  Future<AuthState> login() async {
    final issuer = await oidc.Issuer.discover(
        Uri.parse("${KeycloakConf.baseUrl}/realms/inoventory/"));
    final client = oidc.Client(issuer, Constants.keycloakConf.clientId);

    urlLauncher(String url) async {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.inAppWebView);
      } else {
        throw 'Could not launch $url';
      }
    }

    /** This authenticator automatically uses the recommended PKCE, which
     * does not require speicying a redirect url.
     * The authenticator automatically starts a local HTTP server and redirects
     * to http:/localhost:<port>/ -> This URL must be configured as a valid
     * redirect URL at the IdP.
     * See more: https://stackoverflow.com/questions/60814356/authenticate-flutter-app-with-keycloak-and-openid-client
     */
    final authenticator = oidc.Authenticator(client,
        port: 4000,
        urlLancher: urlLauncher,
    );

    // starts the authentication
    final creds = await authenticator.authorize();

    // close the webview when finished
    closeInAppWebView();

    oidc.TokenResponse tokenResponse = await creds.getTokenResponse();
    final isLoggedIn = (tokenResponse.accessToken != null);

    await secureStorage.write(
        key: 'access_token', value: tokenResponse.accessToken);
    await secureStorage.write(
        key: 'refresh_token', value: tokenResponse.refreshToken);

    // return the user info
    return AuthState.partial(
        isLoggedIn: isLoggedIn,
        accessToken: tokenResponse.accessToken,
        refreshToken: tokenResponse.refreshToken,
        idToken: tokenResponse.idToken.toString(),
        accessTokenExpirationDateTime: tokenResponse.expiresAt);
  }

  @override
  Future<void> logout() async {
    final accessToken = await secureStorage.read(key: "access_token");
    final refreshToken = await secureStorage.read(key: "refresh_token");
    final body = {
      'client_id': Constants.keycloakConf.clientId,
      'refresh_token': refreshToken,
    };

    await dio.post(Constants.keycloakConf.endSessionUrl, options: Options(headers: {
      "Content-Type": "application/x-www-form-urlencoded",
      "Authorization": "Bearer $accessToken",
    }), data: body);
    await secureStorage.deleteAll();
  }
}
