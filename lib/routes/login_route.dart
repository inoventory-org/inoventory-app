import 'package:flutter/material.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:inoventory_ui/config/constants.dart';


const FlutterAppAuth appAuth = FlutterAppAuth();
const FlutterSecureStorage secureStorage = FlutterSecureStorage();

class LoginRoute extends StatefulWidget {
  final Future<void> Function() login;

  const LoginRoute({super.key, required this.login});

  @override
  State<LoginRoute> createState() => _LoginRouteState();
}

class _LoginRouteState extends State<LoginRoute> {
  bool isBusy = false;

  // Map<String, dynamic> parseIdToken(String idToken) {
  //   final parts = idToken.split(r'.');
  //   assert(parts.length == 3);
  //
  //   return jsonDecode(
  //       utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
  // }
  //
  // Future<Map> getUserDetails(String accessToken) async {
  //   const url = '${KeycloakConf.baseUrl}/userinfo';
  //   final response = await http.get(
  //     Uri.parse(url),
  //     headers: {'Authorization': 'Bearer $accessToken'},
  //   );
  //
  //   if (response.statusCode == 200) {
  //     return jsonDecode(response.body);
  //   } else {
  //     throw Exception('Failed to get user details');
  //   }
  // }

  Future<void> loginAction() async {
    await widget.login();
  }


  @override
  Widget build(BuildContext context) {
    return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    loginAction();
                  },
                  child: const Text('Login'),
                ),
              ),
            ],
          );
  }
}
