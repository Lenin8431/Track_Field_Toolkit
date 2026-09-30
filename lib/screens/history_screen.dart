import 'package:flutter/material.dart';

import '../models/training_record.dart';
import '../services/training_repository.dart';
import '../theme/app_theme.dart';
import '../utils/lap_plan.dart';
import '../utils/time_format.dart';
import '../widgets/app_widgets.dart';
import 'record_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TrainingRepository _repository = TrainingRepository();
  List<TrainingRecord> _records = <TrainingRecord>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<TrainingRecord> records = await _repository.loadRecords();
    if (!mounted) {
      return;
    }
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  Future<void> _confirmClear() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('清空全部记录'),
        content: const Text('确定要删除本机保存的全部训练记录吗？此操作无法撤销。'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定清空', style: TextStyle(color: kDangerColor)),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await _repository.clearAll();
    await _load();
  }

  Future<void> _delete(TrainingRecord record) async {
    await _repository.deleteRecord(record.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            AppTopBar(
              title: '历史训练记录',
              onBack: () => Navigator.of(context).maybePop(),
              actions: <Widget>[
                if (_records.isNotEmpty)
                  TextButton(
                    onPressed: _confirmClear,
                    child: const Text('清空'),
                  ),
              ],
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      children: <Widget>[
                        Text(
                          '共 ${_records.length} 条本地记录',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: kMutedTextColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_records.isEmpty)
                          const AppCard(
                            child: Text(
                              '还没有训练记录。完成一次跑圈计时并点击【结束】后，'
                              '记录会自动保存在这里。',
                              style: TextStyle(fontSize: 16, color: kTextColor),
                            ),
                          )
                        else
                          ..._records.map(
                            (TrainingRecord record) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _RecordCard(
                                record: record,
                                onOpen: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (BuildContext context) =>
                                          RecordDetailScreen(record: record),
                                    ),
                                  );
                                  await _load();
                                },
                                onDelete: () => _delete(record),
                              ),
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

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.record,
    required this.onOpen,
    required this.onDelete,
  });

  final TrainingRecord record;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      formatDateTime(record.createdAt),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${record.trackLengthMeters}m 跑道 · '
                      '${formatLaps(record.plannedLaps)} 圈 · '
                      '${record.segmentCount} 段 · '
                      '${record.totalDistanceMeters}m',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: kMutedTextColor),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onDelete,
                child: const Text('删除', style: TextStyle(color: kDangerColor)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: LabeledValue(
                  label: '跑步净时长',
                  value: formatDuration(record.run),
                ),
              ),
              Expanded(
                child: LabeledValue(
                  label: '休息总时长',
                  value: formatDuration(record.rest),
                ),
              ),
            ],
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
                  label: '平均单圈',
                  value: formatDuration(record.averageLap),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
