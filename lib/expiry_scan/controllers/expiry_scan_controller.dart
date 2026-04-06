import 'package:flutter/foundation.dart';
import 'package:inoventory_ui/expiry_scan/models/expiry_scan_detection.dart';

enum ExpiryScanStatus { idle, scanning, textDetected, success, warning }

class ExpiryScanController extends ChangeNotifier {
  bool _isScanning = false;
  bool _awaitingConfirmation = false;
  int? _targetRowIndex;
  int _eventId = 0;
  ExpiryScanStatus _status = ExpiryScanStatus.idle;
  ExpiryScanDetection _latestDetection = const ExpiryScanDetection();

  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool get isScanning => _isScanning;
  bool get awaitingConfirmation => _awaitingConfirmation;
  bool get isActive => _isScanning || _awaitingConfirmation;
  int? get targetRowIndex => _targetRowIndex;
  int get eventId => _eventId;
  ExpiryScanStatus get status => _status;
  ExpiryScanDetection get latestDetection => _latestDetection;

  void startScanning({required int targetRowIndex}) {
    if (!isSupported) {
      return;
    }
    _targetRowIndex = targetRowIndex;
    _isScanning = true;
    _awaitingConfirmation = false;
    _status = ExpiryScanStatus.scanning;
    _latestDetection = const ExpiryScanDetection();
    notifyListeners();
  }

  void stopScanning({bool resetDetection = true}) {
    _isScanning = false;
    _awaitingConfirmation = false;
    _targetRowIndex = null;
    _status = ExpiryScanStatus.idle;
    if (resetDetection) {
      _latestDetection = const ExpiryScanDetection();
    }
    notifyListeners();
  }

  void updateTextPresence(bool detectedTextInTarget) {
    if (!_isScanning || _awaitingConfirmation) {
      return;
    }
    final ExpiryScanStatus nextStatus = detectedTextInTarget
        ? ExpiryScanStatus.textDetected
        : ExpiryScanStatus.scanning;
    if (_status == nextStatus) {
      return;
    }
    _status = nextStatus;
    notifyListeners();
  }

  void publishDetection(ExpiryScanDetection detection) {
    if (!_isScanning) {
      return;
    }
    _latestDetection = detection;
    _eventId++;
    if (detection.requiresConfirmation) {
      _isScanning = false;
      _awaitingConfirmation = true;
      _status = ExpiryScanStatus.warning;
    } else if (detection.bestCandidate != null) {
      _isScanning = false;
      _awaitingConfirmation = true;
      _status = ExpiryScanStatus.success;
    } else {
      _status = detection.detectedTextInTarget
          ? ExpiryScanStatus.textDetected
          : ExpiryScanStatus.scanning;
    }
    notifyListeners();
  }

  void markSuccess() {
    _isScanning = false;
    _awaitingConfirmation = false;
    _status = ExpiryScanStatus.success;
    notifyListeners();
  }

  void cancelSuggestions() {
    _awaitingConfirmation = false;
    _targetRowIndex = null;
    _status = ExpiryScanStatus.idle;
    _latestDetection = const ExpiryScanDetection();
    notifyListeners();
  }
}
