/// 一次跑圈训练记录。
///
/// [laps] 保存每一圈的用时（毫秒），只统计跑步时间，不含休息时间。
class TrainingRecord {
  const TrainingRecord({
    required this.id,
    required this.createdAt,
    required this.totalMillis,
    required this.runMillis,
    required this.restMillis,
    required this.lapDistanceMeters,
    required this.laps,
  });

  final String id;
  final DateTime createdAt;
  final int totalMillis;
  final int runMillis;
  final int restMillis;
  final int lapDistanceMeters;
  final List<int> laps;

  int get lapCount => laps.length;

  int get totalDistanceMeters => lapDistanceMeters * laps.length;

  Duration get total => Duration(milliseconds: totalMillis);

  Duration get run => Duration(milliseconds: runMillis);

  Duration get rest => Duration(milliseconds: restMillis);

  Duration get averageLap {
    if (laps.isEmpty) {
      return Duration.zero;
    }
    final int sum = laps.reduce((int a, int b) => a + b);
    return Duration(milliseconds: sum ~/ laps.length);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'totalMillis': totalMillis,
    'runMillis': runMillis,
    'restMillis': restMillis,
    'lapDistanceMeters': lapDistanceMeters,
    'laps': laps,
  };

  static TrainingRecord fromJson(Map<String, dynamic> json) {
    final List<int> laps = <int>[];
    final Object? rawLaps = json['laps'];
    if (rawLaps is List) {
      for (final Object? item in rawLaps) {
        if (item is num) {
          laps.add(item.toInt());
        }
      }
    }
    return TrainingRecord(
      id: json['id']?.toString() ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['createdAt'] as num?)?.toInt() ?? 0,
      ),
      totalMillis: (json['totalMillis'] as num?)?.toInt() ?? 0,
      runMillis: (json['runMillis'] as num?)?.toInt() ?? 0,
      restMillis: (json['restMillis'] as num?)?.toInt() ?? 0,
      lapDistanceMeters: (json['lapDistanceMeters'] as num?)?.toInt() ?? 400,
      laps: laps,
    );
  }
}
