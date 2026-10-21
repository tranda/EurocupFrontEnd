import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/widgets.dart';
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
/// Arguments: raceResultId, crewId, title (team name), stage.
class BoatCheckinView extends StatefulWidget {
  const BoatCheckinView({super.key});

  static const routeName = '/boat_checkin';

  @override
  State<BoatCheckinView> createState() => _BoatCheckinViewState();
}

class _BoatCheckinViewState extends State<BoatCheckinView> {
  int? _raceResultId;
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
    final stage = (_state?['stage'] as String?) ?? _stage;
    return Scaffold(
      appBar: appBarWithAction(_busy || _state == null ? null : _scan,
          title: stage.isEmpty ? _title : '$_title · $stage', icon: Icons.qr_code_scanner),
      body: Container(
        decoration: bckDecoration(),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ]),
        ),
      );
    }

    final roster = ((_state?['roster'] as List?) ?? []).cast<Map<String, dynamic>>();
    final summary = (_state?['summary'] as Map?)?.cast<String, dynamic>() ?? {};

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: roster.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) return _buildSummary(summary, roster);
          return _buildRow(roster[index - 1]);
        },
      ),
    );
  }

  Widget _buildSummary(Map<String, dynamic> summary, List<Map<String, dynamic>> roster) {
    final onBoard = roster.where((r) => r['checked_in'] == true).length;
    final warnings = ((summary['warnings'] as List?) ?? []).cast<String>();
    final textStyle = Theme.of(context).textTheme.bodyLarge;

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('On board: $onBoard / ${roster.length}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Paddlers: ${summary['paddlers'] ?? 0} / ${summary['paddler_seats'] ?? '-'}'
              '   ·   Women: ${summary['female'] ?? 0}   ·   Men: ${summary['male'] ?? 0}',
              style: textStyle,
            ),
            for (final w in warnings)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(children: [
                  const Icon(Icons.warning_amber, color: Colors.orange),
                  const SizedBox(width: 6),
                  Expanded(child: Text(w, style: textStyle?.copyWith(color: Colors.orange.shade900))),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> row) {
    final athlete = Athlete.fromMap(row['athlete'] as Map<String, dynamic>);
    final checkedIn = row['checked_in'] == true;
    final role = row['role'] as String? ?? '';
    final no = (row['no'] as int? ?? 0) + 1;
    final roleLabel = role == 'paddler' ? '' : '($role) ';

    return Column(children: [
      ListTile(
        leading: Icon(
          checkedIn ? Icons.check_circle : Icons.radio_button_unchecked,
          color: checkedIn ? Colors.green : Colors.grey,
          size: 32,
        ),
        title: Text('$no $roleLabel${athlete.firstName} ${athlete.lastName}',
            style: Theme.of(context).textTheme.displaySmall),
        subtitle: Text('${athlete.gender ?? ''} ${athlete.category ?? ''}'.trim()),
        onLongPress: checkedIn && !_busy ? () => _undo(row) : null,
      ),
      const Divider(height: 4),
    ]);
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
