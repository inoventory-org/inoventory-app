import 'package:inoventory_ui/expiry_scan/models/expiry_scan_candidate.dart';

class ExpiryScanDetection {
  final bool detectedTextInTarget;
  final bool requiresConfirmation;
  final List<ExpiryScanCandidate> candidates;

  const ExpiryScanDetection({
    this.detectedTextInTarget = false,
    this.requiresConfirmation = false,
    this.candidates = const <ExpiryScanCandidate>[],
  });

  ExpiryScanCandidate? get bestCandidate =>
      candidates.isEmpty ? null : candidates.first;
}
