import 'package:flutter/material.dart';
import 'package:inoventory_ui/config/dependencies.dart';
import 'package:inoventory_ui/models/auth_response.dart';
import 'package:inoventory_ui/routes/list/inventory_list_route.dart';
import 'package:inoventory_ui/routes/login_route.dart';
import 'package:inoventory_ui/services/auth_service.dart';

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

  // @override
  // Widget build(BuildContext context) {
  //   return InventoryListRoute(logout: logout);
  // }

  // This widget is the root of your application.
  // @override
  // Widget build(BuildContext context) {
  //   return FutureBuilder(
  //     future: futureAuthState,
  //     builder:(context, snapshot) {return LoginRoute(login: login);});
  // }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuthState>(
        future: futureAuthState,
        initialData: AuthState.empty(),
        builder: ((context, snapshot) {
          // final scaffoldMessenger = ScaffoldMessenger.of(context);
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
            //   scaffoldMessenger.showSnackBar(SnackBar(
            //       content: Text("${snapshot.error}",
            //           style: const TextStyle(color: Colors.white)),
            //       backgroundColor: Colors.red));
              print("Error: ${snapshot.error}");
              return Center(child: Text('${snapshot.error}'));
            }

            if (snapshot.hasData) {
              return snapshot.data!.isLoggedIn
                  ? InventoryListRoute(logout: logout)
                  : LoginRoute(login: login);
            }
          }
          return const Center(child: CircularProgressIndicator());
        }));
  }
}
