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

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Color.fromARGB(255, 0, 80, 150),
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    final style = Theme.of(context).textTheme.displaySmall;
    return Column(
      children: [
        ListTile(
          title: Text(label, style: style),
          trailing: Text(value, style: style),
        ),
        const Divider(height: 4),
      ],
    );
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
              return ListView(
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                children: [
                  _sectionLabel('ATHLETES'),
                  _statRow('Total', '${details.total}'),
                  _statRow('With AD certificate', '${details.withCertificate}'),
                  _statRow('Eurocup', '${details.eurocup}'),
                  _statRow('Festival',
                      '${details.pfestival! - details.eurocup!}'),
                  _sectionLabel('BY CATEGORY  ·  EUROCUP / FESTIVAL'),
                  _statRow('Junior',
                      '${details.juniorEC} / ${details.junior! - details.juniorEC!}'),
                  _statRow('U24',
                      '${details.u24EC} / ${details.u24! - details.u24EC!}'),
                  _statRow('Premier',
                      '${details.premierEC} / ${details.premier! - details.premierEC!}'),
                  _statRow('Senior A',
                      '${details.seniorAEC} / ${details.seniorA! - details.seniorAEC!}'),
                  _statRow('Senior B',
                      '${details.seniorBEC} / ${details.seniorB! - details.seniorBEC!}'),
                  _statRow('Senior C',
                      '${details.seniorCEC} / ${details.seniorC! - details.seniorCEC!}'),
                  _statRow('Senior D',
                      '${details.seniorDEC} / ${details.seniorD! - details.seniorDEC!}'),
                  _statRow('BCP', '${details.bcp}'),
                ],
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
