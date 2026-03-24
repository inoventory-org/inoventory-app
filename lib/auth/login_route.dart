import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:inoventory_ui/config/constants.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

class LoginRoute extends StatelessWidget {
  const LoginRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SupaEmailAuth(
                    redirectTo: kIsWeb ? null : Constants.supabaseRedirectUrl(kIsWeb),
                    onSignInComplete: (response) {},
                    onSignUpComplete: (response) {},
                    metadataFields: [
                      MetaDataField(
                        prefixIcon: const Icon(Icons.person),
                        label: 'Username',
                        key: 'username',
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Please enter something';
                          }
                          return null;
                        },
                      ),
                      BooleanMetaDataField(
                        label: 'I wish to receive marketing emails',
                        key: 'marketing_consent',
                        checkboxPosition: ListTileControlAffinity.leading,
                      ),
                      BooleanMetaDataField(
                        key: 'terms_agreement',
                        isRequired: true,
                        checkboxPosition: ListTileControlAffinity.leading,
                        richLabelSpans: [
                          const TextSpan(text: 'I have read and agree to the '),
                          TextSpan(
                            text: 'Terms and Conditions',
                            style: const TextStyle(color: Colors.blue),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                // TODO: Navigate to terms if needed
                              },
                          ),
                          const WidgetSpan(child: SizedBox(width: 4)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  SupaSocialsAuth(
                    socialProviders: const [OAuthProvider.google],
                    colored: true,
                    redirectUrl: kIsWeb ? null : Constants.supabaseRedirectUrl(kIsWeb),
                    onSuccess: (session) {},
                    onError: (error) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
