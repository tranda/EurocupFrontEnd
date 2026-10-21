import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/widgets/page_template.dart';
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

  final _competitionController = TextEditingController();

  Competition? _selectedEvent;
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
    final canCreate = !(toCreateCount == 0 || _selectedEvent == null);

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
                  title: 'Boat groups',
                  options: disciplineBoatGroups,
                  selected: _selectedBoatGroups,
                  label: (v) => v,
                ),
                _multiSelectSection<String>(
                  title: 'Age categories',
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
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: canCreate ? _createDisciplines : () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canCreate ? pageBlue : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        toCreateCount == 0
                            ? 'Nothing to create'
                            : 'Create $toCreateCount discipline${toCreateCount == 1 ? '' : 's'}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
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

  int? get _eventId => _selectedEvent?.id;

  /// Section body: padded content under a ColoredPageHeader.
  Widget _sectionBody({required Widget child}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: child,
      );

  Widget _eventSelector() => PageTitleBlock(
        title: 'New disciplines',
        children: [
          Text(
            _selectedEvent != null
                ? '${_selectedEvent!.name} ${_selectedEvent!.year}'
                : 'No event selected — pick one on the previous screen',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _selectedEvent != null ? pageBlue : Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );

  Widget _multiSelectSection<T>({
    required String title,
    required List<T> options,
    required Set<T> selected,
    required String Function(T) label,
  }) {
    final allSelected = selected.length == options.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ColoredPageHeader(
          title: title,
          eventId: _eventId,
          trailing: TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
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
        ),
        _sectionBody(
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: options.map((option) {
              final isSelected = selected.contains(option);
              return FilterChip(
                label: Text(label(option)),
                selected: isSelected,
                showCheckmark: true,
                selectedColor: pageBlue.withValues(alpha: 0.15),
                checkmarkColor: pageBlue,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? pageBlue : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected ? pageBlue : Colors.grey,
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
        ),
        pageSectionGap,
      ],
    );
  }

  Widget _competitionField() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredPageHeader(title: 'Competition', eventId: _eventId),
          _sectionBody(
            child: TextFormField(
              controller: _competitionController,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              decoration: pageFieldDecoration('Competition (optional)').copyWith(
                hintText: 'Applied to all generated disciplines',
              ),
              style: const TextStyle(color: Colors.black87, fontSize: 16),
            ),
          ),
          pageSectionGap,
        ],
      );

  Widget _previewSection(List<_Combo> combos, Set<String> existing,
      int toCreateCount, int existingCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ColoredPageHeader(
          title: 'Preview',
          subtitle: '$toCreateCount to create'
              '${existingCount > 0 ? ' · $existingCount exist' : ''}',
          eventId: _eventId,
        ),
        _sectionBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
        ),
      ],
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
                    activeColor: pageBlue,
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
          if (exists) const StatusChip(label: 'exists', color: Colors.grey),
        ],
      ),
    );
  }

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
