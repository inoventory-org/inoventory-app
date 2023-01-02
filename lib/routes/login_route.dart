import 'package:flutter/material.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:inoventory_ui/config/constants.dart';
import 'package:inoventory_ui/routes/list/inventory_list_route.dart';

const FlutterAppAuth appAuth = FlutterAppAuth();
const FlutterSecureStorage secureStorage = FlutterSecureStorage();

class LoginRoute extends StatefulWidget {
  const LoginRoute({super.key});

  @override
  State<LoginRoute> createState() => _LoginRouteState();
}

class _LoginRouteState extends State<LoginRoute> {
  bool isBusy = false;
  bool isLoggedIn = false;
  String? errorMessage;
  String? name;
  String? picture;

  Map<String, dynamic> parseIdToken(String idToken) {
    final parts = idToken.split(r'.');
    assert(parts.length == 3);

    return jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
  }

  Future<Map> getUserDetails(String accessToken) async {
    const url = '${KeycloakConf.baseUrl}/userinfo';
    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get user details');
    }
  }

  Future<void> loginAction() async {
    setState(() {
      isBusy = true;
      errorMessage = '';
    });

    try {
      final AuthorizationTokenResponse? result =
          await appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          Constants.keycloakConf.clientId,
          Constants.keycloakConf.redirectUrl,
          discoveryUrl: Constants.keycloakConf.discoveryUrl,
          promptValues: ['login'],
          allowInsecureConnections: true,
          // scopes: ['openid', 'profile', 'offline_access'],
          // promptValues: ['login']
        ),
      );

      print("Finished authorizeAndExchangeCode flow");
      if (result?.accessToken == null) {
        //result?.idToken == null ||
        setState(() {
          isBusy = false;
          errorMessage = 'Something went wrong... Please try again.';
        });
        return;
      }

      // final idToken = parseIdToken(result.idToken!);
      // final profile = await getUserDetails(result.accessToken!);

      print("token: ${result?.accessToken?.toString()}");

      await secureStorage.write(
          key: 'refresh_token', value: result?.refreshToken);

      print("Stored token");

      setState(() {
        isBusy = false;
        isLoggedIn = true;
        // name = idToken['name'];
        // picture = profile['picture'];
      });
    } catch (e, s) {
      print('login error: $e - stack: $s');

      setState(() {
        isBusy = false;
        isLoggedIn = false;
        errorMessage = e.toString();
      });
    }
  }

  void logoutAction() async {
    await secureStorage.delete(key: 'refresh_token');
    setState(() {
      isLoggedIn = false;
      isBusy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return isLoggedIn
        ? const InventoryListRoute()
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  loginAction();
                },
                child: const Text('Login'),
              ),
              Text(errorMessage ?? ''),
            ],
          );
  }
}
