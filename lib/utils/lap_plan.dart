/// 跑圈分段计划工具。
///
/// 跑道长度仅支持 200 / 300 / 400 米；圈数支持小数，例如：
/// 400m 跑道跑 1500m = 3.75 圈 -> 分段为 第1圈(400m)、第2圈(400m)、
/// 第3圈(400m)、最后300m，共 4 段。
const List<int> kSupportedTrackLengths = <int>[200, 300, 400];

/// 单次训练允许的最大分段数，避免输入异常值把界面撑爆。
const int kMaxSegments = 100;

/// 根据跑道长度与计划圈数，计算每一段的距离（米）。
List<int> buildPlannedDistances({
  required int trackLengthMeters,
  required double laps,
}) {
  if (trackLengthMeters <= 0 || laps <= 0 || !laps.isFinite) {
    return const <int>[];
  }

  final int fullLaps = laps.floor();
  int partialMeters = ((laps - fullLaps) * trackLengthMeters).round();
  if (partialMeters >= trackLengthMeters) {
    partialMeters = 0;
  }

  final List<int> distances = <int>[];
  for (int i = 0; i < fullLaps && distances.length < kMaxSegments; i++) {
    distances.add(trackLengthMeters);
  }
  // 不足一圈的部分作为最后一段，例如 3.75 圈 * 400m = 最后 300m
  if (partialMeters > 0 && partialMeters < trackLengthMeters && distances.length < kMaxSegments) {
    distances.add(partialMeters);
  }
  return distances;
}

/// 分段名称：整圈为「第N圈」，不足一圈的最后一段为「最后Xm」。
String lapSegmentLabel({
  required int trackLengthMeters,
  required int index,
  required int distanceMeters,
}) {
  if (trackLengthMeters > 0 && distanceMeters > 0 && distanceMeters < trackLengthMeters) {
    return '最后${distanceMeters}m';
  }
  return '第$index圈';
}

/// 把圈数格式化成适合输入框显示的文本：2.0 -> "2"，3.75 -> "3.75"。
String formatLaps(double laps) {
  if (!laps.isFinite || laps <= 0) {
    return '';
  }
  if ((laps - laps.roundToDouble()).abs() < 0.0001) {
    return laps.round().toString();
  }
  String text = laps.toStringAsFixed(3);
  while (text.endsWith('0')) {
    text = text.substring(0, text.length - 1);
  }
  if (text.endsWith('.')) {
    text = text.substring(0, text.length - 1);
  }
  return text;
}
