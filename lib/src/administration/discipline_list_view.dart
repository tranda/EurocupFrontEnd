import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:eurocup_frontend/src/widgets/page_template.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;

import '../model/race/discipline.dart';
import '../model/event/event.dart';
import 'discipline_detail_view.dart';
import 'discipline_wizard_view.dart';

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

      // Load competitions first, keeping only active events
      final competitions = await api.getCompetitions();
      final activeCompetitions =
          competitions.where((c) => c.isActive).toList();
      // Sort events by year (newest first)
      activeCompetitions.sort((a, b) => (b.year ?? 0).compareTo(a.year ?? 0));
      events = activeCompetitions;

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
      // "All Events" – restrict to disciplines of active events only
      final activeEventIds = events.map((e) => e.id).toSet();
      return allDisciplines
          .where((d) => activeEventIds.contains(d.eventId))
          .toList();
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

  Widget _competitionBadge(String competition) {
    final color = competitionBadgeColor(competition);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        competition,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color.shade800,
        ),
      ),
    );
  }

  Widget _buildEventFilter() {
    return PageTitleBlock(
      title: 'Discipline Management',
      children: [
        if (events.isNotEmpty)
          DropdownButtonFormField<Competition?>(
            decoration: pageFieldDecoration('Filter by Event'),
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            dropdownColor: Colors.white,
            value: selectedEvent,
            items: events
                .map((event) => DropdownMenuItem<Competition?>(
                      value: event,
                      child: Text('${event.name} ${event.year}'),
                    ))
                .toList(),
            onChanged: (Competition? event) {
              setState(() {
                selectedEvent = event;
                filteredDisciplines = _getFilteredDisciplines();
              });
            },
          ),
      ],
    );
  }

  /// Groups disciplines by boat group + competition, keeping the current order
  /// of first appearance (and the order of rows within each group).
  Map<String, List<Discipline>> _groupDisciplines() {
    final groups = <String, List<Discipline>>{};
    for (final d in filteredDisciplines) {
      final key = '${d.boatGroup ?? ''}|${d.competition ?? ''}';
      groups.putIfAbsent(key, () => <Discipline>[]).add(d);
    }
    return groups;
  }

  List<Widget> _buildSection(List<Discipline> items) {
    final first = items.first;
    final boatGroup = (first.boatGroup == null || first.boatGroup!.isEmpty) ? 'Other' : first.boatGroup!;
    final competition = first.competition;
    return [
      ColoredPageHeader(
        title: '$boatGroup (${items.length})',
        eventId: selectedEvent?.id,
        titleBadge: (competition != null && competition.isNotEmpty) ? _competitionBadge(competition) : null,
      ),
      const Divider(height: 4),
      for (final d in items) _buildDisciplineRow(d),
      pageSectionGap,
    ];
  }

  void _openDiscipline(Discipline discipline) {
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

  Widget _buildDisciplineRow(Discipline discipline) {
    final event = events.firstWhere(
      (e) => e.id == discipline.eventId,
      orElse: () => const Competition(name: 'Unknown Event'),
    );
    final status = discipline.status ?? 'active';
    return PageListItem(
      onTap: () {
        if (currentUser.accessLevel! >= 3) {
          _openDiscipline(discipline);
        }
      },
      child: ListTile(
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                discipline.getDisplayName(),
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ),
            if (discipline.competition != null && discipline.competition!.isNotEmpty) ...[
              const SizedBox(width: 10),
              _competitionBadge(discipline.competition!),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Event: ${event.name} ${event.year}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Wrap(
              runSpacing: 4,
              children: [
                StatusChip(
                  label: status,
                  color: status == 'active' ? Colors.green : Colors.grey,
                ),
                if (discipline.teamsCount != null)
                  StatusChip(label: 'Teams: ${discipline.teamsCount}'),
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
                    onPressed: () => _openDiscipline(discipline),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteDiscipline(discipline),
                  ),
                ],
              )
            : const Icon(Icons.arrow_forward),
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
            tooltip: 'Combination wizard',
            onPressed: () {
              Navigator.pushNamed(
                context,
                DisciplineWizardView.routeName,
                arguments: {
                  'events': events,
                  'selectedEvent': selectedEvent,
                  'disciplines': allDisciplines,
                },
              ).then((value) {
                if (value == true) {
                  _loadData(isRefresh: true);
                }
              });
            },
            icon: const Icon(Icons.grid_on),
          ),
          IconButton(
            tooltip: 'Add discipline',
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
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _buildEventFilter(),
                  if (filteredDisciplines.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No disciplines found',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  for (final group in _groupDisciplines().values) ..._buildSection(group),
                ],
              ),
            ),
            if (_isRefreshing) busyOverlay(context),
          ],
        ),
      ),
    );
  }
}