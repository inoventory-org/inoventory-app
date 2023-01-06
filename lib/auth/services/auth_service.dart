import 'package:openid_client/openid_client.dart';

abstract class AuthService {

  Future<void> authenticate({List<String> scopes = const []});
  Future<TokenResponse?> getTokenResponse({List<String> scopes = const []});
  Future<Credential?> get credential;
  Future<Credential?> getRedirectResult({List<String> scopes = const []});

}
