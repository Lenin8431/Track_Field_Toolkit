import 'package:flutter/material.dart';

import '../models/training_record.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';
import '../widgets/app_widgets.dart';

class RecordDetailScreen extends StatelessWidget {
  const RecordDetailScreen({super.key, required this.record});

  final TrainingRecord record;

  @override
  Widget build(BuildContext context) {
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
                          style: Theme.of(context).textTheme.titleLarge,
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
                                label: '单圈距离',
                                value: '${record.lapDistanceMeters} m',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: LabeledValue(
                                label: '圈数',
                                value: '${record.lapCount} 圈',
                              ),
                            ),
                            Expanded(
                              child: LabeledValue(
                                label: '总距离',
                                value: '${record.totalDistanceMeters} m',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LabeledValue(
                          label: '平均单圈',
                          value: formatDuration(record.averageLap),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SectionTitle('每一圈用时'),
                        const SizedBox(height: 8),
                        const _LapHeaderRow(),
                        const Divider(height: 1),
                        if (record.laps.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text('本次训练未记录分圈数据。'),
                          )
                        else
                          ...List<Widget>.generate(record.laps.length, (int i) {
                            final int millis = record.laps[i];
                            final int distance = record.lapDistanceMeters <= 0
                                ? 1
                                : record.lapDistanceMeters;
                            final double pace =
                                millis / 1000 / distance * 1000;
                            return Column(
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        flex: 2,
                                        child: Text('第 ${i + 1} 圈'),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          formatDuration(
                                            Duration(milliseconds: millis),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(formatPace(pace)),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
                              ],
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LapHeaderRow extends StatelessWidget {
  const _LapHeaderRow();

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: kPrimaryColor,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          Expanded(flex: 2, child: Text('圈次', style: style)),
          Expanded(flex: 3, child: Text('用时', style: style)),
          Expanded(flex: 3, child: Text('配速/km', style: style)),
        ],
      ),
    );
  }
}
