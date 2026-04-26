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
  final List<String> _filterCompetitions = [];

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
      // Sort events by year (newest first)
      competitions.sort((a, b) => (b.year ?? 0).compareTo(a.year ?? 0));
      _events = competitions;

      // Set initial selectedEvent to first active event if not already set
      if (!_initialEventSet && _events.isNotEmpty) {
        _selectedEvent = _events.firstWhere(
          (event) => event.isActive,
          orElse: () => _events.first,
        );
        _initialEventSet = true;
      }

      // Load disciplines for the selected event
      if (_selectedEvent != null) {
        final disciplines = await api.getDisciplinesAll(eventId: _selectedEvent!.id);
        _allDisciplines = disciplines;
        _filterCompetitions.clear();
        _filteredDisciplines = _applyCompetitionFilter();
      }

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

  Future<void> _loadDisciplinesForEvent(Competition event) async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      final disciplines = await api.getDisciplinesAll(eventId: event.id);
      setState(() {
        _allDisciplines = disciplines;
        _filterCompetitions.clear();
        _filteredDisciplines = _applyCompetitionFilter();
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isRefreshing = false;
      });
    }
  }

  Future<void> _refreshDisciplines() async {
    await _loadDisciplines(isRefresh: true);
  }

  List<dynamic> _applyCompetitionFilter() {
    if (_filterCompetitions.isEmpty) return List.from(_allDisciplines);
    return _allDisciplines
        .where((d) => _filterCompetitions.contains(d.competition))
        .toList();
  }

  List<Widget> _buildCompetitionChips() {
    final competitionsSet = <String>{};
    for (var d in _allDisciplines) {
      final c = d.competition as String?;
      if (c != null && c.isNotEmpty) competitionsSet.add(c);
    }
    if (competitionsSet.isEmpty) return const [];
    final available = competitionsSet.toList()..sort();

    return available.map((comp) {
      final isSelected = _filterCompetitions.contains(comp);
      final color = competitionBadgeColor(comp);
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            setState(() {
              if (isSelected) {
                _filterCompetitions.remove(comp);
              } else {
                _filterCompetitions.add(comp);
              }
              _filteredDisciplines = _applyCompetitionFilter();
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected ? color.shade100 : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color, width: 1),
            ),
            child: Text(
              comp,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? color.shade900 : color.shade800,
              ),
            ),
          ),
        ),
      );
    }).toList();
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
              if (event != null) {
                _selectedEvent = event;
                _loadDisciplinesForEvent(event);
              }
            },
          ),
          Builder(builder: (context) {
            final chips = _buildCompetitionChips();
            if (chips.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  runSpacing: 8,
                  children: chips,
                ),
              ),
            );
          }),
        ],
      ),
    );
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
                    title: "${discipline.getDisplayName()} $inactiveStatus (${discipline.teamsCount ?? 0})",
                    eventId: discipline.eventId,
                    titleBadge: (discipline.competition != null && discipline.competition!.isNotEmpty)
                        ? _competitionBadge(discipline.competition!)
                        : null,
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
                          title: Row(
                            children: [
                              if (team.team?.club?.country != null)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Text(
                                    '${getCountryFlag(team.team!.club!.country)} ${getCountryCode(team.team!.club!.country)}',
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  team.team?.name ?? '',
                                  style: Theme.of(context).textTheme.displaySmall,
                                ),
                              ),
                            ],
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
