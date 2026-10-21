import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/app_version.dart';

/// Keeps the web app on the latest release.
///
/// The deploy writes app_version.json next to the app. At startup, if the
/// server has a newer version, the page reloads itself onto it. While the app
/// is open it checks again every few minutes and when the tab comes back to
/// the front; then [available] is set and a "Reload" banner shows, so nobody
/// loses half-entered data.
class UpdateChecker {
  static final ValueNotifier<String?> available = ValueNotifier<String?>(null);

  static const _reloadKey = 'update_reload_target';
  static Timer? _timer;

  static bool get _enabled => kIsWeb && kReleaseMode;

  /// Returns true when a reload has started (caller should stop booting).
  static Future<bool> reloadIfOutdated() async {
    if (!_enabled) return false;
    final remote = await _fetchRemoteVersion();
    if (remote == null || !_isNewer(remote, AppVersion.version)) return false;

    // Only try once per version per tab, so a stale CDN can't cause a loop.
    if (html.window.sessionStorage[_reloadKey] == remote) {
      available.value = remote;
      return false;
    }
    html.window.sessionStorage[_reloadKey] = remote;
    reload(remote);
    return true;
  }

  /// Periodic + on-focus checks that only raise the banner.
  static void startWatching() {
    if (!_enabled || _timer != null) return;
    _timer = Timer.periodic(const Duration(minutes: 5), (_) => _check());
    html.document.onVisibilityChange.listen((_) {
      if (html.document.visibilityState == 'visible') _check();
    });
  }

  static Future<void> _check() async {
    final remote = await _fetchRemoteVersion();
    if (remote != null && _isNewer(remote, AppVersion.version)) {
      available.value = remote;
    }
  }

  /// Loads the page again under a new URL so nothing comes from cache.
  static void reload([String? version]) {
    final loc = html.window.location;
    final v = version ?? available.value ?? DateTime.now().millisecondsSinceEpoch.toString();
    html.window.location.replace('${loc.origin}${loc.pathname}?v=$v${loc.hash}');
  }

  static Future<String?> _fetchRemoteVersion() async {
    try {
      final url = Uri.base.resolve('app_version.json').replace(
          queryParameters: {'t': DateTime.now().millisecondsSinceEpoch.toString()});
      final response = await http.get(url).timeout(const Duration(seconds: 3));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);
      return data is Map && data['version'] is String ? data['version'] as String : null;
    } catch (_) {
      return null;
    }
  }

  /// True when [a] is a higher x.y.z than [b].
  static bool _isNewer(String a, String b) {
    List<int> parts(String v) => v.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final pa = parts(a), pb = parts(b);
    for (var i = 0; i < 3; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x > y;
    }
    return false;
  }
}
