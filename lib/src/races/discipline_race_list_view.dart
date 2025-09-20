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
  List<dynamic>? _disciplines;
  bool _isLoading = true;
  bool _isRefreshing = false;
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

      final allDisciplines = await api.getDisciplinesAll(eventId: EVENTID);
      // Debug: # of Disciplines: ${allDisciplines.length}

      setState(() {
        _disciplines = allDisciplines;
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

  Future<void> _refreshDisciplines() async {
    await _loadDisciplines(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: appBar(title: 'Disciplines'),
        body: Container(
          decoration: bckDecoration(),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: appBar(title: 'Disciplines'),
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

    final disciplines = _disciplines ?? [];

    return PageTemplate(
      title: 'Disciplines',
      items: disciplines,
      onRefresh: _refreshDisciplines,
      isRefreshing: _isRefreshing,
      emptyMessage: 'No disciplines available',
      itemBuilder: (context, discipline, index) {
        final active = discipline.status == "active";
        final inactiveStatus = discipline.status == "inactive" ? "(INACTIVE)" : "";
        var competition = competitions.firstWhere(
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
    );
  }
}
