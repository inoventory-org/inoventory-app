import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:inoventory_ui/config/constants.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

class LoginRoute extends StatelessWidget {
  const LoginRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SupaEmailAuth(
            redirectTo: Constants.supabaseRedirectUrl(kIsWeb),
            onSignInComplete: (response) {},
            onSignUpComplete: (response) {},
          ),
        ),
      ),
    );
  }
}
