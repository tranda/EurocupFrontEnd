import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/races/race_detail_view.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:eurocup_frontend/src/widgets/page_template.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;
class DisciplineRaceListView extends StatefulWidget {
  const DisciplineRaceListView({super.key});

  static const routeName = '/disciplineRace_list';

  @override
  State<DisciplineRaceListView> createState() => _CrewListViewState();
}

class _CrewListViewState extends State<DisciplineRaceListView> {
  List<dynamic> _allDisciplines = [];
  List<dynamic> _filteredDisciplines = [];
  List<Competition> _events = [];
  Competition? _selectedEvent;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _initialEventSet = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDisciplines();
  }

  Future<void> _loadDisciplines({bool isRefresh = false}) async {
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
      _events = competitions;

      // Set initial selectedEvent to EVENTID if not already set
      if (!_initialEventSet && _events.isNotEmpty) {
        _selectedEvent = _events.firstWhere(
          (event) => event.id == EVENTID,
          orElse: () => _events.last,
        );
        _initialEventSet = true;
      }

      // Load all disciplines
      final allDisciplines = await api.getDisciplinesAll();
      _allDisciplines = allDisciplines;
      _filteredDisciplines = _getFilteredDisciplines();

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

  List<dynamic> _getFilteredDisciplines() {
    if (_selectedEvent == null) {
      return List.from(_allDisciplines);
    } else {
      return _allDisciplines
          .where((d) => d.eventId == _selectedEvent!.id)
          .toList();
    }
  }

  Future<void> _refreshDisciplines() async {
    await _loadDisciplines(isRefresh: true);
  }

  Widget _buildEventFilter() {
    if (_events.isEmpty) {
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
            'Current Entries',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Competition?>(
            decoration: InputDecoration(
              labelText: 'Select Event',
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
            initialValue: _selectedEvent,
            items: _events.map((event) => DropdownMenuItem<Competition?>(
              value: event,
              child: Text('${event.name} ${event.year}'),
            )).toList(),
            onChanged: (Competition? event) {
              setState(() {
                _selectedEvent = event;
                _filteredDisciplines = _getFilteredDisciplines();
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
        appBar: appBar(title: 'Current Entries'),
        body: Container(
          decoration: bckDecoration(),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: appBar(title: 'Current Entries'),
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
                  onPressed: () => _loadDisciplines(isRefresh: true),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: appBar(title: 'Current Entries'),
      body: Container(
        decoration: bckDecoration(),
        child: RefreshIndicator(
          onRefresh: _refreshDisciplines,
          child: ListView.builder(
            itemCount: _filteredDisciplines.length + 1, // +1 for header
            itemBuilder: (context, index) {
              // First item is the filter header
              if (index == 0) {
                return _buildEventFilter();
              }

              // Adjust index for disciplines (subtract 1 because of header)
              final discipline = _filteredDisciplines[index - 1];
              final inactiveStatus = discipline.status == "inactive" ? "(INACTIVE)" : "";
              var competition = _events.firstWhere(
                  (element) => element.id == discipline.eventId);
              var eventName = '${competition.name!} ${competition.year}';
              var teams = discipline.teams;

              // Only show disciplines that have teams (visible condition from original)
              if (teams != null && teams.isEmpty) {
                return const SizedBox.shrink();
              }

              return Column(
                children: [
                  ColoredPageHeader(
                    title: "${discipline.getDisplayName()} $inactiveStatus (${discipline.teamsCount})",
                    eventId: discipline.eventId,
                    leading: Text(
                      eventName,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    trailing: (teams != null && teams.isEmpty || currentUser.accessLevel! < 1)
                        ? null
                        : const Icon(Icons.arrow_forward, color: Colors.white),
                    onTap: (teams != null && teams.isEmpty || currentUser.accessLevel! < 1)
                        ? null
                        : () {
                            Navigator.pushNamed(
                              context,
                              RaceDetailView.routeName,
                              arguments: {'disciplineId': discipline.id}
                            );
                          },
                  ),
                  const Divider(height: 4),
                  Column(
                    children: discipline.teams?.map<Widget>((team) {
                      return PageListItem(
                        child: ListTile(
                          title: Text(
                            team.team?.name ?? '',
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                        ),
                      );
                    }).toList() ?? [],
                  ),
                  const Divider(height: smallSpace),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
