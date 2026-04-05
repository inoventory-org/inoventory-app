import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerWidget extends StatefulWidget {
  final dynamic Function(BarcodeCapture barcodeCapture) onDetect;

  const BarcodeScannerWidget({
    Key? key,
    required this.onDetect,
  }) : super(key: key);

  @override
  State<BarcodeScannerWidget> createState() => _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends State<BarcodeScannerWidget> {
  late MobileScannerController _controller;
  DetectionSpeed _detectionSpeed = DetectionSpeed.normal;
  bool _isChangingController = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _controller = MobileScannerController(
      detectionSpeed: _detectionSpeed,
      autoStart: true,
    );
  }

  Future<void> _reinitializeController() async {
    if (!mounted) return;
    setState(() {
      _isChangingController = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));
    await _controller.dispose();

    _initController();

    if (!mounted) return;
    setState(() {
      _isChangingController = false;
    });

    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    unawaited(_controller.start());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildError(BuildContext context, MobileScannerException error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.white, size: 40),
          const SizedBox(height: 16),
          Text(
            error.errorDetails?.message ?? error.errorCode.name,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _onDetectionSpeedChanged(DetectionSpeed? speed) {
    if (speed != null && speed != _detectionSpeed) {
      _detectionSpeed = speed;
      _reinitializeController();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWidgetTest = WidgetsBinding.instance.runtimeType.toString() ==
        'AutomatedTestWidgetsFlutterBinding';

    if (isWidgetTest) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: SizedBox.expand(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mobile Scanner'),
        actions: [
          PopupMenuButton<DetectionSpeed>(
            tooltip: 'Detection Speed',
            icon: const Icon(Icons.speed),
            onSelected: _onDetectionSpeedChanged,
            itemBuilder: (context) => [
              CheckedPopupMenuItem(
                value: DetectionSpeed.normal,
                checked: _detectionSpeed == DetectionSpeed.normal,
                child: const Text('Normal (Timeout)'),
              ),
              CheckedPopupMenuItem(
                value: DetectionSpeed.noDuplicates,
                checked: _detectionSpeed == DetectionSpeed.noDuplicates,
                child: const Text('No Duplicates'),
              ),
              CheckedPopupMenuItem(
                value: DetectionSpeed.unrestricted,
                checked: _detectionSpeed == DetectionSpeed.unrestricted,
                child: const Text('Unrestricted'),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: _isChangingController
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : LayoutBuilder(
              builder: (context, constraints) {
                final smallerDimension =
                    constraints.maxWidth < constraints.maxHeight
                        ? constraints.maxWidth
                        : constraints.maxHeight;
                final scanWindowSize = smallerDimension * 0.7;
                // Ensure we don't offset the center too much if the height is small
                final yOffset = (constraints.maxHeight > 200) ? 40.0 : 0.0;
                final scanWindow = Rect.fromCenter(
                  center: Offset(constraints.maxWidth / 2,
                      constraints.maxHeight / 2 - yOffset),
                  width: scanWindowSize,
                  height: scanWindowSize * 0.8,
                );

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(
                      controller: _controller,
                      scanWindow: scanWindow,
                      errorBuilder: _buildError,
                      onDetect: widget.onDetect,
                      fit: BoxFit.contain,
                    ),
                    IgnorePointer(
                      child: BarcodeOverlay(
                        controller: _controller,
                        boxFit: BoxFit.contain,
                      ),
                    ),
                    IgnorePointer(
                      child: ScanWindowOverlay(
                        scanWindow: scanWindow,
                        controller: _controller,
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        color: const Color.fromRGBO(0, 0, 0, 0.6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ZoomSlider(controller: _controller),
                            const SizedBox(height: 8.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _FlashlightButton(controller: _controller),
                                _StartStopButton(controller: _controller),
                                _SwitchCameraButton(controller: _controller),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _ZoomSlider extends StatelessWidget {
  final MobileScannerController controller;

  const _ZoomSlider({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MobileScannerState>(
      valueListenable: controller,
      builder: (context, state, child) {
        if (!state.isInitialized || !state.isRunning) {
          return const SizedBox.shrink();
        }

        final TextStyle labelStyle = Theme.of(context)
            .textTheme
            .bodyMedium!
            .copyWith(color: Colors.white);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            children: [
              Text('0%', style: labelStyle),
              Expanded(
                child: Slider(
                  value: state.zoomScale,
                  min: 0.0,
                  max: 1.0,
                  activeColor: Colors.blueAccent,
                  inactiveColor: Colors.white54,
                  onChanged: (value) {
                    controller.setZoomScale(value);
                  },
                ),
              ),
              Text('100%', style: labelStyle),
            ],
          ),
        );
      },
    );
  }
}

class _FlashlightButton extends StatelessWidget {
  final MobileScannerController controller;

  const _FlashlightButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MobileScannerState>(
      valueListenable: controller,
      builder: (context, state, child) {
        if (!state.isInitialized || !state.isRunning) {
          return const IconButton(
            color: Colors.white,
            icon: Icon(Icons.flash_off),
            onPressed: null,
          );
        }

        switch (state.torchState) {
          case TorchState.auto:
            return IconButton(
              color: Colors.white,
              icon: const Icon(Icons.flash_auto),
              iconSize: 32.0,
              onPressed: () => controller.toggleTorch(),
            );
          case TorchState.off:
            return IconButton(
              color: Colors.white,
              icon: const Icon(Icons.flash_off),
              iconSize: 32.0,
              onPressed: () => controller.toggleTorch(),
            );
          case TorchState.on:
            return IconButton(
              color: Colors.yellow,
              icon: const Icon(Icons.flash_on),
              iconSize: 32.0,
              onPressed: () => controller.toggleTorch(),
            );
          case TorchState.unavailable:
            return const IconButton(
              color: Colors.grey,
              icon: Icon(Icons.flash_off),
              iconSize: 32.0,
              onPressed: null,
            );
        }
      },
    );
  }
}

class _SwitchCameraButton extends StatelessWidget {
  final MobileScannerController controller;

  const _SwitchCameraButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MobileScannerState>(
      valueListenable: controller,
      builder: (context, state, child) {
        if (!state.isInitialized || !state.isRunning) {
          return const IconButton(
            color: Colors.white,
            icon: Icon(Icons.cameraswitch),
            onPressed: null,
          );
        }

        return IconButton(
          color: Colors.white,
          icon: const Icon(Icons.cameraswitch),
          iconSize: 32.0,
          onPressed: () => controller.switchCamera(),
        );
      },
    );
  }
}

class _StartStopButton extends StatelessWidget {
  final MobileScannerController controller;

  const _StartStopButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MobileScannerState>(
      valueListenable: controller,
      builder: (context, state, child) {
        if (!state.isInitialized || !state.isRunning) {
          return IconButton(
            color: Colors.white,
            icon: const Icon(Icons.play_arrow),
            iconSize: 32.0,
            onPressed: () => controller.start(),
          );
        }

        return IconButton(
          color: Colors.white,
          icon: const Icon(Icons.stop),
          iconSize: 32.0,
          onPressed: () => controller.stop(),
        );
      },
    );
  }
}
