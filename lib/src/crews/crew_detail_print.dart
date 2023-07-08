import 'dart:typed_data';

import 'package:eurocup_frontend/src/crews/athlete_picker_view.dart';
import 'package:eurocup_frontend/src/model/race/crew.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;

import '../clubs/club_details_view.dart';
import '../model/athlete/athlete.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CrewDetailPrint extends StatelessWidget {
  const CrewDetailPrint({Key? key}) : super(key: key);
  static const routeName = '/crew_detail_print';
  // final String title;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('title')),
        body: PdfPreview(
          build: (format) => _generatePdf(format, 'title'),
        ),
      ),
    );
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format, String title) async {
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final font = await PdfGoogleFonts.nunitoExtraLight();

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (context) {
          return pw.Column(
            children: [
              pw.SizedBox(
                width: double.infinity,
                child: pw.FittedBox(
                  child: pw.Text(title, style: pw.TextStyle(font: font)),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Flexible(child: pw.FlutterLogo())
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}

class CrewDetailPrint2 extends StatefulWidget {
  const CrewDetailPrint2({Key? key}) : super(key: key);
  static const routeName = '/crew_detail_print';

  @override
  State<CrewDetailPrint2> createState() => _CrewDetailPrint2State();
}

class _CrewDetailPrint2State extends State<CrewDetailPrint2> {
  late Crew crew;

  @override
  void initState() {
    // TODO: implement initState
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
    print('male #: $countMale, female #: $countFemale');
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Map<int, Athlete> crewAthletes;
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    int size = args['size'];
    int crewId = args['crewId'];
    int helmNo = args['helmNo'];
    String title = args['title'];

    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);

    return Scaffold(
      // appBar: appBar(title: title),
      appBar: appBarWithAction(
        () {
          Navigator.pushNamed(context, ClubDetailView.routeName,
              arguments: {'clubId': 1, 'title': title});
        },
        title: title,
        icon: Icons.print,
      ),
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
                checkMix(crewAthletes, size, helmNo);
                // print (crewAthletes);
                return ListView.builder(
                  itemCount: size,
                  itemBuilder: (context, index) {
                    var no = index + 1;
                    var drummerPrefix = no == 1 ? "(drummer)" : "";
                    var helmPrefix = no == helmNo ? "(helm)" : "";
                    var reservePrefix = no > helmNo ? "(reserve)" : "";
                    if (crewAthletes.containsKey(index)) {
                      return Column(
                        children: [
                          ListTile(
                            title: Text(
                                "$no $drummerPrefix$helmPrefix$reservePrefix ${(crewAthletes[index]!['athlete']! as Athlete).getDisplayName()}",
                                style:
                                    Theme.of(context).textTheme.displaySmall),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                api
                                    .deleteCrewAthlete(
                                        crewAthletes[index]!['id'])
                                    .then((value) {
                                  setState(() {});
                                });
                              },
                            ),
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
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                  AthletePickerView.routeName,
                                  arguments: {
                                    'crewId': crewId,
                                    'no': index
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
}
