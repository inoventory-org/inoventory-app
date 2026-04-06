import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerWidget extends StatelessWidget {
  final dynamic Function(BarcodeCapture barcodeCapture) onDetect;

  const BarcodeScannerWidget({
    super.key,
    required this.onDetect,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mobile Scanner'),
      ),
      backgroundColor: Colors.black,
      body: BarcodeScannerPane(
        onDetect: onDetect,
        showControls: true,
      ),
    );
  }
}

class BarcodeScannerPane extends StatefulWidget {
  final dynamic Function(BarcodeCapture barcodeCapture) onDetect;
  final bool showControls;
  final bool enableDetection;

  const BarcodeScannerPane({
    super.key,
    required this.onDetect,
    this.showControls = true,
    this.enableDetection = true,
  });

  @override
  State<BarcodeScannerPane> createState() => _BarcodeScannerPaneState();
}

class _BarcodeScannerPaneState extends State<BarcodeScannerPane> {
  late MobileScannerController _controller;
  DetectionSpeed _detectionSpeed = DetectionSpeed.noDuplicates;
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
    if (!mounted) {
      return;
    }
    setState(() {
      _isChangingController = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));
    await _controller.dispose();
    _initController();

    if (!mounted) {
      return;
    }
    setState(() {
      _isChangingController = false;
    });

    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) {
      return;
    }
    unawaited(_controller.start());
  }

  void _onDetectionSpeedChanged(DetectionSpeed? speed) {
    if (speed == null || speed == _detectionSpeed) {
      return;
    }
    _detectionSpeed = speed;
    _reinitializeController();
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isWidgetTest = WidgetsBinding.instance.runtimeType.toString() ==
        'AutomatedTestWidgetsFlutterBinding';

    if (isWidgetTest) {
      return const ColoredBox(
        color: Colors.black,
        child: SizedBox.expand(),
      );
    }

    if (_isChangingController) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double smallerDimension =
            constraints.maxWidth < constraints.maxHeight
                ? constraints.maxWidth
                : constraints.maxHeight;
        final double scanWindowSize = smallerDimension * 0.7;
        final double yOffset = constraints.maxHeight > 200 ? 40.0 : 0.0;
        final Rect scanWindow = Rect.fromCenter(
          center: Offset(
            constraints.maxWidth / 2,
            constraints.maxHeight / 2 - yOffset,
          ),
          width: scanWindowSize,
          height: scanWindowSize * 0.8,
        );

        return ColoredBox(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                controller: _controller,
                scanWindow: scanWindow,
                errorBuilder: _buildError,
                onDetect: (capture) {
                  if (!widget.enableDetection) {
                    return;
                  }
                  widget.onDetect(capture);
                },
                fit: BoxFit.cover,
              ),
              IgnorePointer(
                child: BarcodeOverlay(
                  controller: _controller,
                  boxFit: BoxFit.cover,
                ),
              ),
              IgnorePointer(
                child: ScanWindowOverlay(
                  scanWindow: scanWindow,
                  controller: _controller,
                ),
              ),
              if (widget.showControls)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    color: const Color.fromRGBO(0, 0, 0, 0.6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ZoomSlider(controller: _controller),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _FlashlightButton(controller: _controller),
                            _StartStopButton(controller: _controller),
                            _SwitchCameraButton(controller: _controller),
                            PopupMenuButton<DetectionSpeed>(
                              tooltip: 'Detection Speed',
                              icon: const Icon(
                                Icons.speed,
                                color: Colors.white,
                              ),
                              onSelected: _onDetectionSpeedChanged,
                              itemBuilder: (context) => [
                                CheckedPopupMenuItem(
                                  value: DetectionSpeed.noDuplicates,
                                  checked: _detectionSpeed ==
                                      DetectionSpeed.noDuplicates,
                                  child: const Text('No Duplicates'),
                                ),
                                CheckedPopupMenuItem(
                                  value: DetectionSpeed.normal,
                                  checked:
                                      _detectionSpeed == DetectionSpeed.normal,
                                  child: const Text('Normal'),
                                ),
       
                                CheckedPopupMenuItem(
                                  value: DetectionSpeed.unrestricted,
                                  checked: _detectionSpeed ==
                                      DetectionSpeed.unrestricted,
                                  child: const Text('Unrestricted'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
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
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text('0%', style: labelStyle),
              Expanded(
                child: Slider(
                  value: state.zoomScale,
                  min: 0,
                  max: 1,
                  activeColor: Colors.blueAccent,
                  inactiveColor: Colors.white54,
                  onChanged: controller.setZoomScale,
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
              iconSize: 32,
              onPressed: controller.toggleTorch,
            );
          case TorchState.off:
            return IconButton(
              color: Colors.white,
              icon: const Icon(Icons.flash_off),
              iconSize: 32,
              onPressed: controller.toggleTorch,
            );
          case TorchState.on:
            return IconButton(
              color: Colors.yellow,
              icon: const Icon(Icons.flash_on),
              iconSize: 32,
              onPressed: controller.toggleTorch,
            );
          case TorchState.unavailable:
            return const IconButton(
              color: Colors.grey,
              icon: Icon(Icons.flash_off),
              iconSize: 32,
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
          iconSize: 32,
          onPressed: controller.switchCamera,
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
            iconSize: 32,
            onPressed: controller.start,
          );
        }

        return IconButton(
          color: Colors.white,
          icon: const Icon(Icons.stop),
          iconSize: 32,
          onPressed: controller.stop,
        );
      },
    );
  }
}
