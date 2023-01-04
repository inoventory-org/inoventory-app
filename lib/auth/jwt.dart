import 'package:jwt_decode/jwt_decode.dart';


class JWT {
  final String? accessToken;
  final String? refreshToken;
  final String? tokenType;


  JWT(this.accessToken, this.refreshToken, this.tokenType);

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

}