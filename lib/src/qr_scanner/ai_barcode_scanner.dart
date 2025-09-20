import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../model/athlete/athlete.dart';

/// Barcode scanner widget
class AiBarcodeScanner extends StatefulWidget {
  static const routeName = '/ai_barcode_scanner';

  /// Function that gets Called when barcode is scanned successfully
  ///
  final void Function(String)? onScan;

  /// Function that gets called when a Barcode is detected.
  ///
  /// [barcode] The barcode object with all information about the scanned code.
  /// [args] Information about the state of the MobileScanner widget
  final void Function(BarcodeCapture)? onDetect;

  /// Validate barcode text with a function
  final bool Function(String value)? validator;

  /// Fit to screen
  final BoxFit fit;

  /// Barcode controller (optional)
  final MobileScannerController? controller;

  /// Show overlay or not (default: true)
  final bool showOverlay;

  /// Overlay border color (default: white)
  final Color borderColor;

  /// Overlay border width (default: 10)
  final double borderWidth;

  /// Overlay color
  final Color overlayColor;

  /// Overlay border radius (default: 10)
  final double borderRadius;

  /// Overlay border length (default: 30)
  final double borderLength;

  /// Overlay cut out width (optional)
  final double? cutOutWidth;

  /// Overlay cut out height (optional)
  final double? cutOutHeight;

  /// Overlay cut out offset (default: 0)
  final double cutOutBottomOffset;

  /// Overlay cut out size (default: 300)
  final double cutOutSize;

  /// Hint widget (optional) (default: Text('Scan QR Code'))
  /// Hint widget will be replaced the bottom of the screen.
  /// If you want to replace the bottom screen widget, use [bottomBar]
  final Widget? bottomBar;

  /// Hint text (default: 'Scan QR Code')
  final String bottomBarText;

  /// Hint text style
  final TextStyle bottomBarTextStyle;

  /// Show error or not (default: true)
  final bool showError;

  /// Error color (default: red)
  final Color errorColor;

  /// Show success or not (default: true)
  final bool showSuccess;

  /// Success color (default: green)
  final Color successColor;

  /// A toggle to enable or disable haptic feedback upon scan (default: true)
  final bool hapticFeedback;

  /// Can auto back to previous page when barcode is successfully scanned (default: true)
  final bool canPop;

  /// The function that builds an error widget when the scanner
  /// could not be started.
  ///
  /// If this is null, defaults to a black [ColoredBox]
  /// with a centered white [Icons.error] icon.
  final Widget Function(BuildContext, MobileScannerException, Widget?)?
      errorBuilder;

  /// The function that builds a placeholder widget when the scanner
  /// is not yet displaying its camera preview.
  ///
  /// If this is null, a black [ColoredBox] is used as placeholder.
  final Widget Function(BuildContext, Widget?)? placeholderBuilder;

  /// The function that signals when the barcode scanner is started.
  final void Function(MobileScannerArguments?)? onScannerStarted;

  /// Called when this object is removed from the tree permanently.
  final void Function()? onDispose;

  /// if set barcodes will only be scanned if they fall within this [Rect]
  /// useful for having a cut-out overlay for example. these [Rect]
  /// coordinates are relative to the widget size, so by how much your
  /// rectangle overlays the actual image can depend on things like the
  /// [BoxFit]
  final Rect? scanWindow;

  /// Only set this to true if you are starting another instance of mobile_scanner
  /// right after disposing the first one, like in a PageView.
  ///
  /// Default: false
  final bool? startDelay;

  /// Appbar widget
  /// you can use this to add appbar to the scanner screen
  ///
  final PreferredSizeWidget? appBar;

  const AiBarcodeScanner({
    super.key,
    this.onScan,
    this.validator,
    this.fit = BoxFit.cover,
    this.controller,
    this.onDetect,
    this.borderColor = Colors.white,
    this.borderWidth = 10,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 10,
    this.borderLength = 40,
    this.cutOutSize = 300,
    this.cutOutWidth,
    this.cutOutHeight,
    this.cutOutBottomOffset = 0,
    this.bottomBarText = 'Scan QR Code',
    this.bottomBarTextStyle = const TextStyle(fontWeight: FontWeight.bold),
    this.showOverlay = true,
    this.showError = true,
    this.errorColor = Colors.red,
    this.showSuccess = true,
    this.successColor = Colors.green,
    this.hapticFeedback = true,
    this.canPop = true,
    this.errorBuilder,
    this.placeholderBuilder,
    this.onScannerStarted,
    this.onDispose,
    this.scanWindow,
    this.startDelay,
    this.bottomBar,
    this.appBar,
  });

  @override
  State<AiBarcodeScanner> createState() => _AiBarcodeScannerState();
}

class _AiBarcodeScannerState extends State<AiBarcodeScanner> {
  /// bool to check if barcode is valid or not
  bool? _isSuccess;
  bool isDetected = false;
  bool isProcessing = false;

  /// Scanner controller
  late MobileScannerController controller;

  /// Find athlete by ID in the provided list
  Athlete? findAthleteById(List<Athlete> list, int searchId) {
    try {
      return list.firstWhere((athlete) => athlete.id == searchId);
    } catch (e) {
      return null;
    }
  }

  @override
  void initState() {
    controller = widget.controller ?? MobileScannerController();
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();

    /// calls onDispose function if it is not null
    if (widget.onDispose != null) {
      widget.onDispose!.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          bottomNavigationBar: orientation == Orientation.portrait
              ? widget.bottomBar ??
                  ListTile(
                    leading: Builder(
                      builder: (context) {
                        return IconButton(
                          tooltip: "Switch Camera",
                          onPressed: () =>
                              controller.switchCamera(),
                          icon: ValueListenableBuilder<CameraFacing>(
                            valueListenable: controller.cameraFacingState,
                            builder: (context, state, child) {
                              switch (state) {
                                case CameraFacing.front:
                                  return const Icon(Icons.camera_front);
                                case CameraFacing.back:
                                  return const Icon(Icons.camera_rear);
                              }
                            },
                          ),
                        );
                      },
                    ),
                    title: Text(
                      widget.bottomBarText,
                      textAlign: TextAlign.center,
                      style: widget.bottomBarTextStyle,
                    ),
                    trailing: Builder(
                      builder: (context) {
                        return IconButton(
                          tooltip: "Torch",
                          onPressed: () => controller.toggleTorch(),
                          icon: ValueListenableBuilder<TorchState>(
                            valueListenable: controller.torchState,
                            builder: (context, state, child) {
                              switch (state) {
                                case TorchState.off:
                                  return const Icon(Icons.flash_off);
                                case TorchState.on:
                                  return const Icon(Icons.flash_on);
                              }
                            },
                          ),
                        );
                      },
                    ),
                  )
              : null,
          appBar: widget.appBar,
          body: Stack(
            children: [
              MobileScanner(
                controller: controller,
                fit: widget.fit,
                errorBuilder: widget.errorBuilder,
                onScannerStarted: widget.onScannerStarted,
                placeholderBuilder: widget.placeholderBuilder,
                scanWindow: widget.scanWindow,
                startDelay: widget.startDelay ?? false,
                key: widget.key,
                onDetect: (BarcodeCapture barcode) async {
              if (isDetected || isProcessing) return;

              setState(() {
                isDetected = true;
                isProcessing = true;
              });

              widget.onDetect?.call(barcode);

              if (barcode.barcodes.isEmpty) {
                // Debug: Scanned Code is Empty
                _showErrorAndResume('No barcode detected');
                return;
              }

              final String code = barcode.barcodes.first.rawValue ?? "";
              // Debug: QR Code detected

              // Get athlete list from route arguments if available
              final routeSettings = ModalRoute.of(context)?.settings;
              final args = routeSettings?.arguments;
              List<Athlete> listAthlete = [];

              if (args != null && args is Map && args.containsKey('list')) {
                final athleteList = args['list'];
                if (athleteList is List<Athlete>) {
                  listAthlete = athleteList;
                }
              }

              // If we have athlete list, validate against it
              if (listAthlete.isNotEmpty) {
                try {
                  final qrcode = jsonDecode(code);
                  final id = qrcode['id'];
                  // Debug: Athlete ID extracted

                  Athlete? athlete = findAthleteById(listAthlete, id);
                  if (athlete != null) {
                    // Debug: Athlete found
                    setState(() {
                      _isSuccess = true;
                      if (widget.hapticFeedback) HapticFeedback.lightImpact();
                    });

                    if (widget.canPop && mounted && Navigator.canPop(context)) {
                      Navigator.of(context).pop({'success': true, 'athlete': athlete});
                    }
                    return;
                  } else {
                    // Debug: Athlete not found
                    _showErrorAndResume('Athlete not found');
                    return;
                  }
                } catch (e) {
                  // Debug: Error processing QR code
                  _showErrorAndResume('Invalid QR code format');
                  return;
                }
              }

              // Fallback: use validator if provided
              if (widget.validator != null && !widget.validator!(code)) {
                setState(() {
                  if (widget.hapticFeedback) HapticFeedback.heavyImpact();
                  // Debug: Invalid Barcode
                  _isSuccess = false;
                });
                _showErrorAndResume('Invalid QR code');
                return;
              }

              setState(() {
                _isSuccess = true;
                if (widget.hapticFeedback) HapticFeedback.lightImpact();
                // Debug: Barcode rawValue
                widget.onScan?.call(code);
              });

              if (widget.canPop && mounted && Navigator.canPop(context)) {
                Navigator.of(context).pop(code);
                return;
              }
            },
          ),
          // Add overlay for scanning feedback
          if (widget.showOverlay)
            _buildScannerOverlay(),
        ],
          ),
        );
      },
    );
  }

  void _showErrorAndResume(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: widget.errorColor,
        duration: const Duration(seconds: 2),
      ),
    );

    // Resume scanning after error
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          isDetected = false;
          isProcessing = false;
          _isSuccess = null;
        });
      }
    });
  }

  Widget _buildScannerOverlay() {
    return Container(
      decoration: ShapeDecoration(
        shape: QrScannerOverlayShape(
          borderColor: _isSuccess == null
              ? widget.borderColor
              : _isSuccess!
                  ? widget.successColor
                  : widget.errorColor,
          borderRadius: widget.borderRadius,
          borderLength: widget.borderLength,
          borderWidth: widget.borderWidth,
          cutOutSize: widget.cutOutSize,
          cutOutWidth: widget.cutOutWidth,
          cutOutHeight: widget.cutOutHeight,
          cutOutBottomOffset: widget.cutOutBottomOffset,
          overlayColor: widget.overlayColor,
        ),
      ),
    );
  }
}

class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double? cutOutWidth;
  final double? cutOutHeight;
  final double cutOutBottomOffset;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutWidth,
    this.cutOutHeight,
    this.cutOutBottomOffset = 0,
    this.cutOutSize = 300,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path path = Path()..addRect(rect);

    double width = cutOutWidth ?? cutOutSize;
    double height = cutOutHeight ?? cutOutSize;

    double left = rect.center.dx - width / 2;
    double top = rect.center.dy - height / 2 + cutOutBottomOffset;

    final cutOutRect = Rect.fromLTWH(left, top, width, height);

    path = Path.combine(
      PathOperation.difference,
      path,
      Path()
        ..addRRect(
          RRect.fromRectAndCorners(
            cutOutRect,
            topLeft: Radius.circular(borderRadius),
            topRight: Radius.circular(borderRadius),
            bottomLeft: Radius.circular(borderRadius),
            bottomRight: Radius.circular(borderRadius),
          ),
        ),
    );

    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final Paint paint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(getOuterPath(rect), paint);

    double width = cutOutWidth ?? cutOutSize;
    double height = cutOutHeight ?? cutOutSize;

    double left = rect.center.dx - width / 2;
    double top = rect.center.dy - height / 2 + cutOutBottomOffset;

    final cutOutRect = Rect.fromLTWH(left, top, width, height);

    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // Draw corner borders
    final double cornerLength = borderLength;

    // Top left corner
    canvas.drawLine(
      Offset(cutOutRect.left, cutOutRect.top + cornerLength),
      Offset(cutOutRect.left, cutOutRect.top + borderRadius),
      borderPaint,
    );
    canvas.drawLine(
      Offset(cutOutRect.left + borderRadius, cutOutRect.top),
      Offset(cutOutRect.left + cornerLength, cutOutRect.top),
      borderPaint,
    );

    // Top right corner
    canvas.drawLine(
      Offset(cutOutRect.right - cornerLength, cutOutRect.top),
      Offset(cutOutRect.right - borderRadius, cutOutRect.top),
      borderPaint,
    );
    canvas.drawLine(
      Offset(cutOutRect.right, cutOutRect.top + borderRadius),
      Offset(cutOutRect.right, cutOutRect.top + cornerLength),
      borderPaint,
    );

    // Bottom left corner
    canvas.drawLine(
      Offset(cutOutRect.left, cutOutRect.bottom - cornerLength),
      Offset(cutOutRect.left, cutOutRect.bottom - borderRadius),
      borderPaint,
    );
    canvas.drawLine(
      Offset(cutOutRect.left + borderRadius, cutOutRect.bottom),
      Offset(cutOutRect.left + cornerLength, cutOutRect.bottom),
      borderPaint,
    );

    // Bottom right corner
    canvas.drawLine(
      Offset(cutOutRect.right - cornerLength, cutOutRect.bottom),
      Offset(cutOutRect.right - borderRadius, cutOutRect.bottom),
      borderPaint,
    );
    canvas.drawLine(
      Offset(cutOutRect.right, cutOutRect.bottom - borderRadius),
      Offset(cutOutRect.right, cutOutRect.bottom - cornerLength),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
