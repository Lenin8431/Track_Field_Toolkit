import 'package:flutter/material.dart';

import '../models/training_record.dart';
import '../theme/app_theme.dart';
import '../utils/lap_plan.dart';
import '../utils/time_format.dart';
import '../widgets/app_widgets.dart';

/// 训练记录详情：显示每一段的用时与下方合计总时间。
///
/// 例如 400m 跑道跑 1500m（3.75 圈）显示：
/// 第1圈 / 第2圈 / 第3圈 / 最后300m，共 4 段，下面一行是合计总时间。
class RecordDetailScreen extends StatelessWidget {
  const RecordDetailScreen({super.key, required this.record});

  final TrainingRecord record;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            AppTopBar(
              title: '训练记录详情',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: <Widget>[
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          formatDateTime(record.createdAt),
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: LabeledValue(
                                label: '总时长',
                                value: formatDuration(record.total),
                              ),
                            ),
                            Expanded(
                              child: LabeledValue(
                                label: '跑步净时长',
                                value: formatDuration(record.run),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: LabeledValue(
                                label: '休息总时长',
                                value: formatDuration(record.rest),
                              ),
                            ),
                            Expanded(
                              child: LabeledValue(
                                label: '跑道长度',
                                value: '${record.trackLengthMeters} m',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: LabeledValue(
                                label: '计划圈数',
                                value: '${formatLaps(record.plannedLaps)} 圈',
                              ),
                            ),
                            Expanded(
                              child: LabeledValue(
                                label: '分段数',
                                value: '${record.segmentCount} 段',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: LabeledValue(
                                label: '总距离',
                                value: '${record.totalDistanceMeters} m',
                              ),
                            ),
                            Expanded(
                              child: LabeledValue(
                                label: '平均每圈',
                                value: formatDuration(record.averageLap),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildSegmentsCard(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentsCard(ThemeData theme) {
    if (record.segments.isEmpty) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SectionTitle('分段用时'),
            const SizedBox(height: 8),
            Text(
              '本次训练未记录分段数据。',
              style: theme.textTheme.bodyLarge?.copyWith(color: kMutedTextColor),
            ),
          ],
        ),
      );
    }

    final double totalPace = record.totalDistanceMeters <= 0
        ? 0
        : record.runMillis / 1000 / record.totalDistanceMeters * 1000;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SectionTitle('分段用时'),
          const SizedBox(height: 8),
          const _SegmentHeaderRow(),
          const Divider(height: 1),
          for (int i = 0; i < record.segments.length; i++)
            _buildSegmentRow(theme, i),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: Text(
                    '合计',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: kPrimaryColor,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    '${record.totalDistanceMeters}m',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: kPrimaryColor,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    formatDuration(record.run),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: kPrimaryColor,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    formatPace(totalPace),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: kPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentRow(ThemeData theme, int index) {
    final LapSegment segment = record.segments[index];
    final int distance = segment.distanceMeters <= 0 ? 1 : segment.distanceMeters;
    final double pace = segment.millis / 1000 / distance * 1000;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Text(
              record.segmentLabel(index),
              style: theme.textTheme.bodyLarge?.copyWith(color: kTextColor),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '${segment.distanceMeters}m',
              style: theme.textTheme.bodyLarge?.copyWith(color: kMutedTextColor),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              formatDuration(segment.duration),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: kTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              formatPace(pace),
              style: theme.textTheme.bodyLarge?.copyWith(color: kMutedTextColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentHeaderRow extends StatelessWidget {
  const _SegmentHeaderRow();

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(color: kPrimaryColor);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          Expanded(flex: 3, child: Text('分段', style: style)),
          Expanded(flex: 3, child: Text('距离', style: style)),
          Expanded(flex: 4, child: Text('用时', style: style)),
          Expanded(flex: 4, child: Text('配速/km', style: style)),
        ],
      ),
    );
  }
}
