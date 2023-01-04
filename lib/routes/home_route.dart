import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:inoventory_ui/config/constants.dart';
import 'package:inoventory_ui/config/dependencies.dart';
import 'package:inoventory_ui/routes/list/inventory_list_route.dart';
import 'package:inoventory_ui/routes/login_route.dart';
import 'package:inoventory_ui/services/auth_service.dart';
import 'package:inoventory_ui/widgets/inoventory_appbar.dart';

import 'dart:developer' as developer;

class InoventoryHomeRoute extends StatefulWidget {
  const InoventoryHomeRoute({super.key});

  @override
  State<InoventoryHomeRoute> createState() => _InoventoryHomeRouteState();
}

class _InoventoryHomeRouteState extends State<InoventoryHomeRoute> {
  final AuthService authService = Dependencies.authService;
  final FlutterSecureStorage secureStorage = Dependencies.secureStorage;
  final dio = Dependencies.dio;
  late Future<bool> futureLoginState;
  final accessTokenRefreshIntervalSeconds = Constants.accessTokenRefreshIntervalSeconds;


  @override
  void initState() {
    super.initState();
    futureLoginState = authService.login();
    setUpHttpInterceptors();
    Timer.periodic(Duration(seconds: accessTokenRefreshIntervalSeconds), (Timer timer) async {
      await authService.login();
    });
  }

  Future<void> login() async {
    setState(() {
      futureLoginState = authService.login();
    });
  }

  Future<void> logout() async {
    authService.logout();
    setState(() {
      futureLoginState = Future.value(false);
    });
  }

  void setUpHttpInterceptors()  {
    dio.interceptors.add(InterceptorsWrapper(
        onRequest:(options, handler) async {
          final accessToken = await secureStorage.read(key: "access_token");
          if (accessToken == null) {
            developer.log("Access token is null");
            return;
          }
          options.headers.addAll({"Authorization": "Bearer $accessToken"});
          return handler.next(options);
        },
        onResponse:(response,handler) {
          return handler.next(response);
        },
        onError: (DioError e, handler) async {
          if (e.response?.statusCode == 401) {
              if (await secureStorage.containsKey(key: "refresh_token")) {
                setState(() {
                  futureLoginState = authService.login();
                });
              }
          }
          return handler.next(e);
        }
    ));
  }



  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
        future: futureLoginState,
        initialData: false,
        builder: ((context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              developer.log("Error: ${snapshot.error}");
              return Scaffold(appBar: InoventoryAppBar(),
                  body: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(child: Text('${snapshot.error}')
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(child: const Text("Retry Login"), onPressed: () {
                        login();
                      })
                    ],
                  ));
            }
            if (snapshot.hasData) {
              final isLoggedIn = snapshot.data!;
              return isLoggedIn
                  ? InventoryListRoute(logout: logout)
                  : Scaffold(appBar: InoventoryAppBar(), body: LoginRoute(login: login)
              );
            }
          }
          return const Center(child: CircularProgressIndicator());
        }));
  }
}
