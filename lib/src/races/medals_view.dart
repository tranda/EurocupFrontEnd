import 'package:flutter/material.dart';
import '../common.dart';
import '../model/medal_standing.dart';

/// Read-only medal standings view. Renders one table per competition in the
/// passed-in [standings] map, stacked vertically. Filtering by competition
/// is done by the parent (via the shared competition-chip row) — this
/// widget just draws whatever it receives.
class MedalsView extends StatelessWidget {
  /// competition name → sorted standings. If empty, an empty-state message
  /// renders instead of any tables.
  final Map<String, List<MedalStanding>> standings;

  const MedalsView({super.key, required this.standings});

  @override
  Widget build(BuildContext context) {
    final competitions = standings.keys.toList()..sort();

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

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final comp in competitions) ...[
          _sectionHeader(comp),
          _buildTable(context, standings[comp] ?? const []),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  /// Section header above each competition's table. Filled with the
  /// competition's brand color so the section reads at a glance — mirrors
  /// the race header bar in the race list.
  Widget _sectionHeader(String comp) {
    final color = competitionBadgeColor(comp);
    return Container(
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        comp,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildTable(BuildContext context, List<MedalStanding> rows) {
    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No entries yet',
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(48),   // rank
          1: FlexColumnWidth(),      // club
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
                _clubCell(context, rows[i]),
                _BodyCell(_fmt(rows[i].gold), center: true),
                _BodyCell(_fmt(rows[i].silver), center: true),
                _BodyCell(_fmt(rows[i].bronze), center: true),
                _BodyCell(_fmt(rows[i].total), center: true, bold: true),
              ],
            ),
        ],
      ),
    );
  }

  /// Display 0 as an en-dash so zero-medal rows read as "not yet ranked"
  /// rather than emphasising the zero.
  String _fmt(int n) => n == 0 ? '–' : '$n';

  Widget _clubCell(BuildContext context, MedalStanding s) {
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
