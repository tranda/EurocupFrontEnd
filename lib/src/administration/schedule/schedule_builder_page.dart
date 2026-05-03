import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:flutter/material.dart';

import '../../model/event/event.dart';
import '../../model/schedule/schedule_config.dart';
import 'tabs/grid_tab.dart';
import 'tabs/import_tab.dart';
import 'tabs/plan_and_seeds_tab.dart';
import 'tabs/setup_tab.dart';

class ScheduleBuilderPage extends StatefulWidget {
  const ScheduleBuilderPage({super.key});
  static const routeName = '/schedule_builder';

  @override
  State<ScheduleBuilderPage> createState() => _ScheduleBuilderPageState();
}

class _ScheduleBuilderPageState extends State<ScheduleBuilderPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _loading = true;
  String? _error;
  Competition? _event;
  ScheduleConfig? _config;
  bool _publishing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_event != null) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Competition) {
      _event = args;
      _loadConfig();
    } else {
      setState(() {
        _loading = false;
        _error = 'No event provided.';
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    if (_event?.id == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final config = await api.getScheduleConfig(_event!.id!);
      setState(() {
        _config = config;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _togglePublish() async {
    if (_config == null || _event?.id == null || _publishing) return;
    setState(() => _publishing = true);
    try {
      if (_config!.isPublished) {
        await api.unpublishSchedule(_event!.id!);
      } else {
        await api.publishSchedule(_event!.id!);
      }
      await _loadConfig();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventLabel = _event?.name ?? 'Schedule Builder';
    final base = Theme.of(context);
    const darkText = Color(0xFF1F2937);
    final localTheme = base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF5F6F8),
      cardTheme: const CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
      ),
      dividerColor: const Color(0xFFE5E7EB),
      iconTheme: base.iconTheme.copyWith(color: darkText),
      textTheme: base.textTheme.copyWith(
        bodyLarge: base.textTheme.bodyLarge?.copyWith(color: darkText),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(color: darkText),
        bodySmall: base.textTheme.bodySmall?.copyWith(color: Colors.black54),
        labelLarge: base.textTheme.labelLarge?.copyWith(color: darkText),
        labelMedium: base.textTheme.labelMedium?.copyWith(color: darkText),
        labelSmall: base.textTheme.labelSmall?.copyWith(color: Colors.black54),
        titleMedium: base.textTheme.titleMedium?.copyWith(color: darkText),
      ),
    );
    return Theme(
      data: localTheme,
      child: Scaffold(
        backgroundColor: localTheme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          title: Row(children: [
            Expanded(child: Text(eventLabel, overflow: TextOverflow.ellipsis)),
            if (_config != null) _statusBadge(_config!.scheduleStatus),
          ]),
          actions: [
            if (_config != null)
              TextButton.icon(
                onPressed: _publishing ? null : _togglePublish,
                icon: Icon(_config!.isPublished ? Icons.lock_open : Icons.publish),
                label: Text(_config!.isPublished ? 'Unpublish' : 'Publish'),
              ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: const Color.fromARGB(255, 0, 80, 150),
            unselectedLabelColor: Colors.black54,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Setup', icon: Icon(Icons.tune)),
              Tab(text: 'Plan & Seeds', icon: Icon(Icons.format_list_numbered)),
              Tab(text: 'Grid', icon: Icon(Icons.grid_on)),
              Tab(text: 'Import', icon: Icon(Icons.file_upload)),
            ],
          ),
        ),
        body: DefaultTextStyle.merge(
          style: const TextStyle(color: darkText),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Error: $_error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadConfig, child: const Text('Retry')),
        ]),
      );
    }
    if (_config == null || _event?.id == null) {
      return const Center(child: Text('Schedule not loaded.'));
    }
    return TabBarView(
      controller: _tabController,
      children: [
        SetupTab(eventId: _event!.id!, config: _config!, onChanged: _loadConfig),
        PlanAndSeedsTab(eventId: _event!.id!),
        GridTab(eventId: _event!.id!, config: _config!),
        ImportTab(eventId: _event!.id!),
      ],
    );
  }

  Widget _statusBadge(String status) {
    final isPublished = status == 'published';
    return Container(
      margin: const EdgeInsets.only(left: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPublished ? Colors.green.shade100 : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isPublished ? 'PUBLISHED' : 'DRAFT',
        style: TextStyle(
          color: isPublished ? Colors.green.shade900 : Colors.orange.shade900,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
