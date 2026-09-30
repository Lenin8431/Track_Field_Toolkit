enum TrackEvent { meters800, meters1500, meters3000, meters5000, meters10000 }

extension TrackEventInfo on TrackEvent {
  String get label => switch (this) {
    TrackEvent.meters800 => '800m',
    TrackEvent.meters1500 => '1500m',
    TrackEvent.meters3000 => '3000m',
    TrackEvent.meters5000 => '5000m',
    TrackEvent.meters10000 => '10000m',
  };

  int get totalMeters => switch (this) {
    TrackEvent.meters800 => 800,
    TrackEvent.meters1500 => 1500,
    TrackEvent.meters3000 => 3000,
    TrackEvent.meters5000 => 5000,
    TrackEvent.meters10000 => 10000,
  };

  String get defaultTimeText => switch (this) {
    TrackEvent.meters800 => '2:00',
    TrackEvent.meters1500 => '4:00',
    TrackEvent.meters3000 => '9:00',
    TrackEvent.meters5000 => '16:00',
    TrackEvent.meters10000 => '33:00',
  };

  /// 分段规则：
  /// 800m 2×400m（可细化 4×200m）、1500m 3×400+300、3000m 7×400+200、
  /// 5000m 12×400+200、10000m 24×400+400。
  List<int> segmentDistances({bool detailed800 = false}) => switch (this) {
    TrackEvent.meters800 =>
      detailed800 ? <int>[200, 200, 200, 200] : <int>[400, 400],
    TrackEvent.meters1500 => <int>[400, 400, 400, 300],
    TrackEvent.meters3000 => <int>[400, 400, 400, 400, 400, 400, 400, 200],
    TrackEvent.meters5000 => <int>[
      400, 400, 400, 400, 400, 400, 400, 400, 400, 400, 400, 400, 200,
    ],
    TrackEvent.meters10000 => <int>[
      400, 400, 400, 400, 400, 400, 400, 400, 400, 400, 400, 400,
      400, 400, 400, 400, 400, 400, 400, 400, 400, 400, 400, 400, 400,
    ],
  };
}

enum RunStyle { aggressive, even, conservative }

extension RunStyleInfo on RunStyle {
  String get label => switch (this) {
    RunStyle.aggressive => '激进型',
    RunStyle.even => '平均型',
    RunStyle.conservative => '稳妥型',
  };

  String get description => switch (this) {
    RunStyle.aggressive => '前半程略快，后半程允许小幅掉速，适合冲刺能力强的选手。',
    RunStyle.even => '所有分段时间基本一致，全程匀速，最省心的跑法。',
    RunStyle.conservative => '前半程保守留体力，后半程逐步加速，后程不掉速。',
  };
}

class PaceSegment {
  const PaceSegment({
    required this.index,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.cumulativeSeconds,
  });

  final int index;
  final int distanceMeters;
  final double durationSeconds;
  final double cumulativeSeconds;

  double get paceSecondsPerKm =>
      distanceMeters <= 0 ? 0 : durationSeconds / distanceMeters * 1000;
}

/// 根据目标总时间与跑法风格拆分分段用时。
///
/// 每个分段先按跑法分配“速度系数”，再以 距离 ÷ 速度系数 作为权重，
/// 把目标总时间等比分配到各分段，保证各段之和等于目标完赛时间。
List<PaceSegment> buildPacePlan({
  required TrackEvent event,
  required RunStyle style,
  required double totalSeconds,
  bool detailed800 = false,
}) {
  if (totalSeconds <= 0) {
    return const <PaceSegment>[];
  }
  final List<int> distances =
      event.segmentDistances(detailed800: detailed800);
  if (distances.isEmpty) {
    return const <PaceSegment>[];
  }

  final List<double> weights = <double>[];
  for (int i = 0; i < distances.length; i++) {
    final double progress =
        distances.length == 1 ? 1 : (i + 0.5) / distances.length;
    final double speedFactor = switch (style) {
      RunStyle.aggressive => 1.075 - 0.15 * progress,
      RunStyle.even => 1.0,
      RunStyle.conservative => 0.925 + 0.15 * progress,
    };
    weights.add(distances[i] / speedFactor);
  }

  final double weightSum = weights.reduce((double a, double b) => a + b);
  final List<PaceSegment> segments = <PaceSegment>[];
  double cumulative = 0;
  for (int i = 0; i < distances.length; i++) {
    final double duration = totalSeconds * weights[i] / weightSum;
    cumulative += duration;
    segments.add(
      PaceSegment(
        index: i + 1,
        distanceMeters: distances[i],
        durationSeconds: duration,
        cumulativeSeconds: cumulative,
      ),
    );
  }
  return segments;
}
