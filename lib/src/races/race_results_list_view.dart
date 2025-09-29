import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/model/race/race_result.dart';
import 'package:eurocup_frontend/src/model/race/crew_result.dart';
import 'package:eurocup_frontend/src/races/race_result_detail_view.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
  Competition? _competition;


  /// Returns event title without year
  String _getEventTitle() {
    // Use competition's name if available
    if (_competition != null) {
      final shortName = _competition!.getShortName();
      final words = shortName.split(' ');
      if (words.length > 1 && RegExp(r'^\d{4}$').hasMatch(words.last)) {
        return words.sublist(0, words.length - 1).join(' ');
      }
      return shortName;
    }

    // Fallback to processing _eventName if no competition data
    if (_eventName == null) return 'Event';

    final words = _eventName!.split(' ');
    final lastWord = words.last;

    // Check if last word is a year (4 digits)
    if (RegExp(r'^\d{4}$').hasMatch(lastWord)) {
      return words.sublist(0, words.length - 1).join(' ');
    }

    // If no year found, return the first word or full name
    return words.length > 1 ? words.first : _eventName!;
  }

  /// Returns event year
  String _getEventYear() {
    // Use competition's year if available
    if (_competition != null) {
      final shortName = _competition!.getShortName();
      final words = shortName.split(' ');
      if (words.length > 1 && RegExp(r'^\d{4}$').hasMatch(words.last)) {
        return words.last;
      }
    }

    // Fallback to processing _eventName if no competition data
    if (_eventName != null) {
      final words = _eventName!.split(' ');
      final lastWord = words.last;

      // Check if last word is a year (4 digits)
      if (RegExp(r'^\d{4}$').hasMatch(lastWord)) {
        return lastWord;
      }
    }

    // Default to current year
    return DateTime.now().year.toString();
  }

  /// Returns full event name for file naming
  String _getEventFullName() {
    // Use competition's full name if available
    if (_competition != null) {
      return _competition!.toString(); // This gives us "Name, Location Year"
    }

    // Fallback to processing _eventName
    if (_eventName != null) {
      return _eventName!;
    }

    // Default fallback
    return 'Event ${_getEventYear()}';
  }

  /// Sanitizes filename to remove invalid characters
  String _sanitizeFilename(String filename) {
    // Remove or replace characters that are invalid in filenames
    return filename
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '') // Remove invalid chars
        .replaceAll(RegExp(r'\s+'), ' ') // Replace multiple spaces with single space
        .trim(); // Remove leading/trailing spaces
  }

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

    _loadEventData();
  }

  Future<void> _loadEventData() async {
    try {
      // Try to get event data from public competitions API (since public APIs work correctly)
      final competitions = await api.getCompetitions();
      final eventIdInt = int.tryParse(_eventId ?? EVENTID.toString()) ?? EVENTID;
      final competition = competitions.firstWhere((comp) => comp.id == eventIdInt);

      setState(() {
        _competition = competition;
        _eventName ??= competition.getShortName();
      });
      // Successfully loaded event from competitions: ${competition.getShortName()}
    } catch (e) {
      // Failed to load event data: $e
      // Continue without competition data - will use fallbacks
    }

    // Load race results after event data
    _loadRaceResults();
  }

  Future<void> _loadRaceResults({bool isRefresh = false}) async {
    // Always fetch fresh data - no caching for public race results

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
      // Always use public API since it works correctly for both authenticated and non-authenticated users
      final results = await api.getPublicRaceResults(eventId: eventIdInt);

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

  /// Check if the race stage is a final round (uses backend determination)
  bool _isFinalStage(RaceResult raceResult) {
    return raceResult.isFinalRound ?? false;
  }

  /// Check if this is the last round where accumulated time should be shown
  /// Uses backend determination via showAccumulatedTime flag with fallback
  bool _isLastRound(RaceResult raceResult) {
    // If backend provides showAccumulatedTime flag, use it
    if (raceResult.showAccumulatedTime != null) {
      return raceResult.showAccumulatedTime!;
    }

    // Fallback logic if backend doesn't provide the flag yet
    final stage = raceResult.stage?.trim() ?? '';

    // Only show for "Round" stages that are final rounds
    if (stage.toLowerCase().contains('round') && (raceResult.isFinalRound ?? false)) {
      return true;
    }

    return false;
  }

  Future<void> _exportToPDF() async {
    if (_raceResults == null || _raceResults!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No race results to export')),
        );
      }
      return;
    }

    try {
      final pdf = pw.Document();

      // Prepare race results with sorted crew results
      final races = List<RaceResult>.from(_raceResults!);
      races.sort((a, b) => (a.raceNumber ?? 0).compareTo(b.raceNumber ?? 0));

      // Process each race to ensure proper positioning and sorting
      for (var race in races) {
        final crewResults = race.crewResults ?? [];
        final isFinal = _isFinalStage(race);
        _calculatePositions(crewResults, isFinalRound: isFinal);

        // Sort crew results
        if (isFinal) {
          crewResults.sort((a, b) {
            final aPos = a.position;
            final bPos = b.position;
            if (aPos == null && bPos == null) {
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
          crewResults.sort((a, b) {
            if (a.position == null && b.position == null) return 0;
            if (a.position == null) return 1;
            if (b.position == null) return -1;
            return a.position!.compareTo(b.position!);
          });
        }
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) => _buildPDFContent(races),
        ),
      );

      // Sanitize filename for different operating systems
      final sanitizedName = _sanitizeFilename('Race results for ${_getEventFullName()}');
      final fullFilename = '$sanitizedName.pdf';

      // Debug: Print the filename being used
      print('PDF filename: $fullFilename');

      final pdfBytes = await pdf.save();

      // Try sharePdf first (better filename support)
      try {
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: fullFilename,
        );
      } catch (shareError) {
        // Fallback to layoutPdf if sharePdf fails
        print('Share PDF failed, falling back to layout PDF: $shareError');
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
          name: fullFilename,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting PDF: $e')),
        );
      }
    }
  }

  List<pw.Widget> _buildPDFContent(List<RaceResult> races) {
    final widgets = <pw.Widget>[];

    // Header
    widgets.add(
      pw.Column(
        children: [
          pw.Text(
            _getEventFullName(),
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 20),
        ],
      ),
    );

    // Race results
    for (var race in races) {
      widgets.add(_buildPDFRaceSection(race));
      widgets.add(pw.SizedBox(height: 20));
    }

    return widgets;
  }

  pw.Widget _buildPDFRaceSection(RaceResult race) {
    final crewResults = race.crewResults ?? [];
    final isFinal = _isFinalStage(race);
    final isLastRound = _isLastRound(race);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Race header
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue800,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '#${race.raceNumber} ${race.raceTimeDisplay}',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  pw.Text(
                    race.stage ?? '',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                race.discipline?.getDisplayName() ?? 'Unknown',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              pw.Text(
                race.statusDisplay,
                style: pw.TextStyle(
                  color: PdfColors.grey300,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 8),

        // Crew results
        if (crewResults.isNotEmpty)
          ...crewResults.map((crew) => _buildPDFCrewResult(crew, race, isFinal, isLastRound))
        else
          pw.Padding(
            padding: const pw.EdgeInsets.all(16),
            child: pw.Text(
              'No crews registered for this race yet',
              style: pw.TextStyle(
                color: PdfColors.grey600,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  pw.Widget _buildPDFCrewResult(CrewResult crew, RaceResult race, bool isFinal, bool isLastRound) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: pw.Row(
        children: [
          // Position circle
          pw.Container(
            width: 36,
            height: 36,
            decoration: pw.BoxDecoration(
              color: _getPDFPositionColor(crew.position, isFinal),
              shape: pw.BoxShape.circle,
              border: isFinal
                ? null
                : pw.Border.all(color: _getPDFPositionColor(crew.position, false), width: 2),
            ),
            child: pw.Center(
              child: pw.Text(
                crew.position?.toString() ?? '-',
                style: pw.TextStyle(
                  color: isFinal ? PdfColors.white : _getPDFPositionColor(crew.position, false),
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          pw.SizedBox(width: 12),

          // Team name and lane
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  crew.crew?.team?.name ?? crew.team?.name ?? 'Unknown Team',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                ),
                if (crew.lane != null)
                  pw.Text(
                    'Lane ${crew.lane}',
                    style: pw.TextStyle(color: PdfColors.grey600, fontSize: 10),
                  ),
              ],
            ),
          ),

          // Times section
          if (isLastRound && isFinal && crew.hasFinalTime)
            // Two-column format for accumulated rounds
            pw.Row(
              children: [
                // Current round time
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: _getPDFStatusColor(crew.status),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        crew.displayTime,
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    if (crew.isFinished && crew.position != null && crew.position! > 1)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 2),
                        child: pw.Text(
                          _calculateCurrentRoundDelay(crew, race),
                          style: pw.TextStyle(color: PdfColors.grey600, fontSize: 9),
                        ),
                      ),
                  ],
                ),
                pw.SizedBox(width: 16),
                // Accumulated time
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: _getPDFStatusColor(crew.finalStatus ?? crew.status, isTotal: true),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        crew.displayFinalTime,
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    if (crew.isFinished && crew.position != null && crew.position! > 1)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 2),
                        child: pw.Text(
                          _calculateDelay(crew, race, isFinalRound: isFinal),
                          style: pw.TextStyle(color: PdfColors.grey600, fontSize: 9),
                        ),
                      ),
                  ],
                ),
              ],
            )
          else
            // Single time format
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: _getPDFStatusColor(crew.status),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    crew.displayTime,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
                if (crew.isFinished && crew.position != null && crew.position! > 1)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 2),
                    child: pw.Text(
                      _calculateDelay(crew, race, isFinalRound: isFinal),
                      style: pw.TextStyle(color: PdfColors.grey600, fontSize: 9),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  PdfColor _getPDFPositionColor(int? position, bool isFinal) {
    switch (position) {
      case 1:
        return PdfColors.amber; // Gold
      case 2:
        return PdfColors.grey; // Silver
      case 3:
        return PdfColors.brown; // Bronze
      default:
        return PdfColors.blue;
    }
  }

  PdfColor _getPDFStatusColor(String? status, {bool isTotal = false}) {
    PdfColor baseColor;
    switch (status) {
      case 'FINISHED':
        baseColor = PdfColors.green;
        break;
      case 'DNS':
        baseColor = PdfColors.orange;
        break;
      case 'DNF':
        baseColor = PdfColors.red;
        break;
      case 'DSQ':
        baseColor = PdfColors.purple;
        break;
      case null:
        baseColor = PdfColors.blue;
        break;
      default:
        baseColor = PdfColors.grey;
        break;
    }

    if (isTotal) {
      // Create a darker version of the color for total times
      switch (status) {
        case 'FINISHED':
          return PdfColors.green700;
        case 'DNS':
          return PdfColors.orange700;
        case 'DNF':
          return PdfColors.red700;
        case 'DSQ':
          return PdfColors.purple700;
        case null:
          return PdfColors.blue700;
        default:
          return PdfColors.grey700;
      }
    }
    return baseColor;
  }

  void _calculatePositions(List<CrewResult> crewResults, {bool isFinalRound = false}) {
    if (isFinalRound) {
      // For final rounds, use the backend-provided finalPosition
      // The backend calculates positions based on accumulated final times

      // Check if we have valid position data from backend
      final hasValidPositions = crewResults.any((crew) => crew.position != null);

      if (hasValidPositions) {
        // Use backend-provided positions - no need to change anything
        return;
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
      // Regular round logic - respect existing positions from database
      final hasValidPositions = crewResults.any((crew) => crew.position != null);

      if (hasValidPositions) {
        // Use backend-provided positions - no need to change anything
        return;
      }

      // Only calculate if no positions exist in database
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
                  _getEventFullName(),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left side: Expand/Collapse buttons
                    Row(
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
                        const SizedBox(width: 8),
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
                    // Right side: Export PDF button in green
                    ElevatedButton(
                      onPressed: _exportToPDF,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(80, 28),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        textStyle: const TextStyle(fontSize: 12),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Export PDF'),
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
          final isFinal = _isFinalStage(raceResult);
          _calculatePositions(crewResults, isFinalRound: isFinal);

          // Sort crew results based on position
          if (isFinal) {
            // For final rounds, sort by position (based on accumulated final times)
            crewResults.sort((a, b) {
              final aPos = a.position;
              final bPos = b.position;
              if (aPos == null && bPos == null) {
                // If both have no position, sort by final time if available
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
                    leading: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getEventTitle(),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getEventYear(),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '#${raceResult.raceNumber} ${raceResult.raceTimeDisplay}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${raceResult.stage}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          discipline?.getDisplayName() ?? 'Unknown',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
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
                      ...crewResults.map((crewResult) => _buildCrewResultItem(context, crewResult, raceResult, isFinal)),
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
        } catch (e) {
          // Error building race result item: $e
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getPositionBackgroundColor(crewResult.position, isFinalRound),
                  border: Border.all(
                    color: _getPositionBorderColor(crewResult.position, isFinalRound),
                    width: 2,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    crewResult.position?.toString() ?? '-',
                    style: TextStyle(
                      color: _getPositionTextColor(crewResult.position, isFinalRound),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
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
              // Time displays - show both current and accumulated for last round
              if (_isLastRound(raceResult))
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Current round time and delay (left side)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
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
                              _calculateCurrentRoundDelay(crewResult, raceResult),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Accumulated total time and delay (right side)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColorTotal(crewResult.finalStatus ?? crewResult.status),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            crewResult.displayFinalTime,
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
                              _calculateDelay(crewResult, raceResult, isFinalRound: isFinalRound),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                )
              else
                // Regular display for non-accumulated rounds
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
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
                          _calculateDelay(crewResult, raceResult, isFinalRound: isFinalRound),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
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
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _getPositionBackgroundColor(crewResult.position, isFinalRound),
                border: Border.all(
                  color: _getPositionBorderColor(crewResult.position, isFinalRound),
                  width: 2,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  crewResult.position?.toString() ?? '-',
                  style: TextStyle(
                    color: _getPositionTextColor(crewResult.position, isFinalRound),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
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


  String _calculateCurrentRoundDelay(CrewResult crewResult, RaceResult raceResult) {
    if (crewResult.position == null || crewResult.position == 1 || crewResult.timeMs == null) {
      return '';
    }

    // Always use current round times
    final firstPlaceTime = raceResult.crewResults
        ?.where((crew) => crew.position == 1 && crew.timeMs != null)
        .firstOrNull
        ?.timeMs;

    if (firstPlaceTime == null) return '';

    final delayMs = crewResult.timeMs! - firstPlaceTime;
    final delaySeconds = delayMs / 1000.0;

    return '+${delaySeconds.toStringAsFixed(2)}s';
  }

  String _calculateDelay(CrewResult crewResult, RaceResult raceResult, {bool isFinalRound = false}) {
    if (crewResult.position == null || crewResult.position == 1) {
      return '';
    }

    int? currentTime;
    int? firstPlaceTime;

    // Check if this is a round with accumulation (showAccumulatedTime is true)
    final isAccumulatedRound = _isLastRound(raceResult);

    if (isAccumulatedRound && crewResult.finalTimeMs != null) {
      // For accumulated rounds, use final times
      currentTime = crewResult.finalTimeMs;
      firstPlaceTime = raceResult.crewResults
          ?.where((crew) => crew.position == 1 && crew.finalTimeMs != null)
          .firstOrNull
          ?.finalTimeMs;
    } else if (crewResult.timeMs != null) {
      // For all other races (including regular Finals/Grand Finals), use current race times
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

  Color _getPositionBackgroundColor(int? position, bool isFinalRound) {
    if (isFinalRound) {
      return _getPositionColor(position);
    }
    return Colors.transparent; // Transparent background for non-final
  }

  Color _getPositionBorderColor(int? position, bool isFinalRound) {
    if (isFinalRound) {
      return Colors.transparent; // No border for final rounds
    }
    return _getPositionColor(position); // Border color for non-final
  }

  Color _getPositionTextColor(int? position, bool isFinalRound) {
    if (isFinalRound) {
      return Colors.white; // White text on colored background
    }
    return _getPositionColor(position); // Colored text on transparent background
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


  Color _getStatusColorTotal(String? status) {
    switch (status) {
      case 'FINISHED':
        return Colors.green.shade700;
      case 'DNS':
        return Colors.orange.shade700;
      case 'DNF':
        return Colors.red.shade700;
      case 'DSQ':
        return Colors.purple.shade700;
      case null:
        return Colors.blue.shade700; // Registered but no result yet
      default:
        return Colors.grey.shade700;
    }
  }
}