import 'package:flutter/material.dart';
import 'package:inoventory_ui/expiry_scan/controllers/expiry_scan_controller.dart';
import 'package:inoventory_ui/expiry_scan/models/expiry_scan_candidate.dart';
import 'package:inoventory_ui/expiry_scan/routes/expiry_date_scan_route.dart';

enum ExpiryDateConfirmationMode { autoApply, requireConfirmation }

Future<String?> pickExpiryDate(
  BuildContext context, {
  DateTime? initialDate,
  String? helpText,
  String? scanTitle,
  ExpiryDateConfirmationMode confirmationMode =
      ExpiryDateConfirmationMode.autoApply,
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
        confirmationMode: confirmationMode,
      ),
    ),
  );
}

Future<ExpiryDateScanConfirmationResult?> confirmScannedExpiryDate(
  BuildContext context, {
  required List<ExpiryScanCandidate> candidates,
  required String initialDate,
  String? title,
  String? helpText,
}) {
  return showModalBottomSheet<ExpiryDateScanConfirmationResult>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _ExpiryScanConfirmationSheet(
      title: title,
      helpText: helpText,
      candidates: candidates,
      initialDate: initialDate,
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

enum ExpiryScanConfirmationAction { confirm, retry, cancel }

class ExpiryDateScanConfirmationResult {
  final ExpiryScanConfirmationAction action;
  final String? isoDate;

  const ExpiryDateScanConfirmationResult({
    required this.action,
    this.isoDate,
  });
}

class _ExpiryScanConfirmationSheet extends StatefulWidget {
  final String? title;
  final String? helpText;
  final List<ExpiryScanCandidate> candidates;
  final String initialDate;

  const _ExpiryScanConfirmationSheet({
    this.title,
    this.helpText,
    required this.candidates,
    required this.initialDate,
  });

  @override
  State<_ExpiryScanConfirmationSheet> createState() =>
      _ExpiryScanConfirmationSheetState();
}

class _ExpiryScanConfirmationSheetState
    extends State<_ExpiryScanConfirmationSheet> {
  late final TextEditingController _dateController;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: widget.initialDate);
  }

  Future<void> _pickDateFromCalendar() async {
    final String? pickedDate = await _pickDateManually(
      context,
      initialDate: DateTime.tryParse(_dateController.text),
      helpText: widget.helpText,
    );
    if (!mounted || pickedDate == null) {
      return;
    }
    setState(() {
      _dateController.text = pickedDate;
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title ?? 'Confirm expiry date',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.helpText ?? 'Check the scanned date before applying it.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.candidates
                  .map(
                    (candidate) => ActionChip(
                      label: Text(
                          '${candidate.isoDate} · ${candidate.scoreLabel}'),
                      onPressed: () {
                        Navigator.of(context).pop(
                          ExpiryDateScanConfirmationResult(
                            action: ExpiryScanConfirmationAction.confirm,
                            isoDate: candidate.isoDate,
                          ),
                        );
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _dateController,
              readOnly: true,
              onTap: _pickDateFromCalendar,
              decoration: InputDecoration(
                labelText: 'Selected expiry date',
                prefixIcon: const Icon(Icons.calendar_today),
                suffixIcon: IconButton(
                  tooltip: 'Pick manually',
                  onPressed: _pickDateFromCalendar,
                  icon: const Icon(Icons.edit_calendar_outlined),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(
                      const ExpiryDateScanConfirmationResult(
                        action: ExpiryScanConfirmationAction.retry,
                      ),
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(
                      ExpiryDateScanConfirmationResult(
                        action: ExpiryScanConfirmationAction.confirm,
                        isoDate: _dateController.text,
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Confirm'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(
                const ExpiryDateScanConfirmationResult(
                  action: ExpiryScanConfirmationAction.cancel,
                ),
              ),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
