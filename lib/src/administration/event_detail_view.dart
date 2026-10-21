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
  bool _available = true;
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
      _available = _event!.available ?? true;
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
        decoration: pageFieldDecoration(label).copyWith(
          suffixIcon: const Icon(Icons.calendar_today, color: pageBlue),
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

  String? _validateNonNegative(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      final number = int.tryParse(value.trim());
      if (number == null || number < 0) {
        return 'Please enter a valid positive number';
      }
    }
    return null;
  }

  Widget _numberField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: pageFieldDecoration(label),
      style: const TextStyle(color: Colors.black87, fontSize: 16),
      keyboardType: TextInputType.number,
      validator: _validateNonNegative,
    );
  }

  Widget _boatConfigRow(TextEditingController reserves, TextEditingController minGender,
      TextEditingController maxGender) {
    return Row(
      children: [
        Expanded(child: _numberField(reserves, 'Reserves')),
        const SizedBox(width: 12),
        Expanded(child: _numberField(minGender, 'Min Gender')),
        const SizedBox(width: 12),
        Expanded(child: _numberField(maxGender, 'Max Gender')),
      ],
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
        available: _available,
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
    final eventId = _event?.id;
    final title = _isEditMode && (_event?.name ?? '').isNotEmpty ? _event!.name! : 'New event';
    final subtitleParts = <String>[
      if ((_event?.location ?? '').isNotEmpty) _event!.location!,
      if (_event?.year != null) _event!.year.toString(),
    ];

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
                  PageTitleBlock(
                    title: title,
                    children: [
                      if (subtitleParts.isNotEmpty)
                        Text(
                          subtitleParts.join(' · '),
                          style: const TextStyle(color: pageBlue, fontSize: 16, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),

                  // Basic information
                  ColoredPageHeader(title: 'Basic information', eventId: eventId),
                  _section([
                    TextFormField(
                      controller: _nameController,
                      decoration: pageFieldDecoration('Event Name'),
                      style: const TextStyle(color: Colors.black87, fontSize: 16),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an event name';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _locationController,
                      decoration: pageFieldDecoration('Location'),
                      style: const TextStyle(color: Colors.black87, fontSize: 16),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a location';
                        }
                        return null;
                      },
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _yearController,
                            decoration: pageFieldDecoration('Year'),
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _status,
                            decoration: pageFieldDecoration('Status'),
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
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.grey, width: 1.0),
                      ),
                      child: SwitchListTile(
                        title: const Text(
                          'Available',
                          style: TextStyle(
                            color: pageBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          _available
                            ? 'Event is visible in public views'
                            : 'Event is hidden from public views (admin only)',
                          style: TextStyle(
                            fontSize: 12,
                            color: _available ? Colors.teal.shade700 : Colors.red.shade700,
                          ),
                        ),
                        value: _available,
                        onChanged: (bool value) {
                          setState(() {
                            _available = value;
                          });
                        },
                      ),
                    ),
                  ]),
                  pageSectionGap,

                  // Entry lock dates
                  ColoredPageHeader(title: 'Entry lock dates', eventId: eventId),
                  _section([
                    _buildDateTimeSelector(
                      'Name Entries Lock',
                      _nameEntriesLock,
                      () => _selectDate('name'),
                    ),
                    _buildDateTimeSelector(
                      'Crew Entries Lock',
                      _crewEntriesLock,
                      () => _selectDate('crew'),
                    ),
                    _buildDateTimeSelector(
                      'Race Entries Lock',
                      _raceEntriesLock,
                      () => _selectDate('race'),
                    ),
                  ]),
                  pageSectionGap,

                  // Standard boat configuration
                  ColoredPageHeader(title: 'Standard boat configuration', eventId: eventId),
                  _section([
                    _boatConfigRow(
                      _standardReservesController,
                      _standardMinGenderController,
                      _standardMaxGenderController,
                    ),
                  ]),
                  pageSectionGap,

                  // Small boat configuration
                  ColoredPageHeader(title: 'Small boat configuration', eventId: eventId),
                  _section([
                    _boatConfigRow(
                      _smallReservesController,
                      _smallMinGenderController,
                      _smallMaxGenderController,
                    ),
                  ]),
                  pageSectionGap,

                  // Save Button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveEvent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pageBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          _isEditMode ? 'Update Event' : 'Create Event',
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
