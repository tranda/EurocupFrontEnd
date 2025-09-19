import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/widgets.dart';
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
      dataFuture = api.getCompetitions();
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
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No events found'));
                }

                events = snapshot.data!;
                return ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (BuildContext context, int index) {
                    final event = events[index];
                    return Column(
                      children: [
                        ListTile(
                          title: Text(
                            '${event.name} ${event.year}',
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          subtitle: Text(
                            event.location ?? 'No location',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          trailing: currentUser.accessLevel! >= 3 ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    EventDetailView.routeName,
                                    arguments: {'event': event},
                                  ).then((value) {
                                    if (value == true) {
                                      _loadEvents();
                                    }
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteEvent(event),
                              ),
                            ],
                          ) : const Icon(Icons.arrow_forward),
                          onTap: () {
                            if (currentUser.accessLevel! >= 3) {
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
                          },
                        ),
                        const Divider(height: 4),
                        const Divider(height: smallSpace),
                      ],
                    );
                  },
                );
              },
            ),
            if (isLoading) busyOverlay(context),
          ],
        ),
      ),
    );
  }
}