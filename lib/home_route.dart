import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:inoventory_ui/auth/login_route.dart';
import 'package:inoventory_ui/auth/services/auth_service.dart';
import 'package:inoventory_ui/config/constants.dart';
import 'package:inoventory_ui/config/http_config.dart';
import 'package:inoventory_ui/shared/widgets/inoventory_appbar.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:url_launcher/url_launcher.dart';

import 'config/injection.dart';
import 'inventory/lists/inventory_list_overview_route.dart';

class InoventoryHomeRoute extends StatefulWidget {
  final AuthService authService;

  const InoventoryHomeRoute({super.key, required this.authService});

  @override
  State<InoventoryHomeRoute> createState() => _InoventoryHomeRouteState();
}

class _InoventoryHomeRouteState extends State<InoventoryHomeRoute> {
  late final AuthService authService = widget.authService;
  final dio = getIt<Dio>();
  String? authenticatedUserName;
  final accessTokenRefreshIntervalSeconds = Constants.accessTokenRefreshIntervalSeconds;

  @override
  void initState() {
    whenAuthenticated();
    super.initState();
    _setUpHttpInterceptors();
    // _setUpAutomaticAccessTokenRefreshing(refreshIntervalSeconds: Constants.accessTokenRefreshIntervalSeconds);
  }

  void whenAuthenticated() {
    authService.credential.then((c) {
      c?.getTokenResponse().then((tr) {
        setState(() {
          authenticatedUserName = (tr.accessToken != null) ? Jwt.parseJwt(tr.accessToken!)["preferred_username"] : null;
        });
      });
    });
  }

  Future<void> whenNotAuthenticated() async {
    await authService.authenticate();
    whenAuthenticated();
  }

  void _setUpHttpInterceptors() {
    developer.log("Setting up HTTP Interceptors");
    dio.interceptors.add(InoventoryTokenInterceptor(dio, authService, whenAuthenticated, whenNotAuthenticated));
  }

  // void _setUpAutomaticAccessTokenRefreshing({refreshIntervalSeconds = 60}) {
  //   if (kIsWeb) {
  //     developer.log("Automatic refreshing of tokens is currently not supported for the web."
  //         "You simply need to reauthenticate once the token expires");
  //     return;
  //   }
  //   Timer.periodic(Duration(seconds: refreshIntervalSeconds), (Timer timer) async {
  //     await authService.getTokenResponse(forceRefresh: true);
  //   });
  // }

  Future<void> login() async {
    await whenNotAuthenticated();
    if (Platform.isAndroid || Platform.isIOS) {
      closeInAppWebView();
    }
  }

  Future<void> logout() async {
    await authService.logout();
    setState(() {
      authenticatedUserName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    developer.log("authenticatedUserName: $authenticatedUserName");
    return authenticatedUserName != null ? InventoryListRoute(logout: logout) : Scaffold(appBar: const InoventoryAppBar(), body: LoginRoute(login: login));
  }
}
