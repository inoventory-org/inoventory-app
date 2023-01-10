import 'package:flutter/material.dart';

class LoginRoute extends StatefulWidget {
  final Future<void> Function() login;

  const LoginRoute({super.key, required this.login});

  @override
  State<LoginRoute> createState() => _LoginRouteState();
}

class _LoginRouteState extends State<LoginRoute> {
  bool isBusy = false;

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
