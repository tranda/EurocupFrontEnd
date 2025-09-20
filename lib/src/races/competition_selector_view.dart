import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:eurocup_frontend/src/races/race_results_list_view.dart';

class CompetitionSelectorView extends StatefulWidget {
  const CompetitionSelectorView({super.key});

  static const routeName = '/results';

  @override
  State<CompetitionSelectorView> createState() => _CompetitionSelectorViewState();
}

class _CompetitionSelectorViewState extends State<CompetitionSelectorView> {
  String? selectedEventId;
  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, String>> _getAvailableEvents() {
    if (competitions.isEmpty) {
      return [
        {"id": "1", "name": "EuroCup 2023"},
        {"id": "8", "name": "National Championship 2025"},
      ];
    }

    return competitions.map((competition) => {
      "id": competition.id.toString(),
      "name": "${competition.name} ${competition.year}, ${competition.location}",
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    competitions = [];
    api.getCompetitions().then((_) {
      // After competitions are loaded, update the UI and set default selection
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Set default to EVENTID if it exists in competitions, otherwise first competition
          if (competitions.isNotEmpty) {
            final defaultCompetition = competitions.firstWhere(
              (comp) => comp.id == EVENTID,
              orElse: () => competitions.first,
            );
            selectedEventId = defaultCompetition.id.toString();
          }
        });
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load competitions';
        });
      }
    });
  }

  void _viewResults() {
    if (selectedEventId != null) {
      Navigator.pushNamed(
        context,
        RaceResultsListView.routeName,
        arguments: {
          'eventId': selectedEventId,
          'eventName': competitions.firstWhere((c) => c.id.toString() == selectedEventId, orElse: () => competitions.first).getShortName(),
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableEvents = _getAvailableEvents();

    return Scaffold(
      appBar: appBar(title: 'Race Results'),
      body: Container(
        decoration: naslovnaDecoration(),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              margin: const EdgeInsets.all(16),
              child: Card(
                elevation: 8,
                color: Colors.blue.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      // Title
                      Text(
                        'Race Results',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select a competition to view live results',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Competition Selection
                      if (_isLoading)
                        const CircularProgressIndicator()
                      else if (_errorMessage != null)
                        Column(
                          children: [
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _isLoading = true;
                                  _errorMessage = null;
                                });
                                initState();
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Competition Dropdown - matching login page style
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: availableEvents.any((event) => event['id'] == selectedEventId)
                                      ? selectedEventId
                                      : availableEvents.isNotEmpty ? availableEvents.first['id'] : "1",
                                  isExpanded: true,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                  ),
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Colors.black54,
                                  ),
                                  items: availableEvents.map((event) {
                                    return DropdownMenuItem<String>(
                                      value: event['id'],
                                      child: Text(event['name']!),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedEventId = value;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // View Results Button
                            ElevatedButton(
                              onPressed: selectedEventId != null ? _viewResults : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: selectedEventId != null
                                    ? competitionColor[(int.tryParse(selectedEventId ?? '1') ?? 1) - 1]
                                    : Colors.grey,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text(
                                'View Race Results',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}