import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/model/race/race_result.dart';
import 'package:eurocup_frontend/src/model/race/crew_result.dart';
import 'package:eurocup_frontend/src/races/race_results_list_view.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:intl/intl.dart';

class RaceResultDetailView extends StatefulWidget {
  const RaceResultDetailView({super.key});

  static const routeName = '/race_result_detail';

  @override
  State<RaceResultDetailView> createState() => _RaceResultDetailViewState();
}

class _RaceResultDetailViewState extends State<RaceResultDetailView> {
  int? raceResultId;
  RaceResult? _raceResult;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    raceResultId = args?['raceResultId'] as int?;

    // If we don't have a race result ID, redirect to race results list
    if (raceResultId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(RaceResultsListView.routeName);
      });
      return;
    }

    // Load race result data on first load
    if (raceResultId != null && _raceResult == null && _isLoading) {
      _loadRaceResult();
    }
  }

  Future<void> _loadRaceResult({bool isRefresh = false}) async {
    if (raceResultId == null) return;

    // Only load if we haven't loaded yet or if we're reloading
    if (_raceResult != null && !_isLoading && !isRefresh) return;

    try {
      setState(() {
        if (isRefresh) {
          _isRefreshing = true;
        } else {
          _isLoading = true;
        }
        _errorMessage = null;
      });

      final result = (token == null || token!.isEmpty)
          ? await api.getPublicRaceResult(raceResultId!)
          : await api.getRaceResult(raceResultId!);

      setState(() {
        _raceResult = result;
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

  Future<void> _refreshRaceResult() async {
    await _loadRaceResult(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    if (raceResultId == null) {
      return Scaffold(
        appBar: appBar(title: 'Race Result'),
        body: const Center(child: Text('Invalid race result')),
      );
    }

    return Scaffold(
      appBar: appBarWithAction(
        _isRefreshing ? null : _refreshRaceResult,
        title: 'Race Result',
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
              'Error loading race result:',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadRaceResult(isRefresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_raceResult == null) {
      return const Center(child: Text('Race result not found'));
    }

    final raceResult = _raceResult!;
    final crewResults = raceResult.crewResults ?? [];
          
          // Calculate positions based on time and sort crew results
          _calculatePositions(crewResults);
          crewResults.sort((a, b) {
            if (a.position == null && b.position == null) return 0;
            if (a.position == null) return 1;
            if (b.position == null) return -1;
            return a.position!.compareTo(b.position!);
          });

    return RefreshIndicator(
      onRefresh: _refreshRaceResult,
      child: ListView.builder(
        itemCount: crewResults.isEmpty ? 2 : crewResults.length + 1, // +1 for header, +1 for empty state
        itemBuilder: (context, index) {
          // First item is the header
          if (index == 0) {
            return Container(
              color: competitionColor[(int.tryParse(EVENTID.toString()) ?? 1) - 1],
              child: ListTile(
                title: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '#${raceResult.raceNumber} ${raceResult.raceTimeDisplay} ${raceResult.discipline?.getDisplayName() ?? 'Unknown'} - ${raceResult.stage}',
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
              ),
            );
          }

          // Handle empty crew results
          if (crewResults.isEmpty && index == 1) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'No crews registered for this race yet',
                style: TextStyle(
                  color: Colors.black54,
                  fontStyle: FontStyle.italic,
                ),
              ),
            );
          }

          // Adjust index for crew results (subtract 1 because of header)
          final crewResult = crewResults[index - 1];
          return _buildCrewResultItem(context, crewResult, raceResult);
        },
      ),
    );
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