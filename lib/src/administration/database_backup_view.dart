import 'dart:html' as html;
import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;

class DatabaseBackupView extends StatefulWidget {
  const DatabaseBackupView({super.key});

  static const routeName = '/database_backup';

  @override
  State<DatabaseBackupView> createState() => _DatabaseBackupViewState();
}

class _DatabaseBackupViewState extends State<DatabaseBackupView> {
  List<Map<String, dynamic>> backups = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    setState(() => isLoading = true);
    try {
      backups = await api.getBackups();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load backups: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _createBackup() async {
    setState(() => isLoading = true);
    try {
      var result = await api.createBackup();
      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup created successfully')),
          );
        }
        await _loadBackups();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Backup failed: ${result['message']}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating backup: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _restoreBackup(String filename) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Database'),
        content: Text(
          'Are you sure you want to restore from "$filename"?\n\n'
          'This will overwrite the current database. '
          'It is recommended to create a backup before restoring.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => isLoading = true);
    try {
      var result = await api.restoreBackup(filename);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['success'] == true
                ? 'Database restored successfully'
                : 'Restore failed: ${result['message']}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error restoring backup: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _deleteBackup(String filename) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Backup'),
        content: Text('Are you sure you want to delete "$filename"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => isLoading = true);
    try {
      var result = await api.deleteBackup(filename);
      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup deleted')),
          );
        }
        await _loadBackups();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: ${result['message']}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting backup: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _downloadBackup(String filename) async {
    setState(() => isLoading = true);
    try {
      final bytes = await api.downloadBackup(filename);
      if (bytes != null) {
        final blob = html.Blob([bytes], 'application/sql');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', filename)
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to download backup')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _formatSize(dynamic sizeBytes) {
    if (sizeBytes == null) return 'Unknown';
    int bytes = sizeBytes is int ? sizeBytes : int.tryParse(sizeBytes.toString()) ?? 0;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: HSLColor.fromColor(color).withLightness(0.3).toColor(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(title: 'Database Backups'),
      body: Container(
        decoration: bckDecoration(),
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _createBackup,
                      icon: const Icon(Icons.backup),
                      label: const Text('Create Backup Now'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
                const Divider(height: 4),
                Expanded(
                  child: backups.isEmpty
                      ? const Center(
                          child: Text('No backups found',
                              style: TextStyle(fontSize: 16, color: Colors.grey)),
                        )
                      : ListView.builder(
                          itemCount: backups.length,
                          itemBuilder: (context, index) {
                            final backup = backups[index];
                            return Column(
                              children: [
                                ListTile(
                                  title: Text(
                                    backup['filename'] ?? 'Unknown',
                                    style: Theme.of(context).textTheme.displaySmall,
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        _badge(
                                            backup['created_at'] ?? '',
                                            Colors.blue),
                                        const SizedBox(width: 8),
                                        _badge(
                                            _formatSize(backup['size']),
                                            Colors.teal),
                                      ],
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.save,
                                            color: Colors.blue),
                                        tooltip: 'Download',
                                        onPressed: () => _downloadBackup(
                                            backup['filename']),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.refresh,
                                            color: Colors.orange),
                                        tooltip: 'Restore',
                                        onPressed: () => _restoreBackup(
                                            backup['filename']),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        tooltip: 'Delete',
                                        onPressed: () => _deleteBackup(
                                            backup['filename']),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 4),
                                const Divider(height: smallSpace),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
            if (isLoading) busyOverlay(context),
          ],
        ),
      ),
    );
  }
}
