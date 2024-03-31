import 'dart:convert';
import 'dart:typed_data';

import 'package:eurocup_frontend/src/qr_scanner/scanner_error_widget.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../model/athlete/athlete.dart';
import '../widgets.dart';

class BarCodeScannerController extends StatefulWidget {
  const BarCodeScannerController({Key? key}) : super(key: key);
  static const routeName = '/barcode_scanner';

  @override
  State<BarCodeScannerController> createState() =>
      _BarCodeScannerControllerState();
}

class _BarCodeScannerControllerState extends State<BarCodeScannerController> {
  Athlete? findAthleteById(List<Athlete> list, int searchId) {
    var athlete = list.firstWhere((athlete) => athlete.id == searchId);
    return athlete;
  }

  BarcodeCapture? barcode;
  final MobileScannerController controller = MobileScannerController(
    // torchEnabled: true,
    formats: [BarcodeFormat.qrCode],
    facing: CameraFacing.back,
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 1000,
    // returnImage: false,
  );
  bool isStarted = true;
  void _startOrStop() {
    try {
      if (isStarted) {
        controller.stop();
      } else {
        controller.start();
      }
      setState(() {
        isStarted = !isStarted;
      });
    } on Exception catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something went wrong! $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    List<int> listAthleteIds = args['listIds'];
    List<Athlete> listAthlete = args['list'];

    return Scaffold(
      // appBar: AppBar(title: const Text('QR Scanner')),
      appBar: appBarWithAction(() {
        _startOrStop;
      }, title: '', icon: isStarted ? Icons.stop : Icons.play_arrow),
      body: MobileScanner(
        fit: BoxFit.contain,
        controller: controller,
        errorBuilder: (context, error, child) {
          return ScannerErrorWidget(error: error);
        },
        onDetect: (capture) {
          setState(() {
            // barcode = capture;
          final List<Barcode> barcodes = capture.barcodes;
          final Uint8List? image = capture.image;
          final barcode = barcodes.first;
          print(barcode.rawValue.toString());
          final qrcode = jsonDecode(barcode.rawValue.toString());
          final id = qrcode['id'];
          print(id);
          Athlete? athlete = findAthleteById(listAthlete, id);
          // if (listAthleteIds.contains(id)) {
          if (athlete != null) {
            print('OK');
            // showInfoDialog(context, 'PASSED', '', () {
            //   Navigator.pop(context, true);
            // });
            // Navigator.pop(context, true);
          } else {
            print('FAILED');
            // showInfoDialog(context, 'FAILED', 'NOT IN THIS CREW!', () {
            //   Navigator.pop(context, true);
            // });
            // Navigator.pop(context, false);
          }
          });
        },
      ),
    );
  }
}
