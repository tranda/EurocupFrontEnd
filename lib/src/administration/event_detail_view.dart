import 'package:eurocup_frontend/src/widgets.dart';
import 'package:eurocup_frontend/src/widgets/page_template.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;

import '../model/event/event.dart';

class EventDetailView extends StatefulWidget {
  const EventDetailView({super.key});

  static const routeName = '/event_detail';

  @override
  State<EventDetailView> createState() => _EventDetailViewState();
}

class _EventDetailViewState extends State<EventDetailView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _yearController = TextEditingController();
  final _standardReservesController = TextEditingController();
  final _standardMinGenderController = TextEditingController();
  final _standardMaxGenderController = TextEditingController();
  final _smallReservesController = TextEditingController();
  final _smallMinGenderController = TextEditingController();
  final _smallMaxGenderController = TextEditingController();
  
  DateTime? _nameEntriesLock;
  DateTime? _crewEntriesLock;
  DateTime? _raceEntriesLock;
  String _status = 'active';
  bool _isLoading = false;
  Competition? _event;
  bool _isEditMode = false;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Only initialize once
    if (!_isInitialized) {
      final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (arguments != null && arguments.containsKey('event')) {
        _event = arguments['event'] as Competition;
        _isEditMode = true;
        _populateForm();
      } else if (!_isEditMode) {
        // Set defaults for new event
        _setDefaults();
      }
      _isInitialized = true;
    }
  }
  
  void _setDefaults() {
    // Set current year as default
    _yearController.text = DateTime.now().year.toString();
    
    // Set configuration defaults to 0
    _standardReservesController.text = '0';
    _standardMinGenderController.text = '0';
    _standardMaxGenderController.text = '0';
    _smallReservesController.text = '0';
    _smallMinGenderController.text = '0';
    _smallMaxGenderController.text = '0';
    
    // Set lock dates to current date/time
    final now = DateTime.now();
    _nameEntriesLock = now;
    _crewEntriesLock = now;
    _raceEntriesLock = now;
  }

  void _populateForm() {
    if (_event != null) {
      _nameController.text = _event!.name ?? '';
      _locationController.text = _event!.location ?? '';
      _yearController.text = _event!.year?.toString() ?? '';
      _standardReservesController.text = _event!.standardReserves?.toString() ?? '';
      _standardMinGenderController.text = _event!.standardMinGender?.toString() ?? '';
      _standardMaxGenderController.text = _event!.standardMaxGender?.toString() ?? '';
      _smallReservesController.text = _event!.smallReserves?.toString() ?? '';
      _smallMinGenderController.text = _event!.smallMinGender?.toString() ?? '';
      _smallMaxGenderController.text = _event!.smallMaxGender?.toString() ?? '';
      _nameEntriesLock = _event!.nameEntriesLock;
      _crewEntriesLock = _event!.crewEntriesLock;
      _raceEntriesLock = _event!.raceEntriesLock;
      _status = _event!.status ?? 'active';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _yearController.dispose();
    _standardReservesController.dispose();
    _standardMinGenderController.dispose();
    _standardMaxGenderController.dispose();
    _smallReservesController.dispose();
    _smallMinGenderController.dispose();
    _smallMaxGenderController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(String type) async {
    DateTime? currentDate;
    switch (type) {
      case 'name':
        currentDate = _nameEntriesLock;
        break;
      case 'crew':
        currentDate = _crewEntriesLock;
        break;
      case 'race':
        currentDate = _raceEntriesLock;
        break;
    }
    
    // Use current date if available, otherwise use a default future date
    final initialDate = currentDate ?? DateTime.now().add(const Duration(days: 30));
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    
    if (picked != null && picked != currentDate) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(currentDate ?? DateTime.now()),
      );
      
      if (pickedTime != null) {
        final newDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        
        setState(() {
          switch (type) {
            case 'name':
              _nameEntriesLock = newDateTime;
              break;
            case 'crew':
              _crewEntriesLock = newDateTime;
              break;
            case 'race':
              _raceEntriesLock = newDateTime;
              break;
          }
        });
      } else {
        // If time picker was cancelled but date was selected, still update with picked date at current time
        final now = TimeOfDay.now();
        final newDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          now.hour,
          now.minute,
        );
        
        setState(() {
          switch (type) {
            case 'name':
              _nameEntriesLock = newDateTime;
              break;
            case 'crew':
              _crewEntriesLock = newDateTime;
              break;
            case 'race':
              _raceEntriesLock = newDateTime;
              break;
          }
        });
      }
    }
  }
  
  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Not set';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildDateTimeSelector(String label, DateTime? dateTime, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
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
          suffixIcon: const Icon(Icons.calendar_today, color: Color.fromARGB(255, 0, 80, 150)),
        ),
        child: Text(
          _formatDateTime(dateTime),
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final event = Competition(
        id: _event?.id,
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        year: int.parse(_yearController.text.trim()),
        status: _status,
        standardReserves: _standardReservesController.text.trim().isEmpty
          ? null : int.tryParse(_standardReservesController.text.trim()),
        standardMinGender: _standardMinGenderController.text.trim().isEmpty
          ? null : int.tryParse(_standardMinGenderController.text.trim()),
        standardMaxGender: _standardMaxGenderController.text.trim().isEmpty
          ? null : int.tryParse(_standardMaxGenderController.text.trim()),
        smallReserves: _smallReservesController.text.trim().isEmpty
          ? null : int.tryParse(_smallReservesController.text.trim()),
        smallMinGender: _smallMinGenderController.text.trim().isEmpty
          ? null : int.tryParse(_smallMinGenderController.text.trim()),
        smallMaxGender: _smallMaxGenderController.text.trim().isEmpty
          ? null : int.tryParse(_smallMaxGenderController.text.trim()),
        nameEntriesLock: _nameEntriesLock,
        crewEntriesLock: _crewEntriesLock,
        raceEntriesLock: _raceEntriesLock,
      );

      if (_isEditMode) {
        await api.updateEvent(event);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event updated successfully')),
          );
        }
      } else {
        await api.createEvent(event);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event created successfully')),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving event: $error')),
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
      appBar: appBar(title: _isEditMode ? 'Edit Event' : 'Create Event'),
      body: Container(
        decoration: bckDecoration(),
        child: Stack(
          children: [
            Form(
              key: _formKey,
              child: ListView(
                children: [
                  // Basic Information Section Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.white,
                    child: Text(
                      'Basic Information',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Event Name
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey, width: 0.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Event Name',
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
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an event name';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),

                  // Location
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey, width: 0.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: 'Location',
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
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a location';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),

                  // Year and Status
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey, width: 0.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _yearController,
                              decoration: InputDecoration(
                                labelText: 'Year',
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
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a year';
                                }
                                final year = int.tryParse(value.trim());
                                if (year == null || year < 2020 || year > 2050) {
                                  return 'Please enter a valid year (2020-2050)';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _status,
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
                              items: const [
                                DropdownMenuItem(value: 'active', child: Text('Active')),
                                DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _status = value ?? 'active';
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Entry Lock Dates Section Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.white,
                    child: Text(
                      'Entry Lock Dates',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Name Entries Lock
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey, width: 0.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: _buildDateTimeSelector(
                        'Name Entries Lock',
                        _nameEntriesLock,
                        () => _selectDate('name'),
                      ),
                    ),
                  ),

                  // Crew Entries Lock
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey, width: 0.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: _buildDateTimeSelector(
                        'Crew Entries Lock',
                        _crewEntriesLock,
                        () => _selectDate('crew'),
                      ),
                    ),
                  ),

                  // Race Entries Lock
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey, width: 0.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: _buildDateTimeSelector(
                        'Race Entries Lock',
                        _raceEntriesLock,
                        () => _selectDate('race'),
                      ),
                    ),
                  ),

                  // Standard Boat Configuration Section Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.white,
                    child: Text(
                      'Standard Boat Configuration',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Standard Boat Fields (all in one row)
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey, width: 0.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _standardReservesController,
                              decoration: InputDecoration(
                                labelText: 'Reserves',
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
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value != null && value.trim().isNotEmpty) {
                                  final number = int.tryParse(value.trim());
                                  if (number == null || number < 0) {
                                    return 'Please enter a valid positive number';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _standardMinGenderController,
                              decoration: InputDecoration(
                                labelText: 'Min Gender',
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
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value != null && value.trim().isNotEmpty) {
                                  final number = int.tryParse(value.trim());
                                  if (number == null || number < 0) {
                                    return 'Please enter a valid positive number';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _standardMaxGenderController,
                              decoration: InputDecoration(
                                labelText: 'Max Gender',
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
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value != null && value.trim().isNotEmpty) {
                                  final number = int.tryParse(value.trim());
                                  if (number == null || number < 0) {
                                    return 'Please enter a valid positive number';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Small Boat Configuration Section Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.white,
                    child: Text(
                      'Small Boat Configuration',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Small Boat Fields (all in one row)
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey, width: 0.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _smallReservesController,
                              decoration: InputDecoration(
                                labelText: 'Reserves',
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
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value != null && value.trim().isNotEmpty) {
                                  final number = int.tryParse(value.trim());
                                  if (number == null || number < 0) {
                                    return 'Please enter a valid positive number';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _smallMinGenderController,
                              decoration: InputDecoration(
                                labelText: 'Min Gender',
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
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value != null && value.trim().isNotEmpty) {
                                  final number = int.tryParse(value.trim());
                                  if (number == null || number < 0) {
                                    return 'Please enter a valid positive number';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _smallMaxGenderController,
                              decoration: InputDecoration(
                                labelText: 'Max Gender',
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
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value != null && value.trim().isNotEmpty) {
                                  final number = int.tryParse(value.trim());
                                  if (number == null || number < 0) {
                                    return 'Please enter a valid positive number';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Save Button
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: longButtons(
                      _isEditMode ? 'Update Event' : 'Create Event',
                      _saveEvent,
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