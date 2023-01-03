import 'package:flutter_appauth/flutter_appauth.dart';

class AuthState {
  bool isLoggedIn;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? accessTokenExpirationDateTime;
  final String? idToken;
  final String? tokenType;
  final List<String>? scopes;
  final Map<String, dynamic>? tokenAdditionalParameters;
  String? errorMessage;



  AuthState(
      this.isLoggedIn,
      this.accessToken,
      this.refreshToken,
      this.accessTokenExpirationDateTime,
      this.idToken,
      this.tokenType,
      this.scopes,
      this.tokenAdditionalParameters,
      this.errorMessage);

  AuthState.partial({this.isLoggedIn = false,
      this.accessToken,
      this.refreshToken,
      this.accessTokenExpirationDateTime,
      this.idToken,
      this.tokenType,
      this.scopes,
      this.tokenAdditionalParameters,
      this.errorMessage});


  factory AuthState.fromTokenResponse(TokenResponse response) {
    final isLoggedIn = (response.accessToken != null);
    return AuthState(
        isLoggedIn,
        response.accessToken,
        response.refreshToken,
        response.accessTokenExpirationDateTime,
        response.idToken,
        response.tokenType,
        response.scopes,
        response.tokenAdditionalParameters,
        null);
  }

  factory AuthState.empty() {
    return AuthState(false, null, null, null, null, null, null, null, null);
  }
}
