import 'package:flutter/material.dart';
import '../common.dart';
import '../model/medal_standing.dart';

/// Read-only medal standings view. Consumes the map produced by
/// `MedalTally.compute` and lets the user pick which competition to display.
class MedalsView extends StatefulWidget {
  /// competition name → sorted standings.
  final Map<String, List<MedalStanding>> standings;

  const MedalsView({super.key, required this.standings});

  @override
  State<MedalsView> createState() => _MedalsViewState();
}

class _MedalsViewState extends State<MedalsView> {
  String? _selectedCompetition;

  @override
  void initState() {
    super.initState();
    _selectedCompetition = _defaultCompetition();
  }

  @override
  void didUpdateWidget(covariant MedalsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the selected competition disappeared from the data (e.g. after a
    // refresh that removed all Corporate finals), fall back to the default.
    if (_selectedCompetition != null &&
        !widget.standings.containsKey(_selectedCompetition)) {
      _selectedCompetition = _defaultCompetition();
    }
  }

  String? _defaultCompetition() {
    final keys = widget.standings.keys.toList()..sort();
    return keys.isEmpty ? null : keys.first;
  }

  @override
  Widget build(BuildContext context) {
    final competitions = widget.standings.keys.toList()..sort();

    if (competitions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No medals awarded yet',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
      );
    }

    final selected = _selectedCompetition ?? competitions.first;
    final rows = widget.standings[selected] ?? const <MedalStanding>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('Competition:', style: TextStyle(color: Colors.black54)),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: selected,
                items: competitions
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _selectedCompetition = v);
                },
              ),
            ],
          ),
        ),
        Expanded(child: _buildTable(rows, selected)),
      ],
    );
  }

  Widget _buildTable(List<MedalStanding> rows, String competition) {
    if (rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No medals awarded yet in $competition',
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(48),   // rank
          1: FlexColumnWidth(),      // team
          2: FixedColumnWidth(64),   // gold
          3: FixedColumnWidth(64),   // silver
          4: FixedColumnWidth(64),   // bronze
          5: FixedColumnWidth(64),   // total
        },
        border: TableBorder(
          horizontalInside: BorderSide(color: Colors.grey.shade300),
        ),
        children: [
          const TableRow(
            decoration: BoxDecoration(color: Color(0xFFF5F5F5)),
            children: [
              _HeaderCell('#'),
              _HeaderCell('Club'),
              _HeaderCell('🥇', center: true),
              _HeaderCell('🥈', center: true),
              _HeaderCell('🥉', center: true),
              _HeaderCell('Σ', center: true),
            ],
          ),
          for (int i = 0; i < rows.length; i++)
            TableRow(
              children: [
                _BodyCell('${i + 1}'),
                _clubCell(rows[i]),
                _BodyCell('${rows[i].gold}', center: true),
                _BodyCell('${rows[i].silver}', center: true),
                _BodyCell('${rows[i].bronze}', center: true),
                _BodyCell('${rows[i].total}', center: true, bold: true),
              ],
            ),
        ],
      ),
    );
  }

  Widget _clubCell(MedalStanding s) {
    final country = s.country;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          if (country != null) ...[
            Text(getCountryFlag(country), style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(getCountryCode(country),
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              s.clubName,
              // Match the Races view team-name style (Theme.displaySmall:
              // 19pt bold, brand blue) so the two views read as the same
              // information density and visual weight.
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final bool center;
  const _HeaderCell(this.text, {this.center = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Text(
          text,
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      );
}

class _BodyCell extends StatelessWidget {
  final String text;
  final bool center;
  final bool bold;
  const _BodyCell(this.text, {this.center = false, this.bold = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Text(
          text,
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: 16,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );
}
