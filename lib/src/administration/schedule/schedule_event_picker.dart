import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/widgets.dart';
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
    if (_error != null) return Center(child: Text('Error: $_error'));
    if (_events.isEmpty) return const Center(child: Text('No events found.'));

    return ListView.builder(
      itemCount: _events.length,
      itemBuilder: (_, i) => _eventTile(_events[i]),
    );
  }

  Widget _eventTile(Competition event) {
    return Column(children: [
      ListTile(
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
          Row(children: [
            _statusBadge(
              event.status ?? 'active',
              fg: event.isActive ? Colors.green.shade800 : Colors.grey.shade700,
              bg: event.isActive ? Colors.green.shade100 : Colors.grey.shade300,
              border: event.isActive ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 8),
            _statusBadge(
              event.isRaceEntriesOpen ? 'Entries Open' : 'Entries Closed',
              fg: event.isRaceEntriesOpen ? Colors.blue.shade800 : Colors.orange.shade800,
              bg: event.isRaceEntriesOpen ? Colors.blue.shade100 : Colors.orange.shade100,
              border: event.isRaceEntriesOpen ? Colors.blue : Colors.orange,
            ),
            const SizedBox(width: 8),
            _statusBadge(
              (event.available ?? true) ? 'Available' : 'Unavailable',
              fg: (event.available ?? true) ? Colors.teal.shade800 : Colors.red.shade800,
              bg: (event.available ?? true) ? Colors.teal.shade100 : Colors.red.shade100,
              border: (event.available ?? true) ? Colors.teal : Colors.red,
            ),
          ]),
        ]),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.pushNamed(
          context,
          ScheduleBuilderPage.routeName,
          arguments: event,
        ),
      ),
      const Divider(height: 4),
      const Divider(height: smallSpace),
    ]);
  }

  Widget _statusBadge(
    String text, {
    required Color fg,
    required Color bg,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg),
      ),
    );
  }
}
