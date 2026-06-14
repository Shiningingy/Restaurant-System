import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/capture_template.dart';

/// Persists capture templates as a JSON list in shared_preferences. Templates
/// are local merchant config (like printer settings), so they are not synced
/// and need no database table.
class CaptureTemplateStore {
  CaptureTemplateStore(this._prefs);

  static const _key = 'captureTemplates';

  final SharedPreferences _prefs;

  List<CaptureTemplate> list() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => CaptureTemplate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _writeAll(List<CaptureTemplate> templates) => _prefs.setString(
    _key,
    jsonEncode(templates.map((t) => t.toJson()).toList()),
  );

  /// Inserts or replaces a template by id, then returns the full list.
  Future<List<CaptureTemplate>> save(CaptureTemplate template) async {
    final all = list();
    final i = all.indexWhere((t) => t.id == template.id);
    if (i >= 0) {
      all[i] = template;
    } else {
      all.add(template);
    }
    await _writeAll(all);
    return all;
  }

  Future<List<CaptureTemplate>> delete(String id) async {
    final all = list()..removeWhere((t) => t.id == id);
    await _writeAll(all);
    return all;
  }
}
