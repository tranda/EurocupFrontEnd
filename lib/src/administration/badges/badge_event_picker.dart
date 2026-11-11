import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:eurocup_frontend/src/widgets/page_template.dart';
import 'package:flutter/material.dart';

import 'badges_page.dart';

/// Pick the event to make accreditation badges for (Event Managers and up).
class BadgeEventPicker extends StatefulWidget {
  const BadgeEventPicker({super.key});
  static const routeName = '/badge_event_picker';

  @override
  State<BadgeEventPicker> createState() => _BadgeEventPickerState();
}

class _BadgeEventPickerState extends State<BadgeEventPicker> {
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
      appBar: appBar(title: 'Badges'),
      body: Container(
        decoration: bckDecoration(),
        child: RefreshIndicator(onRefresh: _load, child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final children = <Widget>[const PageTitleBlock(title: 'Accreditation Badges')];
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

    return ListView(physics: const AlwaysScrollableScrollPhysics(), children: children);
  }

  Widget _message(String text) => Padding(
        padding: const EdgeInsets.all(24),
        child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
      );

  List<Widget> _section(String title, List<Competition> items) => [
        ColoredPageHeader(title: '$title (${items.length})'),
        const Divider(height: 4),
        for (final event in items)
          PageListItem(
            onTap: () => Navigator.pushNamed(context, '${BadgesPage.routeName}?eventId=${event.id}', arguments: event),
            child: ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: Text('${event.name ?? "Event"} ${event.year ?? ""}'.trim(),
                  style: Theme.of(context).textTheme.displaySmall),
              subtitle: Text(event.location ?? 'No location', style: Theme.of(context).textTheme.headlineMedium),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        pageSectionGap,
      ];
}
