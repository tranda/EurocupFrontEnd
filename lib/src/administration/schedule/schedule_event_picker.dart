import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';

import '../../model/event/event.dart';
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
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Error: $_error'));
    if (_events.isEmpty) return const Center(child: Text('No events found.'));
    return ListView.separated(
      itemCount: _events.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final event = _events[i];
        return ListTile(
          leading: const Icon(Icons.calendar_month, color: Color.fromARGB(255, 0, 80, 150)),
          title: Text(event.name ?? 'Event ${event.id}'),
          subtitle: Text([event.location, event.year?.toString()].whereType<String>().join(' · ')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(
            context,
            ScheduleBuilderPage.routeName,
            arguments: event,
          ),
        );
      },
    );
  }
}
