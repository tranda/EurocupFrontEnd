import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:eurocup_frontend/src/widgets/page_template.dart';
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

    // Sort competitions by year in descending order (newest first)
    final sortedCompetitions = List<Competition>.from(competitions);
    sortedCompetitions.sort((a, b) {
      final yearA = a.year ?? 0;
      final yearB = b.year ?? 0;
      return yearB.compareTo(yearA);
    });

    return sortedCompetitions.map((competition) => {
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
          // Set default to first active competition, otherwise first competition
          if (competitions.isNotEmpty) {
            final defaultCompetition = competitions.firstWhere(
              (comp) => comp.isActive,
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
        '${RaceResultsListView.routeName}?eventId=$selectedEventId',
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
        // Fill the screen even when the content is short.
        height: double.infinity,
        decoration: bckDecoration(),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const MenuBanner(),
            PageTitleBlock(
              title: 'Race Results',
              children: [
                Text(
                  'Select a competition to view live results',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                      ),
                ),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
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
                else ...[
                  // Competition Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: availableEvents.any((event) => event['id'] == selectedEventId)
                        ? selectedEventId
                        : availableEvents.isNotEmpty ? availableEvents.first['id'] : "1",
                    isExpanded: true,
                    decoration: pageFieldDecoration('Select Event'),
                    style: const TextStyle(color: Colors.black87, fontSize: 16),
                    dropdownColor: Colors.white,
                    items: availableEvents.map((event) {
                      return DropdownMenuItem<String>(
                        value: event['id'],
                        child: Text(event['name']!, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedEventId = value;
                      });
                    },
                  ),

                  // View Results Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selectedEventId != null ? _viewResults : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pageBlue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
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
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}