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
          final isFinal = raceResult.isFinalRound ?? false;
          _calculatePositions(crewResults, isFinalRound: isFinal);

          // Sort crew results based on position type
          if (isFinal) {
            // For final rounds, sort by finalPosition (based on accumulated final times)
            crewResults.sort((a, b) {
              final aPos = a.finalPosition;
              final bPos = b.finalPosition;
              if (aPos == null && bPos == null) {
                // If both have no final position, sort by final time if available
                if (a.finalTimeMs != null && b.finalTimeMs != null) {
                  return a.finalTimeMs!.compareTo(b.finalTimeMs!);
                }
                return 0;
              }
              if (aPos == null) return 1;
              if (bPos == null) return -1;
              return aPos.compareTo(bPos);
            });
          } else {
            // For regular rounds, sort by current round position
            crewResults.sort((a, b) {
              if (a.position == null && b.position == null) return 0;
              if (a.position == null) return 1;
              if (b.position == null) return -1;
              return a.position!.compareTo(b.position!);
            });
          }

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
                    '#${raceResult.raceNumber} ${raceResult.raceTimeDisplay} ${raceResult.discipline?.getDisplayName() ?? 'Unknown'} - ${raceResult.stage}${isFinal ? ' (Final)' : ''}',
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
          return _buildCrewResultItem(context, crewResult, raceResult, isFinal);
        },
      ),
    );
  }

  void _calculatePositions(List<CrewResult> crewResults, {bool isFinalRound = false}) {
    if (isFinalRound) {
      // For final rounds, use the backend-provided finalPosition
      // The backend calculates positions based on accumulated final times

      // Check if we have valid finalPosition data from backend
      final hasValidFinalPositions = crewResults.any((crew) => crew.finalPosition != null);

      if (hasValidFinalPositions) {
        // Use backend-provided finalPosition
        for (var crew in crewResults) {
          crew.position = crew.finalPosition;
        }
      } else {
        // Fallback: calculate positions based on finalTimeMs if finalPosition is missing
        final finishedCrews = crewResults
            .where((crew) => crew.finalStatus == 'FINISHED' && crew.finalTimeMs != null)
            .toList();

        // Sort by final time (fastest first)
        finishedCrews.sort((a, b) => a.finalTimeMs!.compareTo(b.finalTimeMs!));

        // Assign positions based on final times
        for (int i = 0; i < finishedCrews.length; i++) {
          finishedCrews[i].position = i + 1;
        }

        // Clear positions for non-finished crews
        crewResults
            .where((crew) => crew.finalStatus != 'FINISHED' || crew.finalTimeMs == null)
            .forEach((crew) => crew.position = null);
      }
    } else {
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
  }

  Widget _buildCrewResultItem(BuildContext context, CrewResult crewResult, RaceResult raceResult, bool isFinalRound) {
    if (isFinalRound && crewResult.hasFinalTime) {
      // Two-line format for final rounds
      return Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey,
              width: 0.5,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Position indicator
              CircleAvatar(
                backgroundColor: _getPositionColor(crewResult.position),
                radius: 20,
                child: Text(
                  crewResult.position?.toString() ?? '-',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Team name and times
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Team name
                    Text(
                      crewResult.crew?.team?.name ?? crewResult.team?.name ?? 'Unknown Team',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Lane info if available
                    if (crewResult.lane != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'Lane ${crewResult.lane}',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Time displays
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Current round time
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
                  const SizedBox(height: 4),
                  // Final time with position
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total: ${crewResult.displayFinalTime}',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (crewResult.position != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            '[${_getPositionDisplay(crewResult.position!)}]',
                            style: TextStyle(
                              color: _getPositionColor(crewResult.position),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      // Regular single-line format for non-final rounds
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
                      _calculateDelay(crewResult, raceResult, isFinalRound: false),
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
  }

  String _calculateDelay(CrewResult crewResult, RaceResult raceResult, {bool isFinalRound = false}) {
    if (crewResult.position == null || crewResult.position == 1) {
      return '';
    }

    int? currentTime;
    int? firstPlaceTime;

    if (isFinalRound && crewResult.finalTimeMs != null) {
      // For final rounds, use final times and find first place based on finalPosition
      currentTime = crewResult.finalTimeMs;
      firstPlaceTime = raceResult.crewResults
          ?.where((crew) => crew.finalPosition == 1 && crew.finalTimeMs != null)
          .firstOrNull
          ?.finalTimeMs;
    } else if (!isFinalRound && crewResult.timeMs != null) {
      // For regular rounds, use round times
      currentTime = crewResult.timeMs;
      firstPlaceTime = raceResult.crewResults
          ?.where((crew) => crew.position == 1 && crew.timeMs != null)
          .firstOrNull
          ?.timeMs;
    }

    if (currentTime == null || firstPlaceTime == null) return '';

    final delayMs = currentTime - firstPlaceTime;
    final delaySeconds = delayMs / 1000.0;

    return '+${delaySeconds.toStringAsFixed(2)}s';
  }

  String _getPositionDisplay(int position) {
    if (position == 1) return '1st';
    if (position == 2) return '2nd';
    if (position == 3) return '3rd';
    return '${position}th';
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