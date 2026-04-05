import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../model/athlete/athlete.dart';
import 'qr_code_util.dart';

class BarCodeScannerController extends StatefulWidget {
  const BarCodeScannerController({super.key});
  static const routeName = '/barcode_scanner';

  @override
  State<BarCodeScannerController> createState() => _BarCodeScannerControllerState();
}

class _BarCodeScannerControllerState extends State<BarCodeScannerController> {
  MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
  );
  bool isProcessing = false;

  Athlete? findAthleteById(List<Athlete> list, int searchId) {
    try {
      return list.firstWhere((athlete) => athlete.id == searchId);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safely extract route arguments with null safety
    final routeSettings = ModalRoute.of(context)?.settings;
    final args = routeSettings?.arguments;

    // Handle null or invalid arguments
    List<Athlete> listAthlete = [];
    if (args != null && args is Map && args.containsKey('list')) {
      final athleteList = args['list'];
      if (athleteList is List<Athlete>) {
        listAthlete = athleteList;
      }
    }

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
                    controller: controller,
                    onDetect: (capture) {
                      _onBarcodeDetect(capture, listAthlete);
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

  void _onBarcodeDetect(BarcodeCapture capture, List<Athlete> listAthlete) {
    if (!isProcessing) {
      final List<Barcode> barcodes = capture.barcodes;
      if (barcodes.isNotEmpty) {
        setState(() {
          isProcessing = true;
        });

        final qrValue = barcodes.first.rawValue ?? '';
        final athleteId = QrCodeUtil.verify(qrValue);

        if (athleteId == null) {
          _showErrorAndResume('Invalid or tampered QR code');
          return;
        }

        Athlete? athlete = findAthleteById(listAthlete, athleteId);
        if (athlete != null) {
          Navigator.pop(context, {'success': true, 'athlete': athlete});
        } else {
          _showErrorAndResume('Athlete not found in crew');
        }
      }
    }
  }

  void _showErrorAndResume(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );

    // Resume scanning after delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}