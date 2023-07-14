import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:eurocup_frontend/src/model/club_details.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';

class ClubDetailView extends StatefulWidget {
  const ClubDetailView({super.key});

  static const routeName = '/club_detail';

  @override
  State<ClubDetailView> createState() => _ClubDetailViewState();
}

class _ClubDetailViewState extends State<ClubDetailView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    int clubId = args['clubId'];
    String title = args['title'];

    return Scaffold(
      appBar: appBar(
        title: title,
      ),
      body: Container(
        decoration: bckDecoration(),
        child: FutureBuilder<ClubDetails>(
          future: api.getClubDetails(clubId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasData) {
              final details = snapshot.data!;
              return Container(
                child: ListView(
                  children: [
                    ListTile(
                      title: Text('Total: ${details.total}',
                          style: Theme.of(context).textTheme.displayLarge,
                          textAlign: TextAlign.left),
                    ),
                    ListTile(
                      title: Text('Eurocup: ${details.eurocup}',
                          style: Theme.of(context).textTheme.displayLarge,
                          textAlign: TextAlign.left),
                    ),
                    ListTile(
                      title: Text('Festival: ${details.festival}',
                          style: Theme.of(context).textTheme.displayLarge,
                          textAlign: TextAlign.left),
                    ),
                    ListTile(
                      title: Text('Junior: ${details.junior}',
                          style: Theme.of(context).textTheme.displayLarge,
                          textAlign: TextAlign.left),
                    ),
                    ListTile(
                      title: Text('U24: ${details.u24}',
                          style: Theme.of(context).textTheme.displayLarge,
                          textAlign: TextAlign.left),
                    ),
                    ListTile(
                      title: Text('Premier: ${details.premier}',
                          style: Theme.of(context).textTheme.displayLarge,
                          textAlign: TextAlign.left),
                    ),
                    ListTile(
                      title: Text('Senior A: ${details.seniorA}',
                          style: Theme.of(context).textTheme.displayLarge,
                          textAlign: TextAlign.left),
                    ),
                    ListTile(
                      title: Text('Senior B: ${details.seniorB}',
                          style: Theme.of(context).textTheme.displayLarge,
                          textAlign: TextAlign.left),
                    ),
                    ListTile(
                      title: Text('Senior C: ${details.seniorC}',
                          style: Theme.of(context).textTheme.displayLarge,
                          textAlign: TextAlign.left),
                    ),
                    ListTile(
                      title: Text('Senior D: ${details.seniorD}',
                          style: Theme.of(context).textTheme.displayLarge,
                          textAlign: TextAlign.left),
                    ),
                    ListTile(
                      title: Text('BCP: ${details.bcp}',
                          style: Theme.of(context).textTheme.displayLarge,
                          textAlign: TextAlign.left),
                    ),
                    ListTile(
                      title: Text('with AD certificate: ${details.withCertificate}',
                          style: Theme.of(context).textTheme.displayLarge,
                          textAlign: TextAlign.left),
                    ),
                  ],
                ),
              );
            } else {
              return (const Text('No data'));
            }
          },
        ),
      ),
    );
  }
}
