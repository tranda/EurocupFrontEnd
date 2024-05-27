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
                      title: Text(
                          'with AD certificate: ${details.withCertificate}',
                          style: Theme.of(context).textTheme.displayLarge,
                          textAlign: TextAlign.left),
                    ),
                    const Divider(
                      height: 4,
                    ),
                    ListTile(
                      title: Text('Eurocup: ${details.eurocup}',
                          style: Theme.of(context).textTheme.displayLarge,
                          textAlign: TextAlign.left),
                    ),
                    ListTile(
                      title: Text(
                          'Festival: ${details.pfestival! - details.eurocup!}',
                          style: Theme.of(context).textTheme.displayLarge,
                          textAlign: TextAlign.left),
                    ),
                    const Divider(
                      height: 4,
                    ),
                    Text('Eurocup / Festival',
                        style: Theme.of(context).textTheme.displaySmall,
                        textAlign: TextAlign.left),
                    ListTile(
                      title: Text(
                          'Junior: ${details.juniorEC} / ${details.junior! - details.juniorEC!}',
                          style: Theme.of(context).textTheme.displayLarge,
                          textAlign: TextAlign.left),
                    ),
                    ListTile(
                      title: Text(
                          'U24: ${details.u24EC} / ${details.u24! - details.u24EC!}',
                          style: Theme.of(context).textTheme.displayLarge,
                          textAlign: TextAlign.left),
                    ),
                    ListTile(
                      title: Text(
                          'Premier: ${details.premierEC} / ${details.premier! - details.premierEC!}',
                          style: Theme.of(context).textTheme.displayLarge,
                          textAlign: TextAlign.left),
                    ),
                    ListTile(
                      title: Text(
                          'Senior A: ${details.seniorAEC} / ${details.seniorA! - details.seniorAEC!}',
                          style: Theme.of(context).textTheme.displayLarge,
                          textAlign: TextAlign.left),
                    ),
                    ListTile(
                      title: Text(
                          'Senior B: ${details.seniorBEC} / ${details.seniorB! - details.seniorBEC!}',
                          style: Theme.of(context).textTheme.displayLarge,
                          textAlign: TextAlign.left),
                    ),
                    ListTile(
                      title: Text(
                          'Senior C: ${details.seniorCEC} / ${details.seniorC! - details.seniorCEC!}',
                          style: Theme.of(context).textTheme.displayLarge,
                          textAlign: TextAlign.left),
                    ),
                    ListTile(
                      title: Text(
                          'Senior D: ${details.seniorDEC} / ${details.seniorD! - details.seniorDEC!}',
                          style: Theme.of(context).textTheme.displayLarge,
                          textAlign: TextAlign.left),
                    ),
                    // ListTile(
                    //   title: Text('BCP: ${details.bcp}',
                    //       style: Theme.of(context).textTheme.displayLarge,
                    //       textAlign: TextAlign.left),
                    // ),
                    const Divider(
                      height: 4,
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
