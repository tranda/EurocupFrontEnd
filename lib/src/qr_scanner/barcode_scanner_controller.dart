import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../model/athlete/athlete.dart';

class BarCodeScannerController extends StatefulWidget {
  const BarCodeScannerController({super.key});
  static const routeName = '/barcode_scanner';

  @override
  State<BarCodeScannerController> createState() => _BarCodeScannerControllerState();
}

class _BarCodeScannerControllerState extends State<BarCodeScannerController> {
  Athlete? findAthleteById(List<Athlete> list, int searchId) {
    try {
      return list.firstWhere((athlete) => athlete.id == searchId);
    } catch (e) {
      return null;
    }
  }

  final MobileScannerController controller = MobileScannerController(
    formats: [BarcodeFormat.qrCode],
    facing: CameraFacing.back,
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 1000,
  );

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    List<Athlete> listAthlete = args['list'];

    return Scaffold(
      appBar: AppBar(title: const Text('QR Scanner')),
      body: MobileScanner(
        fit: BoxFit.contain,
        controller: controller,
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          final barcode = barcodes.first;
          print(barcode.rawValue.toString());
          try {
            final qrcode = jsonDecode(barcode.rawValue.toString());
            final id = qrcode['id'];
            print(id);
            Athlete? athlete = findAthleteById(listAthlete, id);
            if (athlete != null) {
              print('OK');
              Navigator.pop(context, {'success': true, 'athlete': athlete});
            } else {
              print('FAILED');
              Navigator.pop(context, {'success': false, 'message': 'Athlete not found'});
            }
          } catch (e) {
            print('Error processing QR code: $e');
            Navigator.pop(context, {'success': false, 'message': 'Invalid QR code'});
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
