import 'package:eurocup_frontend/src/widgets.dart';
import 'package:eurocup_frontend/src/widgets/page_template.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;

import '../model/race/discipline.dart';
import '../model/event/event.dart';
import '../common.dart';

class DisciplineDetailView extends StatefulWidget {
  const DisciplineDetailView({super.key});

  static const routeName = '/discipline_detail';

  @override
  State<DisciplineDetailView> createState() => _DisciplineDetailViewState();
}

class _DisciplineDetailViewState extends State<DisciplineDetailView> {
  final _formKey = GlobalKey<FormState>();
  final _distanceController = TextEditingController();
  final _competitionController = TextEditingController();

  Competition? _selectedEvent;
  String _selectedAgeGroup = 'Junior';  // First item in disciplineAgeGroups
  String _selectedGenderGroup = 'Mixed';  // First item in disciplineGenderGroups
  String _selectedBoatGroup = 'Standard';  // First item in disciplineBoatGroups
  String _selectedStatus = 'active';  // First item in disciplineStatusOptions
  
  bool _isLoading = false;
  Discipline? _discipline;
  List<Competition> _events = [];
  bool _isEditMode = false;
  bool _didInitialize = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Only read route arguments and populate the form once. didChangeDependencies
    // re-fires on route status changes (e.g. opening/closing a dropdown), and
    // re-running _populateForm() would silently revert the user's edits.
    if (_didInitialize) return;
    _didInitialize = true;

    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      if (arguments.containsKey('events')) {
        _events = arguments['events'] as List<Competition>;
      }
      
