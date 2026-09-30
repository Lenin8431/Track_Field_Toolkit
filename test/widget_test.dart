import 'package:flutter_test/flutter_test.dart';
import 'package:track_field_toolkit/main.dart';
import 'package:track_field_toolkit/utils/pace_plan.dart';
import 'package:track_field_toolkit/utils/time_format.dart';

void main() {
  testWidgets('首页显示两个核心模块', (WidgetTester tester) async {
    await tester.pumpWidget(const TrackToolkitApp());

    expect(find.text('田径通用工具'), findsOneWidget);
    expect(find.text('跑圈计时'), findsOneWidget);
    expect(find.text('中距离比赛配速模拟器'), findsOneWidget);
  });

  test('目标时间解析', () {
    expect(parseTimeToSeconds('2:00'), 120);
    expect(parseTimeToSeconds('16:30'), 990);
    expect(parseTimeToSeconds('1:05:00'), 3900);
    expect(parseTimeToSeconds('abc'), isNull);
    expect(parseTimeToSeconds(''), isNull);
    expect(parseTimeToSeconds('0'), isNull);
  });

  test('秒表格式精确到 0.01 秒', () {
    expect(formatStopwatch(const Duration(milliseconds: 62340)), '01:02.34');
    expect(
      formatStopwatch(const Duration(milliseconds: 3723450)),
      '1:02:03.45',
    );
  });

  test('各项目分段规则与总距离一致', () {
    for (final TrackEvent event in TrackEvent.values) {
      final List<int> distances = event.segmentDistances();
      expect(
        distances.reduce((int a, int b) => a + b),
        event.totalMeters,
        reason: '${event.label} 分段距离之和应等于项目距离',
      );
    }

    expect(
      buildPacePlan(
        event: TrackEvent.meters800,
        style: RunStyle.even,
        totalSeconds: 120,
      ).length,
      2,
    );
    expect(
      buildPacePlan(
        event: TrackEvent.meters800,
        style: RunStyle.even,
        totalSeconds: 120,
        detailed800: true,
      ).length,
      4,
    );
    expect(
      buildPacePlan(
        event: TrackEvent.meters1500,
        style: RunStyle.even,
        totalSeconds: 240,
      ).map((PaceSegment e) => e.distanceMeters).toList(),
      <int>[400, 400, 400, 300],
    );
    expect(
      buildPacePlan(
        event: TrackEvent.meters3000,
        style: RunStyle.even,
        totalSeconds: 540,
      ).length,
      8,
    );
    expect(
      buildPacePlan(
        event: TrackEvent.meters5000,
        style: RunStyle.even,
        totalSeconds: 960,
      ).length,
      13,
    );
    expect(
      buildPacePlan(
        event: TrackEvent.meters10000,
        style: RunStyle.even,
        totalSeconds: 1980,
      ).length,
      25,
    );
  });

  test('所有项目与跑法的分段用时之和等于目标总时间', () {
    for (final TrackEvent event in TrackEvent.values) {
      for (final RunStyle style in RunStyle.values) {
        final List<PaceSegment> plan = buildPacePlan(
          event: event,
          style: style,
          totalSeconds: 600,
        );
        final double sum = plan.fold<double>(
          0,
          (double sum, PaceSegment segment) => sum + segment.durationSeconds,
        );
        expect(
          sum,
          closeTo(600, 0.001),
          reason: '${event.label} · ${style.label} 分段用时之和应等于目标总时间',
        );
      }
    }
  });

  test('激进型前段更快（同为 400m 分段）', () {
    final List<PaceSegment> plan = buildPacePlan(
      event: TrackEvent.meters800,
      style: RunStyle.aggressive,
      totalSeconds: 120,
    );
    expect(plan.length, 2);
    expect(plan.first.durationSeconds, lessThan(plan.last.durationSeconds));
    expect(plan.first.paceSecondsPerKm, lessThan(plan.last.paceSecondsPerKm));
  });

  test('稳妥型后程更快（同为 400m 分段）', () {
    final List<PaceSegment> plan = buildPacePlan(
      event: TrackEvent.meters800,
      style: RunStyle.conservative,
      totalSeconds: 120,
    );
    expect(plan.length, 2);
    expect(plan.first.durationSeconds, greaterThan(plan.last.durationSeconds));
  });

  test('5000m 最后一段只有 200m，需按每公里配速比较', () {
    final List<PaceSegment> plan = buildPacePlan(
      event: TrackEvent.meters5000,
      style: RunStyle.aggressive,
      totalSeconds: 960,
    );
    expect(plan.length, 13);
    expect(plan.last.distanceMeters, 200);
    // 激进型：开段每公里配速更快（数值更小）
    expect(plan.first.paceSecondsPerKm, lessThan(plan.last.paceSecondsPerKm));
  });

  test('平均型各分段每公里配速基本一致', () {
    final List<PaceSegment> plan = buildPacePlan(
      event: TrackEvent.meters3000,
      style: RunStyle.even,
      totalSeconds: 540,
    );
    expect(
      plan.last.paceSecondsPerKm,
      closeTo(plan.first.paceSecondsPerKm, 0.001),
    );
  });
}
