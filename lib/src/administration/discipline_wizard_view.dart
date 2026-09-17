import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;

/// Wizard that generates every combination of the selected boat groups,
/// age categories, genders and distances for one event in a single pass.
/// Combinations that already exist for the event are detected and skipped.
class DisciplineWizardView extends StatefulWidget {
  const DisciplineWizardView({super.key});

  static const routeName = '/discipline_wizard';

  @override
  State<DisciplineWizardView> createState() => _DisciplineWizardViewState();
}

class _DisciplineWizardViewState extends State<DisciplineWizardView> {
  static const _headerColor = Color.fromARGB(255, 0, 80, 150);

  final _competitionController = TextEditingController();

  Competition? _selectedEvent;
  List<Competition> _events = [];
  List<Discipline> _allDisciplines = [];

  final Set<String> _selectedBoatGroups = {};
  final Set<String> _selectedAgeGroups = {};
  final Set<String> _selectedGenderGroups = {};
  final Set<int> _selectedDistances = {};

  /// Keys of previewed (non-existing) combinations the user has unticked.
  final Set<String> _deselectedKeys = {};

  bool _isCreating = false;
  int _createdCount = 0;
  int _totalToCreate = 0;
  bool _didInitialize = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitialize) return;
    _didInitialize = true;

    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      if (arguments.containsKey('events')) {
        _events = arguments['events'] as List<Competition>;
      }
      if (arguments.containsKey('disciplines')) {
        _allDisciplines = arguments['disciplines'] as List<Discipline>;
      }
      if (arguments['selectedEvent'] is Competition) {
        _selectedEvent = arguments['selectedEvent'] as Competition;
      }
    }
  }

  @override
  void dispose() {
    _competitionController.dispose();
    super.dispose();
  }

  // --- Combination helpers -------------------------------------------------

  /// Dedup key for a combination. Competition is intentionally ignored so a
  /// combination is treated as "existing" regardless of its competition value.
  String _comboKey(String boat, String age, String gender, int distance) =>
      '${boat.toLowerCase()}|${age.toLowerCase()}|'
      '${gender.toLowerCase()}|$distance';

  /// Keys of disciplines that already exist for the selected event.
  Set<String> get _existingKeys {
    if (_selectedEvent == null) return {};
    return _allDisciplines
        .where((d) => d.eventId == _selectedEvent!.id)
        .map((d) => _comboKey(
              d.boatGroup ?? '',
              d.ageGroup ?? '',
              d.genderGroup ?? '',
              d.distance ?? -1,
            ))
        .toSet();
  }

  /// Every selected combination, in a stable display order.
  List<_Combo> get _allCombos {
    final combos = <_Combo>[];
    final boats =
        disciplineBoatGroups.where(_selectedBoatGroups.contains).toList();
    final ages =
        disciplineAgeGroups.where(_selectedAgeGroups.contains).toList();
    final genders =
        disciplineGenderGroups.where(_selectedGenderGroups.contains).toList();
    final distances =
        disciplineDistanceOptions.where(_selectedDistances.contains).toList();

    for (final boat in boats) {
      for (final age in ages) {
        for (final gender in genders) {
          for (final distance in distances) {
            combos.add(_Combo(
              boatGroup: boat,
              ageGroup: age,
              genderGroup: gender,
              distance: distance,
              key: _comboKey(boat, age, gender, distance),
            ));
          }
        }
      }
    }
    return combos;
  }

  /// Combinations that will actually be created (new + not unticked).
  List<_Combo> get _combosToCreate {
    final existing = _existingKeys;
    return _allCombos
        .where((c) => !existing.contains(c.key) && !_deselectedKeys.contains(c.key))
        .toList();
  }

  // --- Creation ------------------------------------------------------------

  Future<void> _createDisciplines() async {
    final toCreate = _combosToCreate;
    if (toCreate.isEmpty || _selectedEvent == null) return;

    final competition = _competitionController.text.trim();
    setState(() {
      _isCreating = true;
      _createdCount = 0;
      _totalToCreate = toCreate.length;
    });

    final failures = <String>[];
    for (final combo in toCreate) {
      try {
        await api.createDiscipline(Discipline(
          eventId: _selectedEvent!.id,
          distance: combo.distance,
          ageGroup: combo.ageGroup,
          genderGroup: combo.genderGroup,
          boatGroup: combo.boatGroup,
          competition: competition.isEmpty ? null : competition,
          status: 'active',
        ));
      } catch (e) {
        failures.add(combo.displayName);
      }
      if (mounted) setState(() => _createdCount++);
    }

    if (!mounted) return;
    setState(() => _isCreating = false);

    final created = toCreate.length - failures.length;
    await _showSummaryDialog(created: created, failures: failures);
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _showSummaryDialog(
      {required int created, required List<String> failures}) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wizard complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Created $created discipline${created == 1 ? '' : 's'}.'),
            if (failures.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('${failures.length} failed:',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...failures.take(10).map((f) => Text('• $f',
                  style: const TextStyle(fontSize: 13, color: Colors.red))),
              if (failures.length > 10)
                Text('… and ${failures.length - 10} more',
                    style: const TextStyle(fontSize: 13, color: Colors.red)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // --- UI ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final combos = _allCombos;
    final existing = _existingKeys;
    final toCreateCount = _combosToCreate.length;
    final existingCount = combos.where((c) => existing.contains(c.key)).length;

    return Scaffold(
      appBar: appBar(title: 'Discipline Wizard'),
      body: Container(
        decoration: bckDecoration(),
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _eventSelector(),
                _multiSelectSection<String>(
                  title: 'Boat Groups',
                  options: disciplineBoatGroups,
                  selected: _selectedBoatGroups,
                  label: (v) => v,
                ),
                _multiSelectSection<String>(
                  title: 'Age Categories',
                  options: disciplineAgeGroups,
                  selected: _selectedAgeGroups,
                  label: (v) => v,
                ),
                _multiSelectSection<String>(
                  title: 'Genders',
                  options: disciplineGenderGroups,
                  selected: _selectedGenderGroups,
                  label: (v) => v,
                ),
                _multiSelectSection<int>(
                  title: 'Distances',
                  options: disciplineDistanceOptions,
                  selected: _selectedDistances,
                  label: (v) => '${v}m',
                ),
                _competitionField(),
                _previewSection(combos, existing, toCreateCount, existingCount),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: longButtons(
                    toCreateCount == 0
                        ? 'Nothing to create'
                        : 'Create $toCreateCount discipline${toCreateCount == 1 ? '' : 's'}',
                    (toCreateCount == 0 || _selectedEvent == null)
                        ? () {}
                        : _createDisciplines,
                    color: (toCreateCount == 0 || _selectedEvent == null)
                        ? Colors.grey
                        : Colors.blue,
                  ),
                ),
              ],
            ),
            if (_isCreating) _creatingOverlay(context),
          ],
        ),
      ),
    );
  }

  Widget _sectionContainer({required Widget child}) => Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: child,
        ),
      );

  Widget _eventSelector() => _sectionContainer(
        child: DropdownButtonFormField<Competition>(
          value: _selectedEvent,
          decoration: _inputDecoration('Event'),
          style: const TextStyle(color: Colors.black87, fontSize: 16),
          dropdownColor: Colors.white,
          isExpanded: true,
          items: _events
              .map((e) => DropdownMenuItem<Competition>(
                    value: e,
                    child: Text('${e.name} ${e.year}'),
                  ))
              .toList(),
          onChanged: (e) => setState(() {
            _selectedEvent = e;
            _deselectedKeys.clear();
          }),
          validator: (v) => v == null ? 'Please select an event' : null,
        ),
      );

  Widget _multiSelectSection<T>({
    required String title,
    required List<T> options,
    required Set<T> selected,
    required String Function(T) label,
  }) {
    final allSelected = selected.length == options.length;
    return _sectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _headerColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  if (allSelected) {
                    selected.clear();
                  } else {
                    selected
                      ..clear()
                      ..addAll(options);
                  }
                  _deselectedKeys.clear();
                }),
                child: Text(allSelected ? 'Clear' : 'Select all'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: options.map((option) {
              final isSelected = selected.contains(option);
              return FilterChip(
                label: Text(label(option)),
                selected: isSelected,
                showCheckmark: true,
                selectedColor: _headerColor.withValues(alpha: 0.15),
                checkmarkColor: _headerColor,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? _headerColor : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected ? _headerColor : Colors.grey,
                  ),
                ),
                onSelected: (value) => setState(() {
                  if (value) {
                    selected.add(option);
                  } else {
                    selected.remove(option);
                  }
                  _deselectedKeys.clear();
                }),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _competitionField() => _sectionContainer(
        child: TextFormField(
          controller: _competitionController,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
          decoration: _inputDecoration('Competition (optional)').copyWith(
            hintText: 'Applied to all generated disciplines',
          ),
          style: const TextStyle(color: Colors.black87, fontSize: 16),
        ),
      );

  Widget _previewSection(List<_Combo> combos, Set<String> existing,
      int toCreateCount, int existingCount) {
    return _sectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Preview',
                style: TextStyle(
                  color: _headerColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              Text(
                '$toCreateCount to create'
                '${existingCount > 0 ? ' · $existingCount exist' : ''}',
                style: const TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (combos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Select at least one option in each group to preview '
                'combinations.',
                style: TextStyle(color: Colors.black54),
              ),
            )
          else
            ...combos.map((combo) {
              final exists = existing.contains(combo.key);
              final willCreate = !exists && !_deselectedKeys.contains(combo.key);
              return _previewRow(combo, exists, willCreate);
            }),
        ],
      ),
    );
  }

  Widget _previewRow(_Combo combo, bool exists, bool willCreate) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x11000000))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: exists
                ? const SizedBox.shrink()
                : Checkbox(
                    value: willCreate,
                    activeColor: _headerColor,
                    onChanged: (value) => setState(() {
                      if (value == true) {
                        _deselectedKeys.remove(combo.key);
                      } else {
                        _deselectedKeys.add(combo.key);
                      }
                    }),
                  ),
          ),
          Expanded(
            child: Text(
              combo.displayName,
              style: TextStyle(
                fontSize: 15,
                color: exists ? Colors.black38 : Colors.black87,
                decoration: exists ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (exists)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'exists',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String labelText) => InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(
          color: _headerColor,
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
          borderSide: const BorderSide(color: _headerColor, width: 2.0),
        ),
      );

  Widget _creatingOverlay(BuildContext context) {
    return Container(
      color: Colors.black45,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Creating $_createdCount of $_totalToCreate…'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Combo {
  final String boatGroup;
  final String ageGroup;
  final String genderGroup;
  final int distance;
  final String key;

  const _Combo({
    required this.boatGroup,
    required this.ageGroup,
    required this.genderGroup,
    required this.distance,
    required this.key,
  });

  String get displayName => '$boatGroup $ageGroup $genderGroup ${distance}m';
}
