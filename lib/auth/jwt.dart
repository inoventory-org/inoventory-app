import 'package:inoventory_ui/auth/user_info.dart';
import 'package:jwt_decode/jwt_decode.dart';

class JWT {
  final String? accessToken;
  final String? refreshToken;
  final String? tokenType;

  JWT(this.accessToken, this.refreshToken, this.tokenType);

  static MyUserInfo getUserInfo(String token) {
    final parsedToken = Jwt.parseJwt(token);
    return MyUserInfo(
        parsedToken["name"],
        parsedToken["preferred_username"],
        parsedToken["given_name"],
        parsedToken["family_name"],
        parsedToken["email"]);
  }

  Map<String, dynamic> decodeAccessToken() {
    return (accessToken != null) ? Jwt.parseJwt(accessToken!) : {};
  }

  Map<String, dynamic> decodeRefreshToken() {
    return (refreshToken != null) ? Jwt.parseJwt(refreshToken!) : {};
  }

  DateTime? get accessTokenExpiryDate {
    return (accessToken != null) ? Jwt.getExpiryDate(accessToken!) : null;
  }

  DateTime? get refreshTokenExpiryDate {
    return (refreshToken != null) ? Jwt.getExpiryDate(refreshToken!) : null;
  }

  bool isAccessTokenExpired() {
    final now = DateTime.now();
    final exp = accessTokenExpiryDate ?? now.subtract(const Duration(days: 7));
    return now.isAfter(exp);
  }

  bool isRefreshTokenExpired() {
    final now = DateTime.now();
    final exp = refreshTokenExpiryDate ?? now.subtract(const Duration(days: 7));
    return now.isAfter(exp);
  }

  @override
  String toString() {
    return "access_token: $accessToken\nrefresh_token: $refreshToken\n,token_type: $tokenType";
  }
}
