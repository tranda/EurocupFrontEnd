import 'dart:convert';

import 'package:eurocup_frontend/src/model/race/crew.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../athletes/athlete_detail_view.dart';
import '../model/athlete/athlete.dart';

import 'package:collection/collection.dart';

import '../qr_scanner/barcode_scanner_controller.dart';

class RaceCrewDetailView extends StatefulWidget {
  const RaceCrewDetailView({super.key});
  static const routeName = '/race_crew_detail';

  @override
  State<RaceCrewDetailView> createState() => _RaceCrewDetailViewState();
}

class _RaceCrewDetailViewState extends State<RaceCrewDetailView> {
  late Crew crew;

  // Removed unused variables related to old barcode scanning

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
    List<int> listAthleteIds = [];
    List<Athlete> listAthlete = [];
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
          // Debug: QR scan result
          if (value != null && value.toString().isNotEmpty) {
            checkForPresence(value.toString(), listAthlete);
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
                listAthleteIds = listAthlete.map((e) => e.id as int).toList();
                // Debug: athlete IDs list
                // Debug: check mix validation
                // Debug: crew athletes data
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

  bool checkForPresence(String? code, List<Athlete> listAthlete) {
    var result = false;
    if (code != null && code.isNotEmpty) {
      // Debug: QR code content
      final qrcode = jsonDecode(code);
      final id = qrcode['id'];
      // Debug: athlete ID from QR code
      Athlete? athlete = findAthleteById(listAthlete, id);
      if (athlete != null) {
        result = true;
        // Debug: athlete validation passed
        showInfoDialog(context, 'PASSED', '', () {});
      } else {
        // Debug: athlete validation failed
        showInfoDialog(context, 'NOT IN THIS CREW!', '', () {});
      }
    }
    return (result);
  }

  Athlete? findAthleteById(List<Athlete> list, int searchId) {
    return list.firstWhereOrNull((athlete) => athlete.id == searchId);
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
