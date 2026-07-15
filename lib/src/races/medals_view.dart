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

    // Responsive column widths — on narrow (phone) screens shrink the fixed
    // columns so the flexible Club column gets enough width to keep names on
    // one or two lines instead of wrapping letter-by-letter.
    final narrow = MediaQuery.of(context).size.width < 500;
    final rankW = narrow ? 32.0 : 48.0;
    final medalW = narrow ? 40.0 : 64.0;
    final hPad = narrow ? 8.0 : 16.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Table(
        columnWidths: {
          0: FixedColumnWidth(rankW),   // rank
          1: const FlexColumnWidth(),   // club
          2: FixedColumnWidth(medalW),  // gold
          3: FixedColumnWidth(medalW),  // silver
          4: FixedColumnWidth(medalW),  // bronze
          5: FixedColumnWidth(medalW),  // total
        },
        border: TableBorder(
          horizontalInside: BorderSide(color: Colors.grey.shade300),
        ),
        children: [
          TableRow(
            decoration: const BoxDecoration(color: Color(0xFFF5F5F5)),
            children: [
              _HeaderCell('#', narrow: narrow),
              _HeaderCell('Club', narrow: narrow),
              _HeaderCell('🥇', center: true, narrow: narrow),
              _HeaderCell('🥈', center: true, narrow: narrow),
              _HeaderCell('🥉', center: true, narrow: narrow),
              _HeaderCell('Σ', center: true, narrow: narrow),
            ],
          ),
          for (int i = 0; i < rows.length; i++)
            TableRow(
              children: [
                _BodyCell('${i + 1}', narrow: narrow),
                _clubCell(context, rows[i], narrow: narrow),
                _BodyCell(_fmt(rows[i].gold), center: true, narrow: narrow),
                _BodyCell(_fmt(rows[i].silver), center: true, narrow: narrow),
                _BodyCell(_fmt(rows[i].bronze), center: true, narrow: narrow),
                _BodyCell(_fmt(rows[i].total),
                    center: true, bold: true, narrow: narrow),
              ],
            ),
        ],
      ),
    );
  }

  /// Display 0 as an en-dash so zero-medal rows read as "not yet ranked"
  /// rather than emphasising the zero.
  String _fmt(int n) => n == 0 ? '–' : '$n';

  Widget _clubCell(BuildContext context, MedalStanding s,
      {required bool narrow}) {
    final country = s.country;
    // On narrow screens: drop the country-code text (flag alone is enough)
    // and use a smaller name font so we keep names to one line where possible.
    final nameStyle = narrow
        ? const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 0, 80, 150),
          )
        : Theme.of(context).textTheme.displaySmall;
    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: narrow ? 4 : 8, vertical: 12),
      child: Row(
        children: [
          if (country != null) ...[
            Text(getCountryFlag(country),
                style: TextStyle(fontSize: narrow ? 16 : 18)),
            if (!narrow) ...[
              const SizedBox(width: 6),
              Text(getCountryCode(country),
                  style:
                      const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
            SizedBox(width: narrow ? 6 : 8),
          ],
          Expanded(
            child: Text(
              s.clubName,
              style: nameStyle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
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
  final bool narrow;
  const _HeaderCell(this.text, {this.center = false, this.narrow = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(horizontal: narrow ? 4 : 8, vertical: 10),
        child: Text(
          text,
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: narrow ? 13 : 14),
        ),
      );
}

class _BodyCell extends StatelessWidget {
  final String text;
  final bool center;
  final bool bold;
  final bool narrow;
  const _BodyCell(this.text,
      {this.center = false, this.bold = false, this.narrow = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(horizontal: narrow ? 4 : 8, vertical: 12),
        child: Text(
          text,
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: narrow ? 14 : 16,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );
}
