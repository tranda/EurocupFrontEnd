import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:eurocup_frontend/src/widgets/page_template.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;

import '../model/race/discipline.dart';
import '../model/event/event.dart';
import 'discipline_detail_view.dart';

class AdminDisciplineListView extends StatefulWidget {
  const AdminDisciplineListView({super.key});

  static const routeName = '/admin_discipline_list';

  @override
  State<AdminDisciplineListView> createState() => _AdminDisciplineListViewState();
}

class _AdminDisciplineListViewState extends State<AdminDisciplineListView> {
  List<Discipline> allDisciplines = [];
  List<Discipline> filteredDisciplines = [];
  List<Competition> events = [];
  Competition? selectedEvent;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _initialEventSet = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool isRefresh = false}) async {
    try {
      setState(() {
        if (isRefresh) {
          _isRefreshing = true;
        } else {
          _isLoading = true;
        }
        _errorMessage = null;
      });

      // Load competitions first
      final competitions = await api.getCompetitions();
      // Sort events by year (newest first)
      competitions.sort((a, b) => (b.year ?? 0).compareTo(a.year ?? 0));
      events = competitions;

      // Set initial selectedEvent to the first item (newest year) if not already set
      if (!_initialEventSet && events.isNotEmpty) {
        selectedEvent = events.first;
        _initialEventSet = true;
      }

      // Load disciplines
      final disciplines = await api.getDisciplinesAll();
      allDisciplines = disciplines;
      filteredDisciplines = _getFilteredDisciplines();

      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadData(isRefresh: true);
  }

  List<Discipline> _getFilteredDisciplines() {
    if (selectedEvent == null) {
      return List.from(allDisciplines);
    } else {
      return allDisciplines
          .where((d) => d.eventId == selectedEvent!.id)
          .toList();
    }
  }

  Future<void> _deleteDiscipline(Discipline discipline) async {
    final bool confirmed = await _showDeleteConfirmation(discipline.getDisplayName());
    if (confirmed) {
      setState(() {
        _isRefreshing = true;
      });

      try {
        await api.deleteDiscipline(discipline);
        await _loadData(isRefresh: true); // Reload the list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Discipline "${discipline.getDisplayName()}" deleted successfully')),
          );
        }
      } catch (error) {
        setState(() {
          _isRefreshing = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete discipline: $error')),
          );
        }
      }
    }
  }

  Future<bool> _showDeleteConfirmation(String disciplineName) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "$disciplineName"?'),
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

  Widget _buildEventFilter() {
    if (events.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Discipline Management',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Competition?>(
            decoration: InputDecoration(
              labelText: 'Filter by Event',
              labelStyle: const TextStyle(
                color: Color.fromARGB(255, 0, 80, 150),
                fontWeight: FontWeight.w500,
              ),
              contentPadding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 12.0),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: Colors.grey, width: 1.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: Colors.grey, width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: Color.fromARGB(255, 0, 80, 150), width: 2.0),
              ),
            ),
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            dropdownColor: Colors.white,
            value: selectedEvent,
            items: [
              const DropdownMenuItem<Competition?>(
                value: null,
                child: Text('All Events'),
              ),
              ...events.map((event) => DropdownMenuItem<Competition?>(
                value: event,
                child: Text('${event.name} ${event.year}'),
              )),
            ],
            onChanged: (Competition? event) {
              setState(() {
                selectedEvent = event;
                filteredDisciplines = _getFilteredDisciplines();
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Center(child: Text('Administration')),
        ),
        body: Container(
          decoration: bckDecoration(),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Center(child: Text('Administration')),
        ),
        body: Container(
          decoration: bckDecoration(),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Error loading disciplines:',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _loadData(isRefresh: true),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Administration')),
        actions: currentUser.accessLevel! >= 3 ? [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                DisciplineDetailView.routeName,
                arguments: {
                  'events': events,
                  'selectedEvent': selectedEvent,
                },
              ).then((value) {
                if (value == true) {
                  _loadData(isRefresh: true);
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
            RefreshIndicator(
              onRefresh: _refreshData,
              child: ListView.builder(
                itemCount: filteredDisciplines.length + 1, // +1 for header
                itemBuilder: (context, index) {
                  // First item is the filter header
                  if (index == 0) {
                    return _buildEventFilter();
                  }

                  // Adjust index for disciplines (subtract 1 because of header)
                  final discipline = filteredDisciplines[index - 1];
                  final event = events.firstWhere(
                    (e) => e.id == discipline.eventId,
                    orElse: () => const Competition(name: 'Unknown Event'),
                  );

                  return Column(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: ListTile(
                          title: Text(
                            discipline.getDisplayName(),
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Event: ${event.name} ${event.year}',
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                              Text(
                                'Status: ${discipline.status ?? 'active'}',
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                              if (discipline.teamsCount != null)
                                Text(
                                  'Teams: ${discipline.teamsCount}',
                                  style: Theme.of(context).textTheme.headlineMedium,
                                ),
                            ],
                          ),
                          trailing: currentUser.accessLevel! >= 3 ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    DisciplineDetailView.routeName,
                                    arguments: {
                                      'discipline': discipline,
                                      'events': events,
                                    },
                                  ).then((value) {
                                    if (value == true) {
                                      _loadData(isRefresh: true);
                                    }
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteDiscipline(discipline),
                              ),
                            ],
                          ) : const Icon(Icons.arrow_forward),
                          onTap: () {
                            if (currentUser.accessLevel! >= 3) {
                              Navigator.pushNamed(
                                context,
                                DisciplineDetailView.routeName,
                                arguments: {
                                  'discipline': discipline,
                                  'events': events,
                                },
                              ).then((value) {
                                if (value == true) {
                                  _loadData(isRefresh: true);
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            if (_isRefreshing) busyOverlay(context),
          ],
        ),
      ),
    );
  }
}