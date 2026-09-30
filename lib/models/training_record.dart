import '../utils/lap_plan.dart';

/// 一个分段（整圈或最后不足一圈的部分）。
class LapSegment {
  const LapSegment({required this.distanceMeters, required this.millis});

  /// 该段距离（米），整圈等于跑道长度，最后一段可能小于跑道长度。
  final int distanceMeters;

  /// 该段用时（毫秒），只统计跑步时间，不含休息时间。
  final int millis;

  Duration get duration => Duration(milliseconds: millis);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'distanceMeters': distanceMeters,
    'millis': millis,
  };

  static LapSegment fromJson(Map<String, dynamic> json) => LapSegment(
    distanceMeters: (json['distanceMeters'] as num?)?.toInt() ?? 0,
    millis: (json['millis'] as num?)?.toInt() ?? 0,
  );
}

/// 一次跑圈训练记录。
///
/// 分段示例：400m 跑道跑 1500m（3.75 圈）会记录 4 个分段：
/// 第1圈 400m、第2圈 400m、第3圈 400m、最后300m。
class TrainingRecord {
  const TrainingRecord({
    required this.id,
    required this.createdAt,
    required this.totalMillis,
    required this.runMillis,
    required this.restMillis,
    required this.trackLengthMeters,
    required this.plannedLaps,
    required this.segments,
  });

  final String id;
  final DateTime createdAt;
  final int totalMillis;
  final int runMillis;
  final int restMillis;

  /// 跑道长度（米）：200 / 300 / 400。
  final int trackLengthMeters;

  /// 计划圈数，支持小数，例如 3.75。
  final double plannedLaps;

  final List<LapSegment> segments;

  int get segmentCount => segments.length;

  int get totalDistanceMeters =>
      segments.fold(0, (int sum, LapSegment s) => sum + s.distanceMeters);

  double get actualLaps {
    if (trackLengthMeters <= 0) {
      return segments.length.toDouble();
    }
    return totalDistanceMeters / trackLengthMeters;
  }

  Duration get total => Duration(milliseconds: totalMillis);

  Duration get run => Duration(milliseconds: runMillis);

  Duration get rest => Duration(milliseconds: restMillis);

  /// 平均每圈用时（按跑道长度折算，最后不足一圈的按比例计入）。
  Duration get averageLap {
    if (segments.isEmpty || runMillis <= 0 || trackLengthMeters <= 0) {
      return Duration.zero;
    }
    final double laps = actualLaps;
    if (laps <= 0) {
      return Duration.zero;
    }
    return Duration(milliseconds: (runMillis / laps).round());
  }

  /// 第 index 个分段（从 0 开始）的显示名称。
  String segmentLabel(int index) {
    if (index < 0 || index >= segments.length) {
      return '';
    }
    return lapSegmentLabel(
      trackLengthMeters: trackLengthMeters,
      index: index + 1,
      distanceMeters: segments[index].distanceMeters,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'totalMillis': totalMillis,
    'runMillis': runMillis,
    'restMillis': restMillis,
    'trackLengthMeters': trackLengthMeters,
    'plannedLaps': plannedLaps,
    'segments': segments.map((LapSegment s) => s.toJson()).toList(),
  };

  static TrainingRecord fromJson(Map<String, dynamic> json) {
    final List<LapSegment> segments = <LapSegment>[];

    final Object? rawSegments = json['segments'];
    if (rawSegments is List) {
      for (final Object? item in rawSegments) {
        if (item is Map) {
          segments.add(
            LapSegment.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    // 兼容旧版本数据：旧记录使用 laps + lapDistanceMeters
    final int legacyLapDistance =
        (json['lapDistanceMeters'] as num?)?.toInt() ?? 400;
    if (segments.isEmpty) {
      final Object? rawLaps = json['laps'];
      if (rawLaps is List) {
        for (final Object? item in rawLaps) {
          if (item is num) {
            segments.add(
              LapSegment(
                distanceMeters: legacyLapDistance,
                millis: item.toInt(),
              ),
            );
          }
        }
      }
    }

    final int trackLength =
        (json['trackLengthMeters'] as num?)?.toInt() ?? legacyLapDistance;

    return TrainingRecord(
      id: json['id']?.toString() ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['createdAt'] as num?)?.toInt() ?? 0,
      ),
      totalMillis: (json['totalMillis'] as num?)?.toInt() ?? 0,
      runMillis: (json['runMillis'] as num?)?.toInt() ?? 0,
      restMillis: (json['restMillis'] as num?)?.toInt() ?? 0,
      trackLengthMeters: trackLength,
      plannedLaps: (json['plannedLaps'] as num?)?.toDouble() ??
          segments.length.toDouble(),
      segments: segments,
    );
  }
}