      if (arguments.containsKey('discipline')) {
        _discipline = arguments['discipline'] as Discipline;
        _isEditMode = true;
        _populateForm();
      } else if (arguments.containsKey('selectedEvent')) {
        // Pre-select the event when creating a new discipline
        _selectedEvent = arguments['selectedEvent'] as Competition?;
      }
    }
  }

  void _populateForm() {
    if (_discipline != null) {
      _distanceController.text = _discipline!.distance?.toString() ?? '';
      _competitionController.text = _discipline!.competition ?? '';
      
      // Find the matching event
      if (_discipline!.eventId != null) {
        try {
          _selectedEvent = _events.firstWhere(
            (event) => event.id == _discipline!.eventId,
          );
        } catch (e) {
          _selectedEvent = _events.isNotEmpty ? _events.first : null;
        }
      }
      
      // Ensure values match the predefined options exactly
      _selectedAgeGroup = disciplineAgeGroups.contains(_discipline!.ageGroup) 
        ? _discipline!.ageGroup! 
        : 'Junior';
      
      _selectedGenderGroup = disciplineGenderGroups.contains(_discipline!.genderGroup)
        ? _discipline!.genderGroup!
        : 'Mixed';
        
      _selectedBoatGroup = disciplineBoatGroups.contains(_discipline!.boatGroup)
        ? _discipline!.boatGroup!
        : 'Standard';
        
      _selectedStatus = disciplineStatusOptions.contains(_discipline!.status)
        ? _discipline!.status!
        : 'active';
    }
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _competitionController.dispose();
    super.dispose();
  }

  Future<void> _saveDiscipline() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final discipline = Discipline(
        id: _discipline?.id,
        eventId: _selectedEvent?.id,
        distance: int.parse(_distanceController.text.trim()),
        ageGroup: _selectedAgeGroup,
        genderGroup: _selectedGenderGroup,
        boatGroup: _selectedBoatGroup,
        competition: _competitionController.text.trim().isEmpty
            ? null
            : _competitionController.text.trim(),
        status: _selectedStatus,
      );

      if (_isEditMode) {
        await api.updateDiscipline(discipline);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Discipline updated successfully')),
          );
        }
      } else {
        await api.createDiscipline(discipline);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Discipline created successfully')),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving discipline: $error')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Section body: fields with consistent 12px gaps.
  Widget _section(List<Widget> fields) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < fields.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            fields[i],
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventId = _selectedEvent?.id ?? _discipline?.eventId;
    final title = _isEditMode && _discipline != null ? _discipline!.getDisplayName() : 'New discipline';
    final eventName = _selectedEvent?.name ?? '';

    return Scaffold(
      appBar: appBar(title: _isEditMode ? 'Edit Discipline' : 'Create Discipline'),
      body: Container(
        decoration: bckDecoration(),
        child: Stack(
          children: [
            Form(
              key: _formKey,
              child: ListView(
                children: [
                  PageTitleBlock(
                    title: title,
                    children: [
                      if (eventName.isNotEmpty)
                        Text(
                          eventName,
                          style: const TextStyle(color: pageBlue, fontSize: 16, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),

                  ColoredPageHeader(title: 'Discipline details', eventId: eventId),
                  _section([
                    DropdownButtonFormField<String>(
                      value: _selectedBoatGroup,
                      decoration: pageFieldDecoration('Boat Group'),
                      style: const TextStyle(color: Colors.black87, fontSize: 16),
                      dropdownColor: Colors.white,
                      items: disciplineBoatGroups.map((boatGroup) => DropdownMenuItem<String>(
                        value: boatGroup,
                        child: Text(boatGroup),
                      )).toList(),
                      onChanged: (String? boatGroup) {
                        setState(() {
                          _selectedBoatGroup = boatGroup ?? 'Standard';
                        });
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: _selectedAgeGroup,
                      decoration: pageFieldDecoration('Age Group'),
                      style: const TextStyle(color: Colors.black87, fontSize: 16),
                      dropdownColor: Colors.white,
                      items: disciplineAgeGroups.map((ageGroup) => DropdownMenuItem<String>(
                        value: ageGroup,
                        child: Text(ageGroup),
                      )).toList(),
                      onChanged: (String? ageGroup) {
                        setState(() {
                          _selectedAgeGroup = ageGroup ?? 'Junior';
                        });
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: _selectedGenderGroup,
                      decoration: pageFieldDecoration('Gender Group'),
                      style: const TextStyle(color: Colors.black87, fontSize: 16),
                      dropdownColor: Colors.white,
                      items: disciplineGenderGroups.map((genderGroup) => DropdownMenuItem<String>(
                        value: genderGroup,
                        child: Text(genderGroup),
                      )).toList(),
                      onChanged: (String? genderGroup) {
                        setState(() {
                          _selectedGenderGroup = genderGroup ?? 'Mixed';
                        });
                      },
                    ),
                    DropdownButtonFormField<int>(
                      value: _distanceController.text.isNotEmpty
                        ? int.tryParse(_distanceController.text)
                        : null,
                      decoration: pageFieldDecoration('Distance (meters)'),
                      style: const TextStyle(color: Colors.black87, fontSize: 16),
                      dropdownColor: Colors.white,
                      items: disciplineDistanceOptions.map((distance) => DropdownMenuItem<int>(
                        value: distance,
                        child: Text('${distance}m'),
                      )).toList(),
                      onChanged: (int? distance) {
                        if (distance != null) {
                          _distanceController.text = distance.toString();
                        }
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a distance';
                        }
                        return null;
                      },
                    ),
                  ]),
                  pageSectionGap,

                  ColoredPageHeader(title: 'Competition and status', eventId: eventId),
                  _section([
                    TextFormField(
                      controller: _competitionController,
                      textCapitalization: TextCapitalization.words,
                      decoration: pageFieldDecoration('Competition (optional)').copyWith(
                        hintText: 'e.g. Club, Corporate',
                      ),
                      style: const TextStyle(color: Colors.black87, fontSize: 16),
                    ),
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: pageFieldDecoration('Status'),
                      style: const TextStyle(color: Colors.black87, fontSize: 16),
                      dropdownColor: Colors.white,
                      items: disciplineStatusOptions.map((status) => DropdownMenuItem<String>(
                        value: status,
                        child: Text(status.toUpperCase()),
                      )).toList(),
                      onChanged: (String? status) {
                        setState(() {
                          _selectedStatus = status ?? 'active';
                        });
                      },
                    ),
                  ]),
                  pageSectionGap,

                  // Button Section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveDiscipline,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pageBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          _isEditMode ? 'Update Discipline' : 'Create Discipline',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading) busyOverlay(context),
          ],
        ),
      ),
    );
  }
}
