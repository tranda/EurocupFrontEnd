import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';


class BarCodeScannerController extends StatefulWidget {
  const BarCodeScannerController({super.key});
  static const routeName = '/barcode_scanner';

  @override
  State<BarCodeScannerController> createState() => _BarCodeScannerControllerState();
}

class _BarCodeScannerControllerState extends State<BarCodeScannerController> {
  late MobileScannerController controller;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Scanner'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller.cameraFacingState,
              builder: (context, state, child) {
                return const Icon(Icons.flip_camera_ios);
              },
            ),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Column(
              children: [
                Expanded(
                  flex: 4,
                  child: MobileScanner(
                    key: ValueKey(controller.hashCode),
                    controller: controller,
                    onDetect: (capture) {
                      _onBarcodeDetect(capture);
                    },
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isProcessing)
                          const CircularProgressIndicator()
                        else
                          const Text(
                            'Scan athlete QR code',
                            style: TextStyle(fontSize: 16),
                          ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isProcessing = false;
                            });
                          },
                          child: const Text('Scan Again'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// Returns the raw QR text to the caller ({'qr': value}).
  /// The backend checks the signature, so nothing is verified here.
  void _onBarcodeDetect(BarcodeCapture capture) {
    if (isProcessing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final qrValue = barcodes.first.rawValue ?? '';
    setState(() {
      isProcessing = true;
    });

    if (!qrValue.startsWith('EVT2.')) {
      _showResultAndResume(passed: false, message: 'INVALID QR CODE');
      return;
    }
    Navigator.pop(context, {'qr': qrValue});
  }

  void _showResultAndResume({required bool passed, required String message}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              passed ? Icons.check_circle : Icons.cancel,
              color: passed ? Colors.green : Colors.red,
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: passed ? Colors.green.shade700 : Colors.red.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  isProcessing = false;
                });
              },
              child: const Text('OK', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}