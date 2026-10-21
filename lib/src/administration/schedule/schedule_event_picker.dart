import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:eurocup_frontend/src/widgets/page_template.dart';
import 'package:flutter/material.dart';

import 'schedule_builder_page.dart';

class ScheduleEventPicker extends StatefulWidget {
  const ScheduleEventPicker({super.key});
  static const routeName = '/schedule_event_picker';

  @override
  State<ScheduleEventPicker> createState() => _ScheduleEventPickerState();
}

class _ScheduleEventPickerState extends State<ScheduleEventPicker> {
  bool _loading = true;
  String? _error;
  List<Competition> _events = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final events = await api.getCompetitions(allEvents: true);
      events.sort((a, b) => (b.year ?? 0).compareTo(a.year ?? 0));
      setState(() {
        _events = events;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(title: 'Race Schedule Builder'),
      body: Container(
        decoration: bckDecoration(),
        child: RefreshIndicator(
          onRefresh: _load,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final children = <Widget>[const PageTitleBlock(title: 'Race Schedule Builder')];
    if (_error != null) {
      children.add(_message('Error: $_error'));
    } else if (_events.isEmpty) {
      children.add(_message('No events found.'));
    } else {
      final active = _events.where((e) => e.isActive).toList();
      final inactive = _events.where((e) => !e.isActive).toList();
      if (active.isNotEmpty) children.addAll(_section('Active', active));
      if (inactive.isNotEmpty) children.addAll(_section('Inactive', inactive));
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: children,
    );
  }

  Widget _message(String text) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
    );
  }

  List<Widget> _section(String title, List<Competition> items) {
    return [
      ColoredPageHeader(title: '$title (${items.length})'),
      const Divider(height: 4),
      for (final event in items) _eventTile(event),
      pageSectionGap,
    ];
  }

  Widget _eventTile(Competition event) {
    final available = event.available ?? true;
    return PageListItem(
      onTap: () => Navigator.pushNamed(
        context,
        '${ScheduleBuilderPage.routeName}?competitionId=${event.id}',
        arguments: event,
      ),
      child: ListTile(
        title: Text(
          '${event.name ?? "Event"} ${event.year ?? ""}'.trim(),
          style: Theme.of(context).textTheme.displaySmall,
        ),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            event.location ?? 'No location',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Wrap(runSpacing: 4, children: [
            StatusChip(
              label: event.status ?? 'active',
              color: event.isActive ? Colors.green : Colors.grey,
            ),
            StatusChip(
              label: event.isRaceEntriesOpen ? 'Entries Open' : 'Entries Closed',
              color: event.isRaceEntriesOpen ? Colors.blue : Colors.orange,
            ),
            StatusChip(
              label: available ? 'Available' : 'Unavailable',
              color: available ? Colors.teal : Colors.red,
            ),
          ]),
        ]),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
