import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:inoventory_ui/expiry_scan/controllers/expiry_scan_controller.dart';
import 'package:inoventory_ui/expiry_scan/models/expiry_scan_candidate.dart';
import 'package:inoventory_ui/shared/widgets/container_with_box_decoration.dart';
import 'package:intl/intl.dart';

class ExpiryDateEntry extends StatefulWidget {
  final String label;
  final String? initialDate;
  final String? pendingScannedDate;
  final void Function(String? date)? onDateSet;
  final VoidCallback? onScanRequested;
  final void Function(ExpiryScanCandidate candidate)? onSuggestionSelected;
  final VoidCallback? onDismissSuggestions;
  final VoidCallback? onConfirmPendingDate;
  final VoidCallback? onRetryScan;
  final bool isScanSupported;
  final bool isScanning;
  final bool isTargeted;
  final String? applyToAllHint;
  final ExpiryScanStatus status;
  final List<ExpiryScanCandidate> suggestions;

  const ExpiryDateEntry({
    super.key,
    this.label = 'Expiry Date (Optional)',
    this.initialDate,
    this.pendingScannedDate,
    this.onDateSet,
    this.onScanRequested,
    this.onSuggestionSelected,
    this.onDismissSuggestions,
    this.onConfirmPendingDate,
    this.onRetryScan,
    this.isScanSupported = false,
    this.isScanning = false,
    this.isTargeted = false,
    this.applyToAllHint,
    this.status = ExpiryScanStatus.idle,
    this.suggestions = const <ExpiryScanCandidate>[],
  });

  @override
  State<ExpiryDateEntry> createState() => _ExpiryDateEntryState();
}

class _ExpiryDateEntryState extends State<ExpiryDateEntry> {
  late final TextEditingController _dateInput;

  @override
  void initState() {
    super.initState();
    _dateInput = TextEditingController(text: widget.initialDate ?? '');
  }

  @override
  void didUpdateWidget(covariant ExpiryDateEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String nextValue =
        widget.pendingScannedDate ?? widget.initialDate ?? '';
    if (nextValue != _dateInput.text) {
      _dateInput.text = nextValue;
    }
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = DateTime.tryParse(_dateInput.text) ?? now;
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate == null) {
      developer.log('Date is not selected');
      return;
    }

    final String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
    widget.onDateSet?.call(formattedDate);
    setState(() {
      _dateInput.text = formattedDate;
    });
  }

  Color _borderColor(BuildContext context) {
    switch (widget.status) {
      case ExpiryScanStatus.success:
        return Colors.green;
      case ExpiryScanStatus.warning:
        return Colors.amber;
      case ExpiryScanStatus.scanning:
      case ExpiryScanStatus.textDetected:
        return Theme.of(context).colorScheme.primary;
      case ExpiryScanStatus.idle:
        return Theme.of(context).dividerColor;
    }
  }

  Color _backgroundColor(BuildContext context) {
    switch (widget.status) {
      case ExpiryScanStatus.success:
        return Colors.green.withValues(alpha: 0.08);
      case ExpiryScanStatus.warning:
        return Colors.amber.withValues(alpha: 0.1);
      case ExpiryScanStatus.scanning:
      case ExpiryScanStatus.textDetected:
        return Theme.of(context).colorScheme.primary.withValues(alpha: 0.05);
      case ExpiryScanStatus.idle:
        return Theme.of(context).colorScheme.surface;
    }
  }

  @override
  void dispose() {
    _dateInput.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasDate = _dateInput.text.isNotEmpty;
    final bool hasPendingDate = widget.pendingScannedDate != null &&
        widget.pendingScannedDate!.isNotEmpty;

    return ContainerWithBoxDecoration(
      boxColor: Colors.transparent,
      externalPadding: 5,
      internalPadding: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _backgroundColor(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _borderColor(context),
            width: widget.isTargeted ? 2.2 : 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _dateInput,
              readOnly: true,
              onTap: _pickDate,
              decoration: InputDecoration(
                icon: const Icon(Icons.calendar_today),
                labelText: widget.label,
                helperText: widget.isScanning
                    ? 'Point the camera at the printed expiry date'
                    : widget.applyToAllHint,
                suffixIconConstraints: const BoxConstraints(minWidth: 112),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.isScanSupported)
                      IconButton(
                        tooltip: 'Scan Expiry',
                        onPressed: widget.onScanRequested,
                        icon: Icon(
                          widget.isScanning
                              ? Icons.center_focus_strong
                              : Icons.document_scanner_outlined,
                          color: widget.isScanning
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                    if (hasDate)
                      IconButton(
                        onPressed: () {
                          if (hasPendingDate) {
                            widget.onDismissSuggestions?.call();
                          } else {
                            widget.onDateSet?.call(null);
                          }
                          setState(() {
                            _dateInput.text = '';
                          });
                        },
                        icon: const Icon(Icons.clear_outlined),
                      ),
                  ],
                ),
              ),
            ),
            if (hasPendingDate) ...[
              const SizedBox(height: 10),
              Text(
                'Review the captured expiry date before applying it.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            if (widget.suggestions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final ExpiryScanCandidate candidate
                      in widget.suggestions)
                    ActionChip(
                      label: Text(
                          '${candidate.isoDate} · ${candidate.scoreLabel}'),
                      onPressed: () =>
                          widget.onSuggestionSelected?.call(candidate),
                    ),
                  ActionChip(
                    label: const Text('Dismiss'),
                    onPressed: widget.onDismissSuggestions,
                  ),
                ],
              ),
            ],
            if (hasPendingDate) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: widget.onRetryScan ?? widget.onScanRequested,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry Capture'),
                  ),
                  FilledButton.icon(
                    onPressed: widget.onConfirmPendingDate,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Confirm Date'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
