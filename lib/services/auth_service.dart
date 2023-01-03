import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:inoventory_ui/config/constants.dart';
import 'package:inoventory_ui/models/auth_response.dart';
import 'package:openid_client/openid_client_io.dart' as oidc;
import 'package:url_launcher/url_launcher.dart';

abstract class AuthService {
  Future<AuthState> login();
  Future<bool> logout();
}

class FlutterAppAuthService implements AuthService {
  final FlutterAppAuth appAuth = const FlutterAppAuth();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  FlutterAppAuthService();

  Future<AuthState?> refreshLogin() async {
    print("Refershing Login...");
    final String? refreshToken = await secureStorage.read(key: 'refresh_token');
    if (refreshToken == null) return null;
    print("Retrieved refreshToken");

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

      print("Refresh Token: ${result?.refreshToken}");
      await secureStorage.write(
          key: 'refresh_token', value: result?.refreshToken);

      return (result != null)
          ? AuthState.fromTokenResponse(result)
          : AuthState.empty();
    } catch (e, s) {
      print('login error: $e - stack: $s');
      final response = AuthState.empty();
      response.errorMessage = e.toString();
      return response;
    }
  }

  @override
  Future<bool> logout() async {
    await secureStorage.delete(key: 'refresh_token');
    return true;
  }
}

class OIDCAuthService implements AuthService {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  @override
  Future<AuthState> login() async {
    // create the client
    final issuer = await oidc.Issuer.discover(
        Uri.parse("${KeycloakConf.baseUrl}/realms/inoventory/"));
    final client = oidc.Client(issuer, Constants.keycloakConf.clientId);
    print("Created client");

    // create a function to open a browser with an url
    urlLauncher(String url) async {
      print("URL to launch: $url");
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.inAppWebView);
      } else {
        throw 'Could not launch $url';
      }
    }

    // create an authenticator
    final authenticator = oidc.Authenticator(client,
        port: 4000,
        urlLancher: urlLauncher,
        redirectUri: Uri.parse("http://localhost:4000/")
      // redirectUri: Uri.parse(Constants.keycloakConf.redirectUrl)
    );
    print("Created authenticator");

    // starts the authentication
    final creds = await authenticator.authorize();
    print("Authenticated");

    // close the webview when finished
    closeInAppWebView();
    oidc.TokenResponse tokenResponse = await creds.getTokenResponse();
    final isLoggedIn = (tokenResponse.accessToken != null);
    print("Access token: ${tokenResponse.accessToken}");

    await secureStorage.write(
        key: 'refresh_token', value: tokenResponse.refreshToken);
    print("Persisted refresh token");

    // return the user info
    return AuthState.partial(
        isLoggedIn: isLoggedIn,
        accessToken: tokenResponse.accessToken,
        refreshToken: tokenResponse.refreshToken,
        idToken: tokenResponse.idToken.toString(),
        accessTokenExpirationDateTime: tokenResponse.expiresAt);
  }

  @override
  Future<bool> logout() async {
    await secureStorage.delete(key: 'refresh_token');
    return true;
  }
}
