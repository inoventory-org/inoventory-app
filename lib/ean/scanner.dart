import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerWidget extends StatelessWidget {
  dynamic Function(BarcodeCapture barcodeCapture) onDetect;

  BarcodeScannerWidget({Key? key, required this.onDetect}) : super(key: key);

  MobileScannerController cameraController = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Mobile Scanner'),
          actions: [
            IconButton(
              color: Colors.white,
              icon: ValueListenableBuilder<MobileScannerState>(
                valueListenable: cameraController,
                builder: (context, state, child) {
                  switch (state.torchState) {
                    case TorchState.off:
                    case TorchState.unavailable:
                      return const Icon(Icons.flash_off, color: Colors.grey);
                    case TorchState.on:
                    case TorchState.auto:
                      return const Icon(Icons.flash_on, color: Colors.yellow);
                  }
                },
              ),
              iconSize: 32.0,
              onPressed: () => cameraController.toggleTorch(),
            ),
            IconButton(
              color: Colors.white,
              icon: ValueListenableBuilder<MobileScannerState>(
                valueListenable: cameraController,
                builder: (context, state, child) {
                  switch (state.cameraDirection) {
                    case CameraFacing.front:
                      return const Icon(Icons.camera_front);
                    case CameraFacing.back:
                    default:
                      return const Icon(Icons.camera_rear);
                  }
                },
              ),
              iconSize: 32.0,
              onPressed: () => cameraController.switchCamera(),
            ),
          ],
        ),
        body: MobileScanner(
            controller: cameraController,
            onDetect: onDetect,

        ));
  }
}
