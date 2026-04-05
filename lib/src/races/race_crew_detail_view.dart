import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/model/race/crew.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;

import '../athletes/athlete_detail_view.dart';
import '../athletes/image_widget_web.dart' if (dart.library.io) 'package:flutter/material.dart';
import '../model/athlete/athlete.dart';

import '../qr_scanner/barcode_scanner_controller.dart';

class RaceCrewDetailView extends StatefulWidget {
  const RaceCrewDetailView({super.key});
  static const routeName = '/race_crew_detail';

  @override
  State<RaceCrewDetailView> createState() => _RaceCrewDetailViewState();
}

class _RaceCrewDetailViewState extends State<RaceCrewDetailView> {
  late Crew crew;
  List<Athlete> listAthlete = [];

  @override
  void initState() {
    super.initState();
  }

  bool checkMix(
      Map<int, Map<String, dynamic>> crewAthletes, int size, int helmNo) {
    int countMale = 0;
    int countFemale = 0;
    crewAthletes.forEach((key, value) {
      var athlete = crewAthletes[key]!['athlete']! as Athlete;
      if (key != 0 && key < helmNo - 1) {
        if (athlete.gender == "Male") {
          countMale += 1;
        } else {
          countFemale += 1;
        }
      }
    });
    // Debug: male #: $countMale, female #: $countFemale
    return true;
  }

  // Removed old scanQR method - now using BarCodeScannerController

  // Removed old _scan method - now using BarCodeScannerController

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    int size = args['size'];
    int crewId = args['crewId'];
    int helmNo = args['helmNo'];
    String title = args['title'];

    return Scaffold(
      appBar: appBarWithAction(() {
        Navigator.pushNamed(
          context,
          BarCodeScannerController.routeName,
          arguments: {'list': listAthlete},
        ).then((value) async {
          if (value != null && value is Map && value['success'] == true) {
            final athlete = value['athlete'] as Athlete;
            final isInCrew = listAthlete.any((a) => a.id == athlete.id);
            final photoUrl = athlete.photo != null && athlete.photo!.isNotEmpty
                ? "https://$imagePrefix/${athlete.photo}"
                : "";
            _showScanResult(
              context,
              passed: isInCrew,
              athleteName: '${athlete.firstName} ${athlete.lastName}',
              photoUrl: photoUrl,
            );
          }
        });
      }, title: title, icon: Icons.qr_code_scanner),
      body: Container(
        decoration: bckDecoration(),
        child: FutureBuilder(
          future: api.getCrewAthletesForCrew(crewId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasData) {
                var crewAthletes = snapshot.data!;
                listAthlete = crewAthletes.values
                    .map<Athlete>((innerMap) => innerMap['athlete'] as Athlete)
                    .toList();
                // Debug: check mix validation
                return ListView.builder(
                  itemCount: size,
                  itemBuilder: (context, index) {
                    var no = index + 1;
                    var drummerPrefix = no == 1 ? "(drummer)" : "";
                    var helmPrefix = no == helmNo ? "(helm)" : "";
                    var reservePrefix = no > helmNo ? "(reserve)" : "";
                    if (crewAthletes.containsKey(index)) {
                      final athlete =
                          crewAthletes[index]!['athlete']! as Athlete;
                      return Column(
                        children: [
                          ListTile(
                            title: Text(
                                "$no $drummerPrefix$helmPrefix$reservePrefix ${(crewAthletes[index]!['athlete']! as Athlete).getDisplayDetail()}",
                                style:
                                    Theme.of(context).textTheme.displaySmall),
                            subtitle: Padding(
                              padding: const EdgeInsetsDirectional.symmetric(
                                  horizontal: (8.0), vertical: 8.0),
                              child: Text(athlete.category ?? ""),
                            ),
                            onTap: () {
                              Navigator.pushNamed(
                                  context, AthleteDetailView.routeName,
                                  arguments: {
                                    'mode': 'r',
                                    'allowEdit': false,
                                    'athlete': athlete
                                  }).then((value) {
                                setState(() {});
                              });
                            },
                          ),
                          const Divider(
                            height: 4,
                          )
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          ListTile(
                            title: Text(
                                "$no $drummerPrefix$helmPrefix$reservePrefix",
                                style:
                                    Theme.of(context).textTheme.displaySmall),
                          ),
                          const Divider(
                            height: 4,
                          )
                        ],
                      );
                    }
                  },
                );
              }
            }
            return (const Text('No data'));
          },
        ),
      ),
    );
  }

  void _showScanResult(BuildContext context, {required bool passed, required String athleteName, String photoUrl = ''}) {
    final statusColor = passed ? Colors.green : Colors.red;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: passed ? Colors.green.shade50 : Colors.red.shade50,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (photoUrl.isNotEmpty)
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb
                        ? WebImage(imageUrl: photoUrl, width: 200, height: 200)
                        : Image.network(photoUrl, width: 200, height: 200, fit: BoxFit.cover),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      passed ? Icons.check : Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            if (photoUrl.isEmpty)
              Icon(
                passed ? Icons.check_circle : Icons.cancel,
                color: statusColor,
                size: 100,
              ),
            const SizedBox(height: 16),
            Text(
              athleteName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              passed ? 'PASSED' : 'NOT IN THIS CREW',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: statusColor.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> openDialog() async {
    return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              content: null,
              title: Text(
                "Save Your changes?",
                style: Theme.of(context).textTheme.displaySmall,
              ),
              actions: <Widget>[
                TextButton(onPressed: () {}, child: const Text("OK")),
              ],
            ));
  }
}
