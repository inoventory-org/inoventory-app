import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:inoventory_ui/expiry_scan/controllers/expiry_scan_controller.dart';
import 'package:inoventory_ui/expiry_scan/expiry_date_picker.dart';
import 'package:inoventory_ui/expiry_scan/expiry_date_parser.dart';
import 'package:inoventory_ui/expiry_scan/models/expiry_scan_candidate.dart';
import 'package:inoventory_ui/expiry_scan/widgets/expiry_scan_camera_pane.dart';

class ExpiryDateScanRoute extends StatefulWidget {
  final String? title;
  final String? helpText;
  final DateTime? initialDate;
  final ExpiryDateConfirmationMode confirmationMode;

  const ExpiryDateScanRoute({
    super.key,
    this.title,
    this.helpText,
    this.initialDate,
    this.confirmationMode = ExpiryDateConfirmationMode.autoApply,
  });

  @override
  State<ExpiryDateScanRoute> createState() => _ExpiryDateScanRouteState();
}

class _ExpiryDateScanRouteState extends State<ExpiryDateScanRoute> {
  final ExpiryScanController _controller = ExpiryScanController();
  final ExpiryDateParser _parser = ExpiryDateParser();
  int _lastEventId = 0;
  List<ExpiryScanCandidate> _candidates = const <ExpiryScanCandidate>[];
  late final TextEditingController _selectedDateController;

  @override
  void initState() {
    super.initState();
    _selectedDateController = TextEditingController(
      text: widget.initialDate != null
          ? DateFormat('yyyy-MM-dd').format(widget.initialDate!)
          : '',
    );
    _controller.addListener(_handleScanUpdates);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.startScanning(targetRowIndex: 0);
    });
  }

  void _handleScanUpdates() {
    if (!mounted) {
      return;
    }

    final int eventId = _controller.eventId;
    if (eventId == _lastEventId) {
      setState(() {});
      return;
    }
    _lastEventId = eventId;

    final detection = _controller.latestDetection;
    if (detection.candidates.isEmpty) {
      setState(() {
        _candidates = const <ExpiryScanCandidate>[];
      });
      return;
    }

    if (detection.requiresConfirmation) {
      setState(() {
        _candidates = detection.candidates;
      });
      return;
    }

    final ExpiryScanCandidate? candidate = detection.bestCandidate;
    if (candidate == null) {
      return;
    }
    _setSelectedDate(candidate.isoDate);
    if (widget.confirmationMode == ExpiryDateConfirmationMode.autoApply) {
      HapticFeedback.lightImpact();
      Navigator.of(context).pop(candidate.isoDate);
      return;
    }
    setState(() {
      _candidates = detection.candidates;
    });
  }

  Future<void> _pickDateManually() async {
    final DateTime initialDate =
        DateTime.tryParse(_selectedDateController.text) ??
            widget.initialDate ??
            DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: widget.helpText,
    );
    if (!mounted || pickedDate == null) {
      return;
    }
    final String isoDate = DateFormat('yyyy-MM-dd').format(pickedDate);
    _setSelectedDate(isoDate);
    if (widget.confirmationMode == ExpiryDateConfirmationMode.autoApply) {
      Navigator.of(context).pop(isoDate);
    }
  }

  void _setSelectedDate(String isoDate) {
    setState(() {
      _selectedDateController.text = isoDate;
    });
  }

  void _confirmSelectedDate() {
    if (_selectedDateController.text.isEmpty) {
      return;
    }
    Navigator.of(context).pop(_selectedDateController.text);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleScanUpdates);
    _controller.dispose();
    _selectedDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Scan Expiry Date'),
        actions: [
          TextButton(
            onPressed: _pickDateManually,
            child: const Text('Pick Manually'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: ExpiryScanCameraPane(
              controller: _controller,
              parser: _parser,
            ),
          ),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.helpText ??
                        'Scan the printed expiry date on the package.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  if (_candidates.isNotEmpty) ...[
                    Text(
                      widget.confirmationMode ==
                              ExpiryDateConfirmationMode.requireConfirmation
                          ? 'Review the detected date'
                          : 'Choose the detected date',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _candidates
                          .map(
                            (candidate) => ActionChip(
                              label: Text(
                                  '${candidate.isoDate} · ${candidate.scoreLabel}'),
                              onPressed: () {
                                _setSelectedDate(candidate.isoDate);
                                if (widget.confirmationMode ==
                                    ExpiryDateConfirmationMode.autoApply) {
                                  Navigator.of(context).pop(candidate.isoDate);
                                }
                              },
                            ),
                          )
                          .toList(),
                    ),
                    if (widget.confirmationMode ==
                        ExpiryDateConfirmationMode.requireConfirmation) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _selectedDateController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Selected expiry date',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: _pickDateManually,
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: _confirmSelectedDate,
                        child: const Text('Confirm expiry date'),
                      ),
                    ],
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No valid date yet. Tap to focus or move slightly back and zoom in.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
