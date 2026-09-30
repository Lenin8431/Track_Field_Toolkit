import 'dart:convert';
import 'dart:io';

import '../models/training_record.dart';

/// 训练记录本地存储。
///
/// 直接使用 Dart 的 dart:io 把 JSON 写到应用私有目录，
/// 不依赖任何第三方插件（shared_preferences / path_provider），
/// 这样 GitHub Actions 构建时不需要额外解析 Android 插件依赖，构建更稳定。
///
/// 数据保存在应用私有目录下的 training_records_v1.json，
/// 卸载应用时会被系统一并清除。
class TrainingRepository {
  static const String _fileName = 'training_records_v1.json';

  /// Android 应用私有文件目录（applicationId 为 com.track.toolkit）。
  /// 若修改 applicationId，需要同步修改这里。
  static const List<String> _androidDataDirs = <String>[
    '/data/user/0/com.track.toolkit/files',
    '/data/data/com.track.toolkit/files',
  ];

  Directory? _cachedDirectory;

  Future<Directory> _resolveDirectory() async {
    final Directory? cached = _cachedDirectory;
    if (cached != null) {
      return cached;
    }

    for (final String path in _androidDataDirs) {
      try {
        final Directory dir = Directory(path);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        // 写一次探测文件，确认目录真的可写
        final File probe = File('${dir.path}${Platform.pathSeparator}.write_probe');
        await probe.writeAsString('ok', flush: true);
        await probe.delete();
        _cachedDirectory = dir;
        return dir;
      } on FileSystemException {
        continue;
      } on UnsupportedError {
        continue;
      }
    }

    // 兜底（例如单元测试环境）：使用系统临时目录，保证功能可用不崩溃
    final Directory fallback = Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}track_toolkit_data',
    );
    if (!await fallback.exists()) {
      await fallback.create(recursive: true);
    }
    _cachedDirectory = fallback;
    return fallback;
  }

  Future<File> _resolveFile() async {
    final Directory dir = await _resolveDirectory();
    return File('${dir.path}${Platform.pathSeparator}$_fileName');
  }

  Future<List<TrainingRecord>> loadRecords() async {
    try {
      final File file = await _resolveFile();
      if (!await file.exists()) {
        return <TrainingRecord>[];
      }
      final String raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return <TrainingRecord>[];
      }
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <TrainingRecord>[];
      }
      final List<TrainingRecord> records = <TrainingRecord>[];
      for (final Object? item in decoded) {
        if (item is Map) {
          records.add(TrainingRecord.fromJson(Map<String, dynamic>.from(item)));
        }
      }
      records.sort(
        (TrainingRecord a, TrainingRecord b) =>
            b.createdAt.compareTo(a.createdAt),
      );
      return records;
    } catch (_) {
      // 文件损坏或不兼容时按空列表处理，避免影响使用
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
    try {
      final File file = await _resolveFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // 忽略删除失败
    }
  }

  Future<void> _persist(List<TrainingRecord> records) async {
    final File file = await _resolveFile();
    final String raw = jsonEncode(
      records.map((TrainingRecord record) => record.toJson()).toList(),
    );
    await file.writeAsString(raw, flush: true);
  }
}
