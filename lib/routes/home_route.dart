import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:inoventory_ui/config/dependencies.dart';
import 'package:inoventory_ui/models/auth_response.dart';
import 'package:inoventory_ui/routes/list/inventory_list_route.dart';
import 'package:inoventory_ui/routes/login_route.dart';
import 'package:inoventory_ui/services/auth_service.dart';
import 'package:inoventory_ui/widgets/inoventory_appbar.dart';

class InoventoryHomeRoute extends StatefulWidget {
  const InoventoryHomeRoute({super.key});

  @override
  State<InoventoryHomeRoute> createState() => _InoventoryHomeRouteState();
}

class _InoventoryHomeRouteState extends State<InoventoryHomeRoute> {
  final AuthService authService = Dependencies.authService;
  late Future<AuthState> futureAuthState;

  @override
  void initState() {
    super.initState();
    futureAuthState = authService.login();
  }

  Future<void> login() async {
    setState(() {
      futureAuthState = authService.login();
    });
  }

  Future<void> logout() async {
    authService.logout();
    setState(() {
      futureAuthState = Future.value(AuthState.empty());
    });
  }

  void updateAccessToken(String? accessToken) {
    if (accessToken == null) {
      print("Access token is null");
      return;
    }
    final dio = Dependencies.dio;
    dio.interceptors.add(InterceptorsWrapper(
        onRequest:(options, handler){
          // Do something before request is sent
          options.headers.addAll({"Authorization": "Bearer $accessToken"});
          return handler.next(options); //continue
          // If you want to resolve the request with some custom data，
          // you can resolve a `Response` object eg: `handler.resolve(response)`.
          // If you want to reject the request with a error message,
          // you can reject a `DioError` object eg: `handler.reject(dioError)`
        },
        onResponse:(response,handler) {
          // Do something with response data
          return handler.next(response); // continue
          // If you want to reject the request with a error message,
          // you can reject a `DioError` object eg: `handler.reject(dioError)`
        },
        onError: (DioError e, handler) {
          // Do something with response error
          return  handler.next(e);//continue
          // If you want to resolve the request with some custom data，
          // you can resolve a `Response` object eg: `handler.resolve(response)`.
        }
    ));
  }



  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuthState>(
        future: futureAuthState,
        initialData: AuthState.empty(),
        builder: ((context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              print("Error: ${snapshot.error}");
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
              updateAccessToken(snapshot.data?.accessToken);
              return snapshot.data!.isLoggedIn
                  ? InventoryListRoute(logout: logout)
                  : Scaffold(appBar: InoventoryAppBar(), body: LoginRoute(login: login)
              );
            }
          }
          return const Center(child: CircularProgressIndicator());
        }));
  }
}
