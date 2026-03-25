import 'dart:async';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:inoventory_ui/auth/login_route.dart';
import 'package:inoventory_ui/config/http_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/injection.dart';
import 'inventory/lists/inventory_list_overview_route.dart';

class InoventoryHomeRoute extends StatefulWidget {
  const InoventoryHomeRoute({super.key});

  @override
  State<InoventoryHomeRoute> createState() => _InoventoryHomeRouteState();
}

class _InoventoryHomeRouteState extends State<InoventoryHomeRoute> {
  final dio = getIt<Dio>();
  final supabase = Supabase.instance.client;
  Session? session;
  late final StreamSubscription<AuthState> authSubscription;

  @override
  void initState() {
    super.initState();
    session = supabase.auth.currentSession;
    authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      setState(() {
        session = data.session;
      });
    });
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
    setState(() {
      session = null;
    });
  }

  @override
  void dispose() {
    authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    developer.log("supabase session: ${session?.user.id}");
    return session != null
        ? InventoryListRoute(logout: logout)
        : const LoginRoute();
  }
}
