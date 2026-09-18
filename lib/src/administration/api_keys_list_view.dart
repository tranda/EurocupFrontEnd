import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:eurocup_frontend/src/model/api_key.dart';

/// Admin-only screen to mint and manage server API keys (e.g. a `races.read`
/// key handed to an external club app). The full secret is shown exactly once,
/// right after creation — the server only stores a hash.
class ApiKeysListView extends StatefulWidget {
  const ApiKeysListView({super.key});

  static const routeName = '/api_keys_list';

  @override
  State<ApiKeysListView> createState() => _ApiKeysListViewState();
}

/// The permission scopes the backend accepts (see ApiKeyController validation).
const List<String> _availableScopes = [
  'races.read',
  'races.write',
  'races.bulk-update',
  '*',
];

const Color _brandBlue = Color.fromARGB(255, 0, 80, 150);

class _ApiKeysListViewState extends State<ApiKeysListView> {
  late Future<List<ApiKey>> dataFuture;

  @override
  void initState() {
    super.initState();
    dataFuture = api.getApiKeys();
  }

  void _refresh() {
    setState(() {
      dataFuture = api.getApiKeys();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Keys'),
        actions: [
          IconButton(
            tooltip: 'Create key',
            onPressed: () => _showCreateDialog(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Container(
        decoration: bckDecoration(),
        child: FutureBuilder<List<ApiKey>>(
          future: dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Failed to load keys: ${snapshot.error}'));
            }
            final keys = snapshot.data ?? [];
            if (keys.isEmpty) {
              return const Center(child: Text('No API keys yet. Tap + to create one.'));
            }
            return ListView.separated(
              itemCount: keys.length,
              separatorBuilder: (_, __) => const Divider(height: smallSpace),
              itemBuilder: (context, index) => _keyTile(context, keys[index]),
            );
          },
        ),
      ),
    );
  }

  Widget _keyTile(BuildContext context, ApiKey key) {
    final expired = key.expiresAt != null && key.expiresAt!.isBefore(DateTime.now());
    final inactive = !key.isActive || expired;
    return Opacity(
      opacity: inactive ? 0.5 : 1.0,
      child: ListTile(
        title: Text(
          key.name ?? '(unnamed)',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final p in key.permissions)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(p,
                        style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${key.keyPrefix ?? 'ak_…'}…  •  '
              '${expired ? 'expired' : (key.expiresAt == null ? 'never expires' : 'expires ${_fmtDate(key.expiresAt)}')}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              key.lastUsedAt == null
                  ? 'never used'
                  : 'last used ${_fmtDate(key.lastUsedAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        trailing: IconButton(
          tooltip: 'Delete key',
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () => _confirmDelete(key),
        ),
      ),
    );
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  void _showCreateDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final expiresController = TextEditingController();
    final selectedScopes = <String>{'races.read'};

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('Create API Key'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: buildStandardInputDecorationWithLabel('Name'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Please enter a name' : null,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      const Text('Permissions',
                          style: TextStyle(color: _brandBlue, fontWeight: FontWeight.w600)),
                      for (final scope in _availableScopes)
                        CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(scope),
                          value: selectedScopes.contains(scope),
                          onChanged: (checked) {
                            setLocal(() {
                              if (checked == true) {
                                selectedScopes.add(scope);
                              } else {
                                selectedScopes.remove(scope);
                              }
                            });
                          },
                        ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: expiresController,
                        keyboardType: TextInputType.number,
                        decoration: buildStandardInputDecorationWithLabel(
                            'Expires in days (blank = never)'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final n = int.tryParse(v.trim());
                          if (n == null || n < 1 || n > 365) {
                            return 'Enter 1–365, or leave blank';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    if (selectedScopes.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Select at least one permission')),
                      );
                      return;
                    }
                    final expiresText = expiresController.text.trim();
                    try {
                      final created = await api.createApiKey(
                        nameController.text.trim(),
                        selectedScopes.toList(),
                        expiresInDays: expiresText.isEmpty ? null : int.parse(expiresText),
                      );
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      _refresh();
                      _showKeySecretDialog(created.plaintextKey);
                    } catch (e) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text('Failed to create key: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// One-time reveal of the plaintext secret. It cannot be retrieved again.
  void _showKeySecretDialog(String plaintextKey) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('API Key Created'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Copy this key now — it will not be shown again.',
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.redAccent),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: SelectableText(
                  plaintextKey,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                ),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: plaintextKey));
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Key copied to clipboard')),
                  );
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(ApiKey key) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete API Key'),
          content: Text(
            'Delete "${key.name ?? 'this key'}"? Any app using it will immediately lose access.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                if (key.id == null) return;
                try {
                  await api.deleteApiKey(key.id!);
                  _refresh();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('API key deleted')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete: $e')),
                    );
                  }
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }
}
