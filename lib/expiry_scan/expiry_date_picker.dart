import 'package:flutter/material.dart';
import 'package:inoventory_ui/expiry_scan/controllers/expiry_scan_controller.dart';
import 'package:inoventory_ui/expiry_scan/routes/expiry_date_scan_route.dart';

Future<String?> pickExpiryDate(
  BuildContext context, {
  DateTime? initialDate,
  String? helpText,
  String? scanTitle,
}) async {
  final ExpiryScanController probe = ExpiryScanController();
  final bool isScanSupported = probe.isSupported;
  probe.dispose();

  if (!isScanSupported) {
    return _pickDateManually(
      context,
      initialDate: initialDate,
      helpText: helpText,
    );
  }

  final _ExpiryDatePickerAction? action =
      await showModalBottomSheet<_ExpiryDatePickerAction>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add expiry date',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () =>
                  Navigator.of(context).pop(_ExpiryDatePickerAction.scan),
              icon: const Icon(Icons.document_scanner_outlined),
              label: const Text('Scan expiry date'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.of(context).pop(_ExpiryDatePickerAction.manual),
              icon: const Icon(Icons.calendar_today),
              label: const Text('Choose manually'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    ),
  );

  if (action == null) {
    return null;
  }
  if (!context.mounted) {
    return null;
  }
  if (action == _ExpiryDatePickerAction.manual) {
    return _pickDateManually(
      context,
      initialDate: initialDate,
      helpText: helpText,
    );
  }

  final NavigatorState navigator = Navigator.of(context);
  return navigator.push<String>(
    MaterialPageRoute(
      builder: (_) => ExpiryDateScanRoute(
        title: scanTitle,
        helpText: helpText,
        initialDate: initialDate,
      ),
    ),
  );
}

Future<String?> _pickDateManually(
  BuildContext context, {
  DateTime? initialDate,
  String? helpText,
}) async {
  final DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: initialDate ?? DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
    helpText: helpText,
  );

  if (pickedDate == null) {
    return null;
  }
  return '${pickedDate.year.toString().padLeft(4, '0')}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
}

enum _ExpiryDatePickerAction { scan, manual }
