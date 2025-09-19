import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/model/race/race_result.dart';
import 'package:eurocup_frontend/src/model/race/crew_result.dart';
import 'package:eurocup_frontend/src/races/race_result_detail_view.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;

class RaceResultsListView extends StatefulWidget {
  const RaceResultsListView({super.key});

  static const routeName = '/race_results_list';

  @override
  State<RaceResultsListView> createState() => _RaceResultsListViewState();
}

class _RaceResultsListViewState extends State<RaceResultsListView> {
  final Set<int?> _expandedRaces = <int?>{};
  List<RaceResult>? _raceResults;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  String? _eventId;
  String? _eventName;

  @override
  void initState() {
    super.initState();
    // Extract arguments will be handled in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Extract navigation arguments if available
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      _eventId = arguments['eventId'] as String?;
      _eventName = arguments['eventName'] as String?;
    }
    
    // Default to current EVENTID if no event ID provided
    _eventId ??= EVENTID.toString();
    _eventName ??= 'EuroCup 2025';
    
    _loadRaceResults();
  }

  Future<void> _loadRaceResults({bool isRefresh = false}) async {
    // Only load if we haven't loaded yet or if we're reloading
    if (_raceResults != null && !_isLoading && !isRefresh) return;

    try {
      setState(() {
        if (isRefresh) {
          _isRefreshing = true;
        } else {
          _isLoading = true;
        }
        _errorMessage = null;
      });

      final eventIdInt = int.tryParse(_eventId ?? EVENTID.toString()) ?? EVENTID;
      // Use public API if we don't have an authenticated token, otherwise use authenticated API
      final results = (token == null || token!.isEmpty)
          ? await api.getPublicRaceResults(eventId: eventIdInt)
          : await api.getRaceResults(eventId: eventIdInt);

      setState(() {
        _raceResults = results;
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

  Future<void> _refreshResults() async {
    await _loadRaceResults(isRefresh: true);
  }

  void _expandAll() {
    setState(() {
      final races = _raceResults ?? [];
      _expandedRaces.addAll(races.map((race) => race.id));
    });
  }

  void _collapseAll() {
    setState(() {
      _expandedRaces.clear();
    });
  }

  void _calculatePositions(List<CrewResult> crewResults) {
    // Get only crews with valid times and FINISHED status
    final finishedCrews = crewResults
        .where((crew) => crew.status == 'FINISHED' && crew.timeMs != null)
        .toList();
    
    // Sort by time (fastest first)
    finishedCrews.sort((a, b) => a.timeMs!.compareTo(b.timeMs!));
    
    // Assign positions to finished crews
    for (int i = 0; i < finishedCrews.length; i++) {
      finishedCrews[i].position = i + 1;
    }
    
    // Clear positions for non-finished crews
    crewResults
        .where((crew) => crew.status != 'FINISHED' || crew.timeMs == null)
        .forEach((crew) => crew.position = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWithAction(
        _isRefreshing ? null : _refreshResults,
        title: 'Race Results',
        icon: _isRefreshing ? Icons.hourglass_empty : Icons.refresh,
      ),
      body: Container(
        decoration: bckDecoration(),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Error loading race results:',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadRaceResults(isRefresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final races = _raceResults ?? [];
    races.sort((a, b) => (a.raceNumber ?? 0).compareTo(b.raceNumber ?? 0));

    if (races.isEmpty) {
      return const Center(
        child: Text('No race results available'),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshResults,
      child: ListView.builder(
        itemCount: races.length + 1, // +1 for the header
        itemBuilder: (context, index) {
        // First item is the header
        if (index == 0) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _eventName ?? 'EuroCup 2025',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _expandAll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: competitionColor[(int.tryParse(_eventId ?? '1') ?? 1) - 1],
                        foregroundColor: Colors.white,
                        minimumSize: const Size(80, 28),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        textStyle: const TextStyle(fontSize: 12),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Expand All'),
                    ),
                    ElevatedButton(
                      onPressed: _collapseAll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: competitionColor[(int.tryParse(_eventId ?? '1') ?? 1) - 1],
                        foregroundColor: Colors.white,
                        minimumSize: const Size(80, 28),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        textStyle: const TextStyle(fontSize: 12),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Collapse All'),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        // Adjust index for race results (subtract 1 because of header)
        final raceResult = races[index - 1];
        try {
          final discipline = raceResult.discipline;
          
          final isExpanded = _expandedRaces.contains(raceResult.id);
          final crewResults = raceResult.crewResults ?? [];
          
          // Calculate positions based on time and sort crew results
          _calculatePositions(crewResults);
          crewResults.sort((a, b) {
            if (a.position == null && b.position == null) return 0;
            if (a.position == null) return 1;
            if (b.position == null) return -1;
            return a.position!.compareTo(b.position!);
          });

          return Column(
            children: [
                Container(
                  color: competitionColor[(int.tryParse(_eventId ?? '1') ?? 1) - 1],
                  child: ListTile(
                    onTap: crewResults.isEmpty ? () {
                      Navigator.pushNamed(
                        context,
                        RaceResultDetailView.routeName,
                        arguments: {'raceResultId': raceResult.id},
                      );
                    } : () {
                      setState(() {
                        if (isExpanded) {
                          _expandedRaces.remove(raceResult.id);
                        } else {
                          _expandedRaces.add(raceResult.id);
                        }
                      });
                    },
                    leading: Text(
                      _eventName ?? 'EuroCup 2025',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    title: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '#${raceResult.raceNumber} ${raceResult.raceTimeDisplay} ${discipline?.getDisplayName() ?? 'Unknown'} - ${raceResult.stage}',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    subtitle: Text(
                      '${raceResult.statusDisplay} (${crewResults.length})',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (crewResults.isNotEmpty)
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: Colors.white,
                          ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              RaceResultDetailView.routeName,
                              arguments: {'raceResultId': raceResult.id},
                            );
                          },
                          child: const Icon(Icons.arrow_forward, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(
                  height: 4,
                ),

                // Expandable crew results section
                if (isExpanded && crewResults.isNotEmpty)
                  Column(
                    children: [
                      ...crewResults.map((crewResult) => _buildCrewResultItem(context, crewResult, raceResult)),
                    ],
                  ),

                if (isExpanded && crewResults.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: const Text(
                      'No crews registered for this race yet',
                      style: TextStyle(
                        color: Colors.black54,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                const Divider(
                  height: smallSpace,
                ),
              ],
            );
        } catch (e, stackTrace) {
          print('Error building race result item: $e');
          print('Stack trace: $stackTrace');
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Error displaying race result: $e',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }
      },
      ),
    );
  }

  Widget _buildCrewResultItem(BuildContext context, CrewResult crewResult, RaceResult raceResult) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey,
            width: 0.5,
          ),
        ),
      ),
      child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _getPositionColor(crewResult.position),
            child: Text(
              crewResult.position?.toString() ?? '-',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            crewResult.crew?.team?.name ?? crewResult.team?.name ?? 'Unknown Team',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          subtitle: crewResult.lane != null
              ? Text(
                  'Lane ${crewResult.lane}',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                )
              : null,
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(crewResult.status),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  crewResult.displayTime,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              if (crewResult.isFinished && crewResult.position != null && crewResult.position! > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    _calculateDelay(crewResult, raceResult),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
      ),
    );
  }


  String _calculateDelay(CrewResult crewResult, RaceResult raceResult) {
    if (crewResult.position == null || crewResult.position == 1 || crewResult.timeMs == null) {
      return '';
    }
    
    // Find the first place crew's time
    final firstPlaceTime = raceResult.crewResults
        ?.where((crew) => crew.position == 1 && crew.timeMs != null)
        .firstOrNull
        ?.timeMs;
    
    if (firstPlaceTime == null) return '';
    
    final delayMs = crewResult.timeMs! - firstPlaceTime;
    final delaySeconds = delayMs / 1000.0;
    
    return '+${delaySeconds.toStringAsFixed(2)}s';
  }

  Color _getPositionColor(int? position) {
    switch (position) {
      case 1:
        return Colors.amber; // Gold
      case 2:
        return Colors.grey; // Silver
      case 3:
        return Colors.brown; // Bronze
      default:
        return Colors.blue;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'FINISHED':
        return Colors.green;
      case 'DNS':
        return Colors.orange;
      case 'DNF':
        return Colors.red;
      case 'DSQ':
        return Colors.purple;
      case null:
        return Colors.blue; // Registered but no result yet
      default:
        return Colors.grey;
    }
  }
}