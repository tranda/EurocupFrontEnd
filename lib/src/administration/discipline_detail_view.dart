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
  
  Competition? _selectedEvent;
  String _selectedAgeGroup = 'Junior';  // First item in disciplineAgeGroups
  String _selectedGenderGroup = 'Mixed';  // First item in disciplineGenderGroups
  String _selectedBoatGroup = 'Standard';  // First item in disciplineBoatGroups
  String _selectedStatus = 'active';  // First item in disciplineStatusOptions
  
  bool _isLoading = false;
  Discipline? _discipline;
  List<Competition> _events = [];
  bool _isEditMode = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
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

  @override
  Widget build(BuildContext context) {
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
                  // Form Fields

                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: DropdownButtonFormField<String>(
                        value: _selectedBoatGroup,
                        decoration: InputDecoration(
                          labelText: 'Boat Group',
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
                    ),
                  ),

                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: DropdownButtonFormField<String>(
                        value: _selectedAgeGroup,
                        decoration: InputDecoration(
                          labelText: 'Age Group',
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
                    ),
                  ),

                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: DropdownButtonFormField<String>(
                        value: _selectedGenderGroup,
                        decoration: InputDecoration(
                          labelText: 'Gender Group',
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
                    ),
                  ),

                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: DropdownButtonFormField<int>(
                        value: _distanceController.text.isNotEmpty
                          ? int.tryParse(_distanceController.text)
                          : null,
                        decoration: InputDecoration(
                          labelText: 'Distance (meters)',
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
                    ),
                  ),

                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Status',
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
                    ),
                  ),

                  // Button Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: longButtons(
                      _isEditMode ? 'Update Discipline' : 'Create Discipline',
                      _saveDiscipline,
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