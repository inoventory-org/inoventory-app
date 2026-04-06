import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:inoventory_ui/expiry_scan/controllers/expiry_scan_controller.dart';
import 'package:inoventory_ui/expiry_scan/expiry_date_parser.dart';
import 'package:inoventory_ui/expiry_scan/models/expiry_scan_text_block.dart';

class ExpiryScanCameraPane extends StatefulWidget {
  final ExpiryScanController controller;
  final ExpiryDateParser parser;

  const ExpiryScanCameraPane({
    super.key,
    required this.controller,
    required this.parser,
  });

  @override
  State<ExpiryScanCameraPane> createState() => _ExpiryScanCameraPaneState();
}

class _ExpiryScanCameraPaneState extends State<ExpiryScanCameraPane> {
  static const Rect _targetBox = Rect.fromLTWH(0.16, 0.2, 0.68, 0.44);

  CameraController? _cameraController;
  late final TextRecognizer _textRecognizer;
  bool _isInitializing = true;
  bool _isProcessingFrame = false;
  double _minZoomLevel = 1;
  double _maxZoomLevel = 1;
  double _zoomLevel = 1;
  Offset? _focusIndicatorPosition;
  DateTime _lastAnalyzedAt = DateTime.fromMillisecondsSinceEpoch(0);

  double get _usableMinZoomLevel =>
      _minZoomLevel < 1.0 && _maxZoomLevel >= 1.0 ? 1.0 : _minZoomLevel;

  @override
  void initState() {
    super.initState();
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    unawaited(_initializeCamera());
  }

  Future<void> _initializeCamera() async {
    if (kIsWeb) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isInitializing = false;
      });
      return;
    }

    try {
      final List<CameraDescription> cameras = await availableCameras();
      final CameraDescription camera = _pickPreferredCamera(cameras);

      final CameraController controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.iOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.nv21,
      );

      await controller.initialize();
      await controller.setFocusMode(FocusMode.auto);
      if (controller.value.focusPointSupported) {
        await controller.setFocusPoint(const Offset(0.5, 0.5));
      }
      _minZoomLevel = await controller.getMinZoomLevel();
      _maxZoomLevel = await controller.getMaxZoomLevel();
      _zoomLevel = _usableMinZoomLevel;
      await controller.setZoomLevel(_zoomLevel);
      await controller.startImageStream(_processCameraImage);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _isInitializing = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isInitializing = false;
      });
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (!widget.controller.isScanning ||
        widget.controller.awaitingConfirmation) {
      return;
    }
    if (_isProcessingFrame) {
      return;
    }
    final DateTime now = DateTime.now();
    if (now.difference(_lastAnalyzedAt).inMilliseconds < 350) {
      return;
    }
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    _isProcessingFrame = true;
    _lastAnalyzedAt = now;

    try {
      final InputImage? inputImage = _toInputImage(cameraController, image);
      if (inputImage == null) {
        return;
      }

      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);
      final List<ExpiryScanTextBlock> blocks = recognizedText.blocks
          .map(
            (block) => ExpiryScanTextBlock(
              text: block.text,
              boundingBox: Rect.fromLTWH(
                block.boundingBox.left / image.width,
                block.boundingBox.top / image.height,
                block.boundingBox.width / image.width,
                block.boundingBox.height / image.height,
              ),
            ),
          )
          .toList();

      final detection = widget.parser.parse(
        blocks: blocks,
        targetBox: _targetBox,
      );
      widget.controller.updateTextPresence(detection.detectedTextInTarget);
      if (detection.bestCandidate != null) {
        widget.controller.publishDetection(detection);
      }
    } catch (_) {
      // Keep scanning; OCR failures should not break the camera session.
    } finally {
      _isProcessingFrame = false;
    }
  }

  InputImage? _toInputImage(
    CameraController controller,
    CameraImage image,
  ) {
    final InputImageFormat? inputImageFormat =
        InputImageFormatValue.fromRawValue(image.format.raw);
    if (inputImageFormat == null) {
      return null;
    }

    final Uint8List bytes = _concatenatePlanes(image.planes);
    final Size imageSize =
        Size(image.width.toDouble(), image.height.toDouble());
    final int rotation = controller.description.sensorOrientation;
    final InputImageRotation? imageRotation =
        InputImageRotationValue.fromRawValue(rotation);
    if (imageRotation == null) {
      return null;
    }

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  Color _targetBorderColor(BuildContext context) {
    switch (widget.controller.status) {
      case ExpiryScanStatus.success:
        return Colors.greenAccent;
      case ExpiryScanStatus.warning:
        return Colors.amberAccent;
      case ExpiryScanStatus.textDetected:
        return Colors.green;
      case ExpiryScanStatus.scanning:
        return Theme.of(context).colorScheme.primary;
      case ExpiryScanStatus.idle:
        return Colors.white70;
    }
  }

  Future<void> _setZoomLevel(double nextZoomLevel) async {
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    final double clampedZoomLevel =
        nextZoomLevel.clamp(_usableMinZoomLevel, _maxZoomLevel);
    await cameraController.setZoomLevel(clampedZoomLevel);

    if (!mounted) {
      return;
    }
    setState(() {
      _zoomLevel = clampedZoomLevel;
    });
  }

  CameraDescription _pickPreferredCamera(List<CameraDescription> cameras) {
    final List<CameraDescription> backCameras = cameras
        .where((camera) => camera.lensDirection == CameraLensDirection.back)
        .toList();
    if (backCameras.isEmpty) {
      return cameras.first;
    }

    int score(CameraDescription camera) {
      final String name = camera.name.toLowerCase();
      int value = 0;
      if (name.contains('wide') || name.contains('ultra')) {
        value += 10;
      }
      if (name.contains('macro')) {
        value += 4;
      }
      if (name.contains('back')) {
        value -= 1;
      }
      return value;
    }

    backCameras.sort((a, b) => score(a).compareTo(score(b)));
    return backCameras.first;
  }

  Future<void> _handleTapToFocus(
    TapDownDetails details,
    BoxConstraints constraints,
  ) async {
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    if (!cameraController.value.focusPointSupported) {
      return;
    }

    final Offset localPosition = details.localPosition;
    final Offset normalizedPoint = Offset(
      (localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0),
      (localPosition.dy / constraints.maxHeight).clamp(0.0, 1.0),
    );

    await cameraController.setFocusMode(FocusMode.auto);
    await cameraController.setFocusPoint(normalizedPoint);
    await HapticFeedback.selectionClick();

    if (!mounted) {
      return;
    }
    setState(() {
      _focusIndicatorPosition = localPosition;
    });

    Future<void>.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _focusIndicatorPosition = null;
      });
    });
  }

  @override
  void dispose() {
    final CameraController? cameraController = _cameraController;
    if (cameraController != null) {
      unawaited(cameraController.dispose());
    }
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: Text(
            'Unable to start expiry scanner',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) => _handleTapToFocus(details, constraints),
              child: ColoredBox(
                color: Colors.black,
                child: CameraPreview(cameraController),
              ),
            ),
            IgnorePointer(
              child: CustomPaint(
                painter: _ExpiryTargetOverlayPainter(
                  targetBox: _targetBox,
                  borderColor: _targetBorderColor(context),
                ),
              ),
            ),
            if (_focusIndicatorPosition != null)
              Positioned(
                left: _focusIndicatorPosition!.dx - 22,
                top: _focusIndicatorPosition!.dy - 22,
                child: IgnorePointer(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.9),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            Positioned(
              right: 10,
              bottom: 12,
              child: _maxZoomLevel > _usableMinZoomLevel
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 88,
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 2,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 12,
                                  ),
                                ),
                                child: Slider(
                                  value: _zoomLevel,
                                  min: _usableMinZoomLevel,
                                  max: _maxZoomLevel,
                                  divisions:
                                      ((_maxZoomLevel - _usableMinZoomLevel) *
                                              2)
                                          .round()
                                          .clamp(1, 20),
                                  onChanged: _setZoomLevel,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${_zoomLevel.toStringAsFixed(1)}x',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }
}

class _ExpiryTargetOverlayPainter extends CustomPainter {
  final Rect targetBox;
  final Color borderColor;

  const _ExpiryTargetOverlayPainter({
    required this.targetBox,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect scaledRect = Rect.fromLTWH(
      targetBox.left * size.width,
      targetBox.top * size.height,
      targetBox.width * size.width,
      targetBox.height * size.height,
    );

    final Paint scrimPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.45);
    final Path fullPath = Path()..addRect(Offset.zero & size);
    final Path cutoutPath = Path()
      ..addRRect(
          RRect.fromRectAndRadius(scaledRect, const Radius.circular(18)));
    canvas.drawPath(
      Path.combine(PathOperation.difference, fullPath, cutoutPath),
      scrimPaint,
    );

    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(scaledRect, const Radius.circular(18)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ExpiryTargetOverlayPainter oldDelegate) {
    return oldDelegate.targetBox != targetBox ||
        oldDelegate.borderColor != borderColor;
  }
}
