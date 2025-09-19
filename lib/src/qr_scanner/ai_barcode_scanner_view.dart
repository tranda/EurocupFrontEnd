import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:flutter/material.dart';



class AIBarCodeScanner extends StatefulWidget {
  const AIBarCodeScanner({super.key});
  //  static const routeName = '/ai_barcode_scanner';

  @override
  State<AIBarCodeScanner> createState() => _AIBarCodeScannerState();
}

class _AIBarCodeScannerState extends State<AIBarCodeScanner> {
  String barcode = 'Tap  to scan';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(' Scanner'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              child: const Text('Scan Barcode'),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AiBarcodeScanner(
                      // validator: (value) {
                      //   return value.startsWith('https://');
                      // },
                      canPop: true,
                      onScan: (String value) {
                        debugPrint(value);
                        setState(() {
                          barcode = value;
                        });
                      },
                      onDetect: (p0) {},
                      onDispose: () {
                        debugPrint("Barcode scanner disposed!");
                      },
                      controller: MobileScannerController(
                        detectionSpeed: DetectionSpeed.noDuplicates,
                      ),
                    ),
                  ),
                );
              },
            ),
            Text(barcode),
          ],
        ),
      ),
    );
  }
}
