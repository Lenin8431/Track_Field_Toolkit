import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/training_record.dart';

/// 训练记录本地存储（shared_preferences + JSON），卸载应用前一直保留在手机上。
class TrainingRepository {
  static const String _storageKey = 'training_records_v1';

  Future<List<TrainingRecord>> loadRecords() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return <TrainingRecord>[];
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <TrainingRecord>[];
      }
      final List<TrainingRecord> records = <TrainingRecord>[];
      for (final Object? item in decoded) {
        if (item is Map) {
          records.add(
            TrainingRecord.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
      records.sort(
        (TrainingRecord a, TrainingRecord b) =>
            b.createdAt.compareTo(a.createdAt),
      );
      return records;
    } catch (_) {
      return <TrainingRecord>[];
    }
  }

  Future<void> addRecord(TrainingRecord record) async {
    final List<TrainingRecord> records = await loadRecords();
    records.insert(0, record);
    await _persist(records);
  }

  Future<void> deleteRecord(String id) async {
    final List<TrainingRecord> records = await loadRecords();
    records.removeWhere((TrainingRecord record) => record.id == id);
    await _persist(records);
  }

  Future<void> clearAll() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> _persist(List<TrainingRecord> records) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw = jsonEncode(
      records.map((TrainingRecord record) => record.toJson()).toList(),
    );
    await prefs.setString(_storageKey, raw);
  }
}
