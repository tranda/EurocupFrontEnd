import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import '../model/athlete/athlete.dart';

class BarCodeScannerController extends StatefulWidget {
  const BarCodeScannerController({super.key});
  static const routeName = '/barcode_scanner';

  @override
  State<BarCodeScannerController> createState() => _BarCodeScannerControllerState();
}

class _BarCodeScannerControllerState extends State<BarCodeScannerController> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
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
          if (controller != null)
            IconButton(
              icon: const Icon(Icons.flash_on),
              onPressed: () async {
                await controller?.toggleFlash();
              },
            ),
          if (controller != null)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios),
              onPressed: () async {
                await controller?.flipCamera();
              },
            ),
        ],
      ),
      body: listAthlete.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No athletes available for scanning. Please go back and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  flex: 4,
                  child: QRView(
                    key: qrKey,
                    onQRViewCreated: _onQRViewCreated,
                    overlay: QrScannerOverlayShape(
                      borderColor: Colors.red,
                      borderRadius: 10,
                      borderLength: 30,
                      borderWidth: 10,
                      cutOutSize: 300,
                    ),
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
                          onPressed: () async {
                            await controller?.resumeCamera();
                            setState(() {
                              isProcessing = false;
                            });
                          },
                          child: const Text('Resume Camera'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });

    // Safely extract route arguments
    final routeSettings = ModalRoute.of(context)?.settings;
    final args = routeSettings?.arguments;

    List<Athlete> listAthlete = [];
    if (args != null && args is Map && args.containsKey('list')) {
      final athleteList = args['list'];
      if (athleteList is List<Athlete>) {
        listAthlete = athleteList;
      }
    }

    controller.scannedDataStream.listen((scanData) {
      if (!isProcessing) {
        setState(() {
          isProcessing = true;
        });

        controller.pauseCamera();

        final qrValue = scanData.code;
        print('QR Code detected: $qrValue');

        try {
          final qrcode = jsonDecode(qrValue ?? '');
          final id = qrcode['id'];
          print('Athlete ID: $id');

          Athlete? athlete = findAthleteById(listAthlete, id);
          if (athlete != null) {
            print('Athlete found: ${athlete.getDisplayName()}');
            Navigator.pop(context, {'success': true, 'athlete': athlete});
          } else {
            print('Athlete not found');
            _showErrorAndResume('Athlete not found');
          }
        } catch (e) {
          print('Error processing QR code: $e');
          _showErrorAndResume('Invalid QR code format');
        }
      }
    });
  }

  void _showErrorAndResume(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );

    // Resume scanning after error
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        controller?.resumeCamera();
        setState(() {
          isProcessing = false;
        });
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      controller!.pauseCamera();
      controller!.resumeCamera();
    }
  }
}
