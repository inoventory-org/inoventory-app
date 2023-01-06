import 'package:dio/dio.dart';
import 'package:inoventory_ui/auth/services/auth_service.dart';
import 'package:inoventory_ui/config/constants.dart';
import 'dart:developer' as developer;
import 'package:openid_client/openid_client.dart';

class InoventoryHttpInterceptor extends InterceptorsWrapper {
  final AuthService authService;
  final Dio dio;
  final void Function()? onAuthSuccess;
  final Future<void> Function()? onAuthFail;

  InoventoryHttpInterceptor(
    this.dio,
    this.authService,
    this.onAuthSuccess,
    this.onAuthFail,
  ) : super();

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.uri.toString().contains(Constants.inoventoryBackendUrl)) {
      TokenResponse? tr;
      try {
        tr = await authService.getTokenResponse();
      } catch (e) {
        developer.log("Unable to retrieve access token", error: e);
        await onAuthFail?.call();
        return handler.resolve(await _retry(options));
      }
      final accessToken = tr?.accessToken;
      if (accessToken == null) {
        developer.log("Access token is null");
        await onAuthFail?.call();
        return;
      }
      // developer.log("Adding access token to request:");
      // print(accessToken);
      options.headers.addAll({"Authorization": "Bearer $accessToken"});
    }
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    return handler.next(response);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err)) {
      // must retrigger login
      await authService.authenticate();
      onAuthFail?.call();
    }
    return handler.next(err);
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final options = Options(
        method: requestOptions.method,
        sendTimeout: requestOptions.sendTimeout,
        receiveTimeout: requestOptions.receiveTimeout,
        extra: requestOptions.extra,
        headers: requestOptions.headers,
        responseType: requestOptions.responseType,
        contentType: requestOptions.contentType,
        validateStatus: requestOptions.validateStatus,
        receiveDataWhenStatusError: requestOptions.receiveDataWhenStatusError,
        followRedirects: requestOptions.followRedirects,
        maxRedirects: requestOptions.maxRedirects,
        requestEncoder: requestOptions.requestEncoder,
        responseDecoder: requestOptions.responseDecoder,
        listFormat: requestOptions.listFormat);

    return await dio.request(requestOptions.uri.toString(),
        options: options, queryParameters: requestOptions.queryParameters);
  }

  bool _shouldRetry(DioError err) {
    final isInoventoryRequest = err.requestOptions.uri
        .toString()
        .contains(Constants.inoventoryBackendUrl);
    if (isInoventoryRequest && err.response?.statusCode == 401) {
      return true;
    }

    return false;
  }
}
