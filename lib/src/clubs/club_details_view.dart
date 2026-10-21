import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:eurocup_frontend/src/model/club_details.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:eurocup_frontend/src/widgets/page_template.dart';
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

  Widget _statRow(String label, String value) {
    final style = Theme.of(context).textTheme.displaySmall;
    return PageListItem(
      child: ListTile(
        title: Text(label, style: style),
        trailing: Text(
          value,
          style: style?.copyWith(
            fontWeight: FontWeight.bold,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
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
        // Fill the screen even when the content is short.
        height: double.infinity,
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
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  PageTitleBlock(title: title),
                  pageSectionGap,
                  const ColoredPageHeader(title: 'Athletes'),
                  const Divider(height: 4),
                  _statRow('Total', '${details.total}'),
                  _statRow('With AD certificate', '${details.withCertificate}'),
                  _statRow('Eurocup', '${details.eurocup}'),
                  _statRow('Festival',
                      '${details.pfestival! - details.eurocup!}'),
                  pageSectionGap,
                  const ColoredPageHeader(
                    title: 'By category',
                    subtitle: 'Eurocup / Festival',
                  ),
                  const Divider(height: 4),
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
              return const Center(child: Text('No data'));
            }
          },
        ),
      ),
    );
  }
}
