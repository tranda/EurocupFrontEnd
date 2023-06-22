import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarCodeScannerController extends StatelessWidget {
  const BarCodeScannerController({Key? key}) : super(key: key);
  static const routeName = '/barcode_scanner';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Scanner')),
      body: MobileScanner(
        fit: BoxFit.contain,
        controller: MobileScannerController(
            detectionSpeed: DetectionSpeed.normal,
            facing: CameraFacing.back,
            torchEnabled: false,
            formats: [BarcodeFormat.qrCode]),
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          final Uint8List? image = capture.image;
          for (final barcode in barcodes) {
            debugPrint('QR Code found! ${barcode.rawValue}');
          }
        },
      ),
    );
  }
}
