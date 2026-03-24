import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScanRoute extends StatefulWidget {
  const BarcodeScanRoute({super.key});

  @override
  State<BarcodeScanRoute> createState() => _BarcodeScanRouteState();
}

class _BarcodeScanRouteState extends State<BarcodeScanRoute> {
  final MobileScannerController _cameraController =
      MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  bool _hasPopped = false;

  void _onDetect(BarcodeCapture barcodeCapture) {
    if (_hasPopped) {
      return;
    }
    final barcodes = barcodeCapture.barcodes;
    if (barcodes.isEmpty) {
      return;
    }
    final code = barcodes.first.rawValue ?? "";
    if (code.isEmpty) {
      return;
    }
    _hasPopped = true;
    Navigator.of(context).pop(code);
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan barcode'),
      ),
      body: MobileScanner(
        controller: _cameraController,
        onDetect: _onDetect,
      ),
    );
  }
}
