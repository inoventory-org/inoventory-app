// import 'package:flutter/material.dart';
// import 'package:inoventory_ui/config/dependencies.dart';
// import 'package:inoventory_ui/routes/list/inventory_list_route.dart';
// import 'package:inoventory_ui/services/auth_service.dart';
//
// class LoginRouteCopy extends StatefulWidget {
//   // final Future<bool> Function(String username, String password) login;
//   // final Future<bool> Function(String username, String password) register;
//
//   const LoginRouteCopy({Key? key}) : super(key: key);
//
//   @override
//   _LoginRouteCopyState createState() => _LoginRouteCopyState();
// }
//
// class _LoginRouteCopyState extends State<LoginRouteCopy> {
//   final TextEditingController _usernameController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final FlutterAppAuthService authService = Dependencies.authService;
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(12.0),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           TextField(
//             controller: _usernameController,
//             decoration: const InputDecoration(
//               labelText: 'Username',
//             ),
//           ),
//           TextField(
//             controller: _passwordController,
//             obscureText: true,
//             decoration: const InputDecoration(
//               labelText: 'Password',
//             ),
//           ),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               ElevatedButton(
//                 child: const Text('Login'),
//                 onPressed: () async {
//                   final scaffoldMessenger = ScaffoldMessenger.of(context);
//                   final navigator = Navigator.of(context);
//                   final username = _usernameController.text;
//                   final password = _passwordController.text;
//                   final success = await authService.login(username, password);
//                   if (success) {
//                     scaffoldMessenger.showSnackBar(const SnackBar(
//                       content: Text('Successful Login!', style: TextStyle(color: Colors.white)),
//                       backgroundColor: Colors.green
//                     ));
//                     navigator.push(MaterialPageRoute(
//                                     builder: (context) => const InventoryListRoute())
//                     );
//                   } else {
//                     scaffoldMessenger.showSnackBar(const SnackBar(
//                       content: Text('Invalid username or password', style: TextStyle(color: Colors.white)),
//                       backgroundColor: Colors.red,
//                     ));
//                   }
//                 },
//               ),
//               const SizedBox(width: 4), // give it width
//               ElevatedButton(
//                 child: const Text('Register'),
//                 onPressed: () async {
//                   final scaffoldMessenger = ScaffoldMessenger.of(context);
//                   final navigator = Navigator.of(context);
//                   final username = _usernameController.text;
//                   final password = _passwordController.text;
//                   final success = await authService.register(username, password);
//                   if (success) {
//                     scaffoldMessenger.showSnackBar(const SnackBar(
//                       content: Text('Successfully Registered!', style: TextStyle(color: Colors.white)),
//                       backgroundColor: Colors.green,
//                     ));
//                   } else {
//                     scaffoldMessenger.showSnackBar(const SnackBar(
//                       content: Text('Failed to register', style: TextStyle(color: Colors.white)),
//                       backgroundColor: Colors.red,
//                     ));
//                   }
//                 },
//               ),
//             ],
//           ),
//
//         ],
//       ),
//     );
//   }
// }
