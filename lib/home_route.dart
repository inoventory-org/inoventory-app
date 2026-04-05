import 'dart:async';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:inoventory_ui/auth/login_route.dart';
import 'package:inoventory_ui/products/product_upload_job_service.dart';
import 'package:inoventory_ui/settings/off_settings_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/injection.dart';
import 'inventory/lists/inventory_list_overview_route.dart';

import 'notifications/push_notification_service.dart';
import 'inventory/items/item_list_route.dart';
import 'inventory/lists/models/inventory_list.dart';
import 'inventory/lists/inventory_list_service.dart';

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
  StreamSubscription<ProductUploadJobEvent>? jobEventsSubscription;
  bool _offPromptCheckInFlight = false;
  bool _offPromptShownForSession = false;

  final _notificationService = getIt<PushNotificationService>();
  final _productUploadJobService = getIt<ProductUploadJobService>();
  final _inventoryListService = getIt<InventoryListService>();
  final _offSettingsService = getIt<OffSettingsService>();

  @override
  void initState() {
    super.initState();
    session = supabase.auth.currentSession;

    _notificationService.onListNotificationTapped = (String rawListId) async {
      developer.log("Notification tapped for List ID: $rawListId");

      try {
        final int listId = int.parse(rawListId);

        // Fetch the full list object from the backend
        final InventoryList list = await _inventoryListService.get(listId);

        // Ensure the widget is still on screen before navigating across an async gap
        if (!mounted) return;

        // Navigate directly to the item list, with the expiring items sorted at the top!
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ItemListRoute(
              list: list,
              focusExpiring: true,
            ),
          ),
        );
      } catch (e) {
        developer.log("Failed to navigate to expiring items list", error: e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not load that list.')),
          );
        }
      }
    };

    authSubscription = supabase.auth.onAuthStateChange.listen((data) async {
      setState(() {
        session = data.session;
      });

      // If the user just logged in (or app started and they are already logged in)
      if (data.session != null) {
        // Initialize FCM listeners and sync the token to your Spring Boot backend
        await _notificationService.initialize();
        await _notificationService.syncFcmToken();
        unawaited(_ensureOffContributionSettingsPrompt());
      } else {
        _offPromptShownForSession = false;
      }
    });

    jobEventsSubscription = _productUploadJobService.events.listen((event) {
      if (!mounted) {
        return;
      }
      final isCompleted = event.job.status == ProductUploadJobStatus.completed;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCompleted
                ? '${event.job.actionLabel} finished for ${event.job.product.ean}'
                : '${event.job.actionLabel} failed for ${event.job.product.ean}: ${event.job.message}',
          ),
          backgroundColor: isCompleted ? Colors.green : Colors.red,
        ),
      );
    });

    if (session != null) {
      unawaited(_ensureOffContributionSettingsPrompt());
    }
  }

  Future<void> _ensureOffContributionSettingsPrompt() async {
    if (!mounted ||
        session == null ||
        _offPromptCheckInFlight ||
        _offPromptShownForSession) {
      return;
    }

    _offPromptCheckInFlight = true;
    try {
      final hasSettings = await _offSettingsService.hasContributionSettings();
      if (!mounted ||
          session == null ||
          hasSettings ||
          _offPromptShownForSession) {
        return;
      }

      _offPromptShownForSession = true;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _OffSettingsPromptDialog(
          settingsService: _offSettingsService,
        ),
      );
    } finally {
      _offPromptCheckInFlight = false;
    }
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
    jobEventsSubscription?.cancel();
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

class _OffSettingsPromptDialog extends StatefulWidget {
  final OffSettingsService settingsService;

  const _OffSettingsPromptDialog({required this.settingsService});

  @override
  State<_OffSettingsPromptDialog> createState() =>
      _OffSettingsPromptDialogState();
}

class _OffSettingsPromptDialogState extends State<_OffSettingsPromptDialog> {
  String _region = OffSettingsService.defaultRegion;
  String _language = OffSettingsService.defaultLanguage;
  bool _isSaving = false;

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
    });

    await widget.settingsService.saveContributionSettings(
      region: _region,
      language: _language,
    );

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Open Food Facts settings saved',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose Open Food Facts Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select your contribution region and product language before using the app.',
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _region,
            items: offRegionOptions.entries
                .map(
                  (entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _region = value;
              });
            },
            decoration: const InputDecoration(
              labelText: 'Contribution Region',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _language,
            items: offLanguageOptions.entries
                .map(
                  (entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _language = value;
              });
            },
            decoration: const InputDecoration(
              labelText: 'Product Language',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Continue'),
        ),
      ],
    );
  }
}
