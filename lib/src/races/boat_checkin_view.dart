import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:eurocup_frontend/src/widgets/page_template.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;

import '../athletes/image_widget_web.dart' if (dart.library.io) 'package:flutter/material.dart';
import '../model/athlete/athlete.dart';
import '../qr_scanner/barcode_scanner_controller.dart';

/// Boat marshal check-in for one crew in one race (heat, repechage, final…).
/// Every scan is stored on the backend with the race's stage. Reserves can be
/// scanned on board too; the mix check runs on who actually boarded.
///
/// Arguments: raceResultId, crewId, title (team name), stage, raceNumber, eventId.
class BoatCheckinView extends StatefulWidget {
  const BoatCheckinView({super.key});

  static const routeName = '/boat_checkin';

  @override
  State<BoatCheckinView> createState() => _BoatCheckinViewState();
}

class _BoatCheckinViewState extends State<BoatCheckinView> {
  static const _blue = Color.fromARGB(255, 0, 80, 150);

  int? _raceResultId;
  int? _raceNumber;
  int? _eventId;
  int? _crewId;
  String _title = '';
  String _stage = '';

  Map<String, dynamic>? _state;
  String? _error;
  bool _loading = true;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_raceResultId != null) return;
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    _raceResultId = args?['raceResultId'] as int?;
    _crewId = args?['crewId'] as int?;
    _title = (args?['title'] as String?) ?? '';
    _stage = (args?['stage'] as String?) ?? '';
    _raceNumber = args?['raceNumber'] as int?;
    _eventId = args?['eventId'] as int?;
    _load();
  }

  Future<void> _load() async {
    if (_raceResultId == null || _crewId == null) {
      setState(() {
        _loading = false;
        _error = 'Missing race or crew';
      });
      return;
    }
    try {
      final state = await api.getBoatCheckins(_raceResultId!, _crewId!);
      if (!mounted) return;
      setState(() {
        _state = state;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _scan() async {
    if (_busy) return;
    final value = await Navigator.pushNamed(context, BarCodeScannerController.routeName);
    if (!mounted || value is! Map || value['qr'] is! String) return;

    setState(() => _busy = true);
    try {
      final result = await api.postBoatCheckin(_raceResultId!, _crewId!, value['qr'] as String);
      if (!mounted) return;
      setState(() {
        if (result['checkin'] is Map<String, dynamic>) _state = result['checkin'];
        _busy = false;
      });
      final athleteMap = result['athlete'];
      final athlete = athleteMap is Map<String, dynamic> ? Athlete.fromMap(athleteMap) : null;
      _showScanResult(status: result['status'] as String, message: result['message'] as String?, athlete: athlete);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _undo(Map<String, dynamic> row) async {
    final athlete = Athlete.fromMap(row['athlete'] as Map<String, dynamic>);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from boat?'),
        content: Text('${athlete.firstName} ${athlete.lastName} will be marked as not on board.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final state = await api.deleteBoatCheckin(_raceResultId!, _crewId!, athlete.id!);
      if (!mounted) return;
      setState(() {
        _state = state;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWithAction(_busy || _state == null ? null : _scan,
          title: 'Boat Check-in', icon: Icons.qr_code_scanner),
      body: Container(
        decoration: bckDecoration(),
        child: _buildBody(),
      ),
      floatingActionButton: _state == null
          ? null
          : FloatingActionButton.extended(
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              onPressed: _busy ? null : _scan,
              icon: _busy
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.qr_code_scanner),
              label: const Text('Scan'),
            ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('Error loading crew:', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _load, child: const Text('Retry')),
        ]),
      );
    }

    final roster = ((_state?['roster'] as List?) ?? []).cast<Map<String, dynamic>>();
    final summary = (_state?['summary'] as Map?)?.cast<String, dynamic>() ?? {};
    final onBoard = roster.where((r) => r['checked_in'] == true).length;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 88), // room for the Scan button
        itemCount: roster.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) return _buildHeader(summary);
          if (index == 1) {
            return ColoredPageHeader(
              title: 'On board: $onBoard / ${roster.length}',
              subtitle: 'Long-press a checked athlete to remove',
              eventId: _eventId,
            );
          }
          return _buildRow(roster[index - 2]);
        },
      ),
    );
  }

  /// White header block, same as Current Entries: crew, race, mix summary.
  Widget _buildHeader(Map<String, dynamic> summary) {
    final stage = (_state?['stage'] as String?) ?? _stage;
    final raceNumber = _state?['race_number'] ?? _raceNumber;
    final race = [if (raceNumber != null) 'Race $raceNumber', stage].where((s) => s.isNotEmpty).join(' · ');
    final warnings = ((summary['warnings'] as List?) ?? []).cast<String>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _title,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          if (race.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(race,
                  style: const TextStyle(color: _blue, fontSize: 16, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center),
            ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('Paddlers ${summary['paddlers'] ?? 0} / ${summary['paddler_seats'] ?? '-'}', Colors.blue),
              _chip('Women ${summary['female'] ?? 0}', Colors.pink),
              _chip('Men ${summary['male'] ?? 0}', Colors.indigo),
            ],
          ),
          for (final w in warnings)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(children: [
                Icon(Icons.warning_amber, color: Colors.orange.shade800),
                const SizedBox(width: 6),
                Expanded(child: Text(w, style: TextStyle(color: Colors.orange.shade900))),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _chip(String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color.shade800)),
    );
  }

  Widget _buildRow(Map<String, dynamic> row) {
    final athlete = Athlete.fromMap(row['athlete'] as Map<String, dynamic>);
    final checkedIn = row['checked_in'] == true;
    final role = row['role'] as String? ?? '';
    final no = (row['no'] as int? ?? 0) + 1;

    return PageListItem(
      onTap: null,
      child: ListTile(
        onLongPress: checkedIn && !_busy ? () => _undo(row) : null,
        leading: Text('$no', style: Theme.of(context).textTheme.displaySmall),
        title: Row(children: [
          if (role != 'paddler')
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: role == 'reserve' ? Colors.grey.shade100 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: role == 'reserve' ? Colors.grey : Colors.blue.shade200),
              ),
              child: Text(
                role.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: role == 'reserve' ? Colors.grey.shade800 : Colors.blue.shade700,
                ),
              ),
            ),
          Expanded(
            child: Text('${athlete.firstName} ${athlete.lastName}',
                style: Theme.of(context).textTheme.displaySmall),
          ),
        ]),
        subtitle: Text('${athlete.gender ?? ''}  ${athlete.category ?? ''}'.trim()),
        trailing: Icon(
          checkedIn ? Icons.check_circle : Icons.radio_button_unchecked,
          color: checkedIn ? Colors.green : Colors.grey,
          size: 30,
        ),
      ),
    );
  }

  void _showScanResult({required String status, String? message, Athlete? athlete}) {
    final passed = status == 'checked_in' || status == 'already_checked_in';
    final statusColor = passed ? Colors.green : Colors.red;
    final photoUrl = athlete?.photo != null && athlete!.photo!.isNotEmpty
        ? "https://$imagePrefix/${athlete.photo}"
        : '';
    const labels = {
      'checked_in': 'PASSED',
      'already_checked_in': 'ALREADY ON BOARD',
      'not_in_crew': 'NOT IN THIS CREW',
      'in_other_crew': 'ON ANOTHER BOAT',
    };
    final label = labels[status] ?? 'INVALID QR CODE';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: passed ? Colors.green.shade50 : Colors.red.shade50,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (photoUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: kIsWeb
                    ? WebImage(imageUrl: photoUrl, width: 200, height: 200)
                    : Image.network(photoUrl, width: 200, height: 200, fit: BoxFit.cover),
              )
            else
              Icon(passed ? Icons.check_circle : Icons.cancel, color: statusColor, size: 100),
            const SizedBox(height: 16),
            if (athlete != null)
              Text(
                '${athlete.firstName} ${athlete.lastName}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: statusColor.shade700),
              textAlign: TextAlign.center,
            ),
            if (!passed && message != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(message, textAlign: TextAlign.center),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(fontSize: 18))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _scan();
            },
            child: const Text('Scan next', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }
}
