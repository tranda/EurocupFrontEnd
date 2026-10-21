import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:eurocup_frontend/src/widgets/page_template.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;

import '../model/event/event.dart';
import 'event_detail_view.dart';

class EventListView extends StatefulWidget {
  const EventListView({super.key});

  static const routeName = '/event_list';

  @override
  State<EventListView> createState() => _EventListViewState();
}

class _EventListViewState extends State<EventListView> {
  late Future<List<Competition>> dataFuture;
  List<Competition> events = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    setState(() {
      // Load all events (including unavailable) for admin management
      dataFuture = api.getCompetitions(allEvents: true);
    });
  }

  Future<void> _deleteEvent(Competition event) async {
    final bool confirmed = await _showDeleteConfirmation(event.name ?? 'Unknown Event');
    if (confirmed) {
      setState(() {
        isLoading = true;
      });

      try {
        await api.deleteEvent(event);
        _loadEvents(); // Reload the list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Event "${event.name}" deleted successfully')),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete event: $error')),
          );
        }
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<bool> _showDeleteConfirmation(String eventName) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "$eventName"?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Delete'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Event Management')),
        actions: currentUser.accessLevel! >= 3 ? [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, EventDetailView.routeName)
                  .then((value) {
                if (value == true) {
                  _loadEvents();
                }
              });
            },
            icon: const Icon(Icons.add),
          ),
        ] : [],
      ),
      body: Container(
        decoration: bckDecoration(),
        child: Stack(
          children: [
            FutureBuilder<List<Competition>>(
              future: dataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _buildMessage('Error: ${snapshot.error}');
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildMessage('No events found');
                }

                events = snapshot.data!;
                // Sort events by year (newest first)
                events.sort((a, b) => (b.year ?? 0).compareTo(a.year ?? 0));
                final active = events.where((e) => e.isActive).toList();
                final inactive = events.where((e) => !e.isActive).toList();
                return ListView(
                  children: [
                    const PageTitleBlock(title: 'Event Management'),
                    if (active.isNotEmpty) ..._buildSection('Active', active),
                    if (inactive.isNotEmpty) ..._buildSection('Inactive', inactive),
                  ],
                );
              },
            ),
            if (isLoading) busyOverlay(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(String text) {
    return ListView(
      children: [
        const PageTitleBlock(title: 'Event Management'),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
        ),
      ],
    );
  }

  List<Widget> _buildSection(String title, List<Competition> items) {
    return [
      ColoredPageHeader(title: '$title (${items.length})'),
      const Divider(height: 4),
      for (final event in items) _buildEventRow(event),
      pageSectionGap,
    ];
  }

  void _openEvent(Competition event) {
    Navigator.pushNamed(
      context,
      EventDetailView.routeName,
      arguments: {'event': event},
    ).then((value) {
      if (value == true) {
        _loadEvents();
      }
    });
  }

  Widget _buildEventRow(Competition event) {
    final available = event.available ?? true;
    return PageListItem(
      onTap: () {
        if (currentUser.accessLevel! >= 3) {
          _openEvent(event);
        }
      },
      child: ListTile(
        title: Text(
          '${event.name} ${event.year}',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.location ?? 'No location',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Wrap(
              runSpacing: 4,
              children: [
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
              ],
            ),
          ],
        ),
        trailing: currentUser.accessLevel! >= 3
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _openEvent(event),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteEvent(event),
                  ),
                ],
              )
            : const Icon(Icons.arrow_forward),
      ),
    );
  }
}
