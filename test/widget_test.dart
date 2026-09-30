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
  });

  test('1500m 拆分为 3×400 + 300，且总时间一致', () {
    final plan = buildPacePlan(
      event: TrackEvent.meters1500,
      style: RunStyle.even,
      totalSeconds: 240,
    );
    expect(plan.length, 4);
    expect(plan.map((e) => e.distanceMeters).toList(), <int>[400, 400, 400, 300]);
    final double sum = plan.fold<double>(
      0,
      (double sum, PaceSegment e) => sum + e.durationSeconds,
    );
    expect(sum, closeTo(240, 0.001));
  });

  test('激进型前段更快', () {
    final plan = buildPacePlan(
      event: TrackEvent.meters5000,
      style: RunStyle.aggressive,
      totalSeconds: 960,
    );
    expect(plan.first.durationSeconds, lessThan(plan.last.durationSeconds));
  });

  test('秒表格式精确到 0.01 秒', () {
    expect(formatStopwatch(const Duration(milliseconds: 62340)), '01:02.34');
    expect(
      formatStopwatch(const Duration(milliseconds: 3723450)),
      '1:02:03.45',
    );
  });
}
