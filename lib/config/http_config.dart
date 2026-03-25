import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:inoventory_ui/config/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InoventoryTokenInterceptor extends InterceptorsWrapper {
  final Dio dio;

  InoventoryTokenInterceptor(
    this.dio,
  ) : super();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    developer.log("Request URL: ${options.uri.toString()}");
    if (!options.uri.toString().contains(Constants.inoventoryBackendUrl)) {
      return handler.next(options);
    }

    final accessToken = Supabase.instance.client.auth.currentSession?.accessToken;
    if (accessToken == null) {
      developer.log("Access token is null");
      return;
    }
    // developer.log("Adding access token to request:");
    // developer.log(accessToken);
    // developer.log("");
    // developer.log(tr!.refreshToken!);

    options.headers.addAll({"Authorization": "Bearer $accessToken"});
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err)) {
      await Supabase.instance.client.auth.signOut();
    }
    return handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    final isInoventoryRequest = err.requestOptions.uri.toString().contains(Constants.inoventoryBackendUrl);
    if (isInoventoryRequest && err.response?.statusCode == 401) {
      return true;
    }

    return false;
  }
}
