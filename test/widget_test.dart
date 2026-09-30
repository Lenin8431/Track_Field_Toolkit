import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:track_field_toolkit/app_info.dart';
import 'package:track_field_toolkit/main.dart';
import 'package:track_field_toolkit/screens/pace_screen.dart';
import 'package:track_field_toolkit/screens/timer_screen.dart';
import 'package:track_field_toolkit/theme/app_theme.dart';
import 'package:track_field_toolkit/utils/lap_plan.dart';
import 'package:track_field_toolkit/utils/pace_plan.dart';
import 'package:track_field_toolkit/utils/time_format.dart';

void main() {
  testWidgets('首页显示两个核心模块', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const TrackToolkitApp());

    expect(find.text('田径通用工具'), findsOneWidget);
    expect(find.text('跑圈计时'), findsOneWidget);
    expect(find.text('中距离比赛配速模拟器'), findsOneWidget);
    expect(find.text('版本 $kAppVersionName'), findsOneWidget);
    expect(find.text(kAppPoweredBy), findsOneWidget);
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

  test('主题文字颜色不为空（防止文字显示为空白）', () {
    final ThemeData theme = buildAppTheme();
    expect(theme.textTheme.bodyLarge?.color, isNotNull);
    expect(theme.textTheme.bodyMedium?.color, isNotNull);
    expect(theme.textTheme.bodySmall?.color, isNotNull);
    expect(theme.textTheme.titleLarge?.color, isNotNull);
    expect(theme.textTheme.titleMedium?.color, isNotNull);
    expect(theme.textTheme.labelLarge?.color, isNotNull);
    expect(theme.textTheme.displayLarge?.color, isNotNull);
  });

  testWidgets('配速模拟器：输入目标时间后表格正常显示分段用时', (
    WidgetTester tester,
  ) async {
    // 放大测试视口，保证长页面里的分段表也被构建出来
    await tester.binding.setSurfaceSize(const Size(900, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(theme: buildAppTheme(), home: const PaceScreen()),
    );

    // 默认 800m / 2:00
    expect(find.text('2:00'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '2:05');
    await tester.pump();

    // 800m 平均型 2:05 = 125s，两段各 62.5s：本段 + 累计共 3 处 1:02.5
    expect(find.text('1:02.5'), findsNWidgets(3));
    // 第二段累计用时
    expect(find.text('2:05.0'), findsOneWidget);
    // 每公里配速 62.5 / 0.4 = 156.25s -> 2:36.3
    expect(find.text('2:36.3'), findsNWidgets(2));
  });

  testWidgets('配速模拟器：分段表文字颜色不为空（不是空白）', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(theme: buildAppTheme(), home: const PaceScreen()),
    );

    await tester.enterText(find.byType(TextField), '2:05');
    await tester.pump();

    final Text cell = tester.widget<Text>(find.text('1:02.5').first);
    expect(cell.style?.color, isNotNull);
    expect(cell.style!.color, kTextColor);
  });

  test('400m 跑道 3.75 圈拆分为 3×400m + 最后300m', () {
    final List<int> distances = buildPlannedDistances(
      trackLengthMeters: 400,
      laps: 3.75,
    );
    expect(distances, <int>[400, 400, 400, 300]);
    expect(
      lapSegmentLabel(trackLengthMeters: 400, index: 1, distanceMeters: 400),
      '第1圈',
    );
    expect(
      lapSegmentLabel(trackLengthMeters: 400, index: 2, distanceMeters: 400),
      '第2圈',
    );
    expect(
      lapSegmentLabel(trackLengthMeters: 400, index: 3, distanceMeters: 400),
      '第3圈',
    );
    expect(
      lapSegmentLabel(trackLengthMeters: 400, index: 4, distanceMeters: 300),
      '最后300m',
    );
  });

  test('常见项目在各跑道上的分段', () {
    // 800m / 400m 跑道 = 2 圈
    expect(
      buildPlannedDistances(trackLengthMeters: 400, laps: 2),
      <int>[400, 400],
    );
    // 1500m / 300m 跑道 = 5 圈
    expect(
      buildPlannedDistances(trackLengthMeters: 300, laps: 5).length,
      5,
    );
    // 1500m / 200m 跑道 = 7.5 圈 -> 7×200m + 最后100m
    expect(
      buildPlannedDistances(trackLengthMeters: 200, laps: 7.5).last,
      100,
    );
    // 5000m / 400m 跑道 = 12.5 圈 -> 最后200m
    expect(
      buildPlannedDistances(trackLengthMeters: 400, laps: 12.5).last,
      200,
    );
    // 10000m / 400m 跑道 = 25 圈（整数圈不产生额外分段）
    expect(
      buildPlannedDistances(trackLengthMeters: 400, laps: 25).length,
      25,
    );
  });

  test('圈数格式化', () {
    expect(formatLaps(2), '2');
    expect(formatLaps(3.75), '3.75');
    expect(formatLaps(7.5), '7.5');
  });

  testWidgets('跑圈计时：400m/3.75圈 分段显示第1~3圈与最后300m', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(theme: buildAppTheme(), home: const TimerScreen()),
    );

    // 只有「计划圈数」一个输入框
    await tester.enterText(find.byType(TextField), '3.75');
    await tester.pump();

    expect(find.text('第1圈'), findsOneWidget);
    expect(find.text('第2圈'), findsOneWidget);
    expect(find.text('第3圈'), findsOneWidget);
    expect(find.text('最后300m'), findsOneWidget);
    expect(find.text('第4圈'), findsNothing);
    expect(find.text('合计'), findsOneWidget);
  });

  testWidgets('跑圈计时：暂停状态下也能计圈', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(theme: buildAppTheme(), home: const TimerScreen()),
    );

    await tester.tap(find.text('开始'));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.tap(find.text('暂停'));
    await tester.pump();

    // 暂停后计圈按钮必须是可点击状态
    final Finder lapButton = find.widgetWithText(ElevatedButton, '计圈');
    expect(tester.widget<ElevatedButton>(lapButton).onPressed, isNotNull);

    await tester.tap(lapButton);
    await tester.pump();

    // 默认计划 2 圈，记录 1 段后应显示 1 / 2
    expect(find.text('1 / 2'), findsOneWidget);
  });
}
