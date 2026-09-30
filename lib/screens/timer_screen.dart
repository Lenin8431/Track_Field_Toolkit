import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/training_record.dart';
import '../services/training_repository.dart';
import '../theme/app_theme.dart';
import '../utils/lap_plan.dart';
import '../utils/time_format.dart';
import '../widgets/app_widgets.dart';
import 'record_detail_screen.dart';

/// 跑圈计时。
///
/// 使用流程：先选跑道长度（200 / 300 / 400m），再设置计划圈数（支持小数，
/// 例如 400m 跑道跑 1500m 就是 3.75 圈），然后开始计时、每完成一段点一次【计圈】。
/// 最后不足一圈的部分会显示为「最后Xm」，例如 1500m 在 400m 跑道上为
/// 第1圈、第2圈、第3圈、最后300m 共 4 段。
class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  static const List<int> _distancePresets = <int>[
    800,
    1500,
    3000,
    5000,
    10000,
  ];

  final TrainingRepository _repository = TrainingRepository();
  final TextEditingController _lapsController = TextEditingController(
    text: '2',
  );

  final Stopwatch _runStopwatch = Stopwatch();
  final Stopwatch _restStopwatch = Stopwatch();
  final List<LapSegment> _segments = <LapSegment>[];

  Timer? _ticker;
  Duration _runAccumulated = Duration.zero;
  Duration _restAccumulated = Duration.zero;
  Duration _lastSegmentMark = Duration.zero;
  int _trackLengthMeters = 400;
  double _plannedLaps = 2;
  int _restCount = 0;
  bool _isRunning = false;
  bool _isResting = false;
  bool _resumeRunAfterRest = false;

  @override
  void initState() {
    super.initState();
    // 每 10ms 刷新一次界面；计时数值来自 Stopwatch 单调时钟，显示精确到 0.01 秒。
    _ticker = Timer.periodic(const Duration(milliseconds: 10), (Timer timer) {
      if (_isRunning || _isResting) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _lapsController.dispose();
    super.dispose();
  }

  // ---------------- 计划 ----------------

  List<int> get _plannedDistances => buildPlannedDistances(
    trackLengthMeters: _trackLengthMeters,
    laps: _plannedLaps,
  );

  int get _plannedSegmentCount => _plannedDistances.length;

  int get _plannedDistanceMeters =>
      (_plannedLaps * _trackLengthMeters).round();

  int get _nextSegmentDistance => _segments.length < _plannedDistances.length
      ? _plannedDistances[_segments.length]
      : _trackLengthMeters;

  String get _nextSegmentLabel => lapSegmentLabel(
    trackLengthMeters: _trackLengthMeters,
    index: _segments.length + 1,
    distanceMeters: _nextSegmentDistance,
  );

  // ---------------- 计时状态 ----------------

  Duration get _runElapsed =>
      _runAccumulated + (_isRunning ? _runStopwatch.elapsed : Duration.zero);

  Duration get _currentRest =>
      _isResting ? _restStopwatch.elapsed : Duration.zero;

  Duration get _restTotal => _restAccumulated + _currentRest;

  Duration get _totalElapsed => _runElapsed + _restTotal;

  /// 当前未记录分段的用时（暂停时保持不变）。
  Duration get _currentSegment =>
      (_runElapsed - _lastSegmentMark) > Duration.zero
      ? _runElapsed - _lastSegmentMark
      : Duration.zero;

  int get _recordedDistanceMeters => _segments.fold(
    0,
    (int sum, LapSegment segment) => sum + segment.distanceMeters,
  );

  bool get _hasSession =>
      _runElapsed > Duration.zero ||
      _restTotal > Duration.zero ||
      _segments.isNotEmpty ||
      _isRunning ||
      _isResting;

  /// 计时中或暂停时都可以计圈（休息中除外）。
  bool get _canRecordSegment =>
      !_isResting &&
      _hasSession &&
      _currentSegment > Duration.zero &&
      _segments.length < kMaxSegments;

  String get _statusText {
    if (_isResting) {
      return '休息中（已休息 $_restCount 次）';
    }
    if (_isRunning) {
      return '计时中';
    }
    if (_hasSession) {
      return '已暂停';
    }
    return '准备开始';
  }

  // ---------------- 计划设置 ----------------

  void _selectTrackLength(int meters) {
    if (_hasSession) {
      return;
    }
    setState(() => _trackLengthMeters = meters);
  }

  void _onLapsChanged(String value) {
    final double? parsed = double.tryParse(value.trim());
    if (parsed == null || parsed <= 0 || parsed > kMaxSegments) {
      return;
    }
    setState(() => _plannedLaps = parsed);
  }

  void _applyDistancePreset(int meters) {
    if (_hasSession || _trackLengthMeters <= 0) {
      return;
    }
    final double laps = meters / _trackLengthMeters;
    final double rounded = (laps * 1000).round() / 1000;
    setState(() {
      _plannedLaps = rounded;
      _lapsController.text = formatLaps(rounded);
    });
  }

  // ---------------- 计时操作 ----------------

  void _startRun() {
    if (_isRunning || _isResting) {
      return;
    }
    _runStopwatch
      ..reset()
      ..start();
    setState(() => _isRunning = true);
  }

  void _pauseRun() {
    if (!_isRunning) {
      return;
    }
    _runAccumulated += _runStopwatch.elapsed;
    _runStopwatch
      ..stop()
      ..reset();
    setState(() => _isRunning = false);
  }

  /// 休息计时开关：开始休息自动暂停跑步；结束休息时若休息前在跑则自动继续。
  void _toggleRest() {
    if (_isResting) {
      _restAccumulated += _restStopwatch.elapsed;
      _restStopwatch
        ..stop()
        ..reset();
      final bool resume = _resumeRunAfterRest;
      _resumeRunAfterRest = false;
      setState(() {
        _isResting = false;
        _restCount += 1;
      });
      if (resume) {
        _runStopwatch
          ..reset()
          ..start();
        setState(() => _isRunning = true);
      }
      return;
    }

    if (!_hasSession) {
      return;
    }
    final bool wasRunning = _isRunning;
    if (wasRunning) {
      _runAccumulated += _runStopwatch.elapsed;
      _runStopwatch
        ..stop()
        ..reset();
    }
    _resumeRunAfterRest = wasRunning;
    _restStopwatch
      ..reset()
      ..start();
    setState(() {
      _isResting = true;
      _isRunning = false;
    });
  }

  /// 记录一个分段：计时中或暂停时都可用。
  void _recordSegment() {
    final Duration split = _currentSegment;
    if (split <= Duration.zero) {
      return;
    }
    setState(() {
      _segments.add(
        LapSegment(distanceMeters: _nextSegmentDistance, millis: split.inMilliseconds),
      );
      _lastSegmentMark = _runElapsed;
    });
  }

  void _resetSession() {
    _runStopwatch
      ..stop()
      ..reset();
    _restStopwatch
      ..stop()
      ..reset();
    setState(() {
      _runAccumulated = Duration.zero;
      _restAccumulated = Duration.zero;
      _lastSegmentMark = Duration.zero;
      _segments.clear();
      _isRunning = false;
      _isResting = false;
      _resumeRunAfterRest = false;
      _restCount = 0;
    });
  }

  Future<void> _finish() async {
    final Duration runElapsed = _runElapsed;
    final Duration restTotal = _restTotal;
    if (runElapsed <= Duration.zero &&
        restTotal <= Duration.zero &&
        _segments.isEmpty) {
      return;
    }

    final List<LapSegment> segments = List<LapSegment>.from(_segments);
    final Duration remaining = _currentSegment;
    // 只有计划内还没记录完的分段才自动补上，避免出现“多一圈”的记录。
    if (segments.length < _plannedSegmentCount && remaining > Duration.zero) {
      segments.add(
        LapSegment(
          distanceMeters: _nextSegmentDistance,
          millis: remaining.inMilliseconds,
        ),
      );
    }

    final TrainingRecord record = TrainingRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      totalMillis: (runElapsed + restTotal).inMilliseconds,
      runMillis: runElapsed.inMilliseconds,
      restMillis: restTotal.inMilliseconds,
      trackLengthMeters: _trackLengthMeters,
      plannedLaps: _plannedLaps,
      segments: segments,
    );
    await _repository.addRecord(record);
    if (!mounted) {
      return;
    }
    _resetSession();
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('训练已保存'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('总时长：${formatDuration(record.total)}'),
            Text('跑步净时长：${formatDuration(record.run)}'),
            Text('休息总时长：${formatDuration(record.rest)}'),
            Text('跑道：${record.trackLengthMeters}m · 计划 ${formatLaps(record.plannedLaps)} 圈'),
            Text('分段：${record.segmentCount} 段 · 总距离 ${record.totalDistanceMeters}m'),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('继续'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) =>
                      RecordDetailScreen(record: record),
                ),
              );
            },
            child: const Text('查看记录'),
          ),
        ],
      ),
    );
  }

  // ---------------- 界面 ----------------

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            AppTopBar(
              title: '跑圈计时',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: <Widget>[
                  _buildPlanCard(theme),
                  const SizedBox(height: 14),
                  _buildTimerCard(theme),
                  const SizedBox(height: 14),
                  _buildCurrentSegmentCard(theme),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: BigActionButton(
                          label: '开始',
                          color: kPrimaryColor,
                          icon: Icons.play_arrow_rounded,
                          onPressed: (!_isRunning && !_isResting)
                              ? _startRun
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: BigActionButton(
                          label: '暂停',
                          color: kSuccessColor,
                          icon: Icons.pause_rounded,
                          onPressed: _isRunning ? _pauseRun : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: BigActionButton(
                          label: _isResting ? '结束休息' : '休息计时',
                          color: kSecondaryColor,
                          icon: Icons.timer_outlined,
                          onPressed: (_isResting || _isRunning)
                              ? _toggleRest
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: BigActionButton(
                          label: '结束',
                          color: kDangerColor,
                          icon: Icons.stop_rounded,
                          onPressed: _hasSession ? _finish : null,
                        ),
                      ),
                    ],
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

  Widget _buildPlanCard(ThemeData theme) {
    final List<int> planned = _plannedDistances;
    final String planSummary = planned.isEmpty
        ? '请设置跑道长度与圈数'
        : '计划 ${formatLaps(_plannedLaps)} 圈 = ${_plannedDistanceMeters}m，共 ${planned.length} 段';
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SectionTitle('1. 跑道长度'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: kSupportedTrackLengths.map((int length) {
              return ChoiceChip(
                label: Text('${length}m'),
                selected: _trackLengthMeters == length,
                onSelected: (bool selected) => _selectTrackLength(length),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          const SectionTitle('2. 计划圈数'),
          const SizedBox(height: 10),
          TextField(
            controller: _lapsController,
            enabled: !_hasSession,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: kTextColor,
            ),
            decoration: const InputDecoration(
              labelText: '计划圈数（支持小数）',
              helperText: '例：400m 跑道跑 1500m 输入 3.75',
              suffixText: '圈',
            ),
            onChanged: _onLapsChanged,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _distancePresets.map((int meters) {
              final bool selected = _plannedDistanceMeters == meters;
              return ChoiceChip(
                label: Text('${meters}m'),
                selected: selected,
                onSelected: (bool value) => _applyDistancePreset(meters),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            planSummary,
            style: theme.textTheme.bodyMedium?.copyWith(color: kMutedTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerCard(ThemeData theme) {
    return Card(
      margin: EdgeInsets.zero,
      color: kPrimaryContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: <Widget>[
            Text(
              _statusText,
              style: theme.textTheme.titleMedium?.copyWith(
                color: kOnPrimaryContainer,
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                formatStopwatch(_runElapsed),
                style: theme.textTheme.displayLarge?.copyWith(
                  color: kOnPrimaryContainer,
                ),
              ),
            ),
            Text(
              '跑步净时长',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: kOnPrimaryContainer,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: LabeledValue(
                    label: '总时长',
                    value: formatStopwatch(_totalElapsed),
                  ),
                ),
                Expanded(
                  child: LabeledValue(
                    label: '休息总时长',
                    value: formatStopwatch(_restTotal),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: LabeledValue(
                    label: '已记录分段',
                    value: '${_segments.length} / $_plannedSegmentCount',
                  ),
                ),
                Expanded(
                  child: LabeledValue(
                    label: '已跑距离',
                    value: '$_recordedDistanceMeters m',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentSegmentCard(ThemeData theme) {
    return AppCard(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SectionTitle('本段：$_nextSegmentLabel（${_nextSegmentDistance}m）'),
                const SizedBox(height: 4),
                Text(
                  formatStopwatch(_currentSegment),
                  style: theme.textTheme.headlineMedium,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 62,
            child: ElevatedButton(
              onPressed: _canRecordSegment ? _recordSegment : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('计圈'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentsCard(ThemeData theme) {
    final List<int> planned = _plannedDistances;
    final int rowCount = math.max(planned.length, _segments.length);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionTitle(
            '分段记录（已记录 ${_segments.length} / ${planned.isEmpty ? 0 : planned.length} 段）',
          ),
          const SizedBox(height: 8),
          if (rowCount == 0)
            Text(
              '请先选择跑道长度并设置圈数。',
              style: theme.textTheme.bodyLarge?.copyWith(color: kMutedTextColor),
            )
          else ...<Widget>[
            const _SegmentHeaderRow(),
            const Divider(height: 1),
            for (int i = 0; i < rowCount; i++) _buildSegmentRow(theme, i, planned),
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
                      '${_recordedDistanceMeters}m',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: kPrimaryColor,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      formatStopwatch(_runElapsed),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: kPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSegmentRow(ThemeData theme, int index, List<int> planned) {
    final bool done = index < _segments.length;
    final int distance = done
        ? _segments[index].distanceMeters
        : (index < planned.length ? planned[index] : _trackLengthMeters);
    final String label = lapSegmentLabel(
      trackLengthMeters: _trackLengthMeters,
      index: index + 1,
      distanceMeters: distance,
    );
    final bool isCurrent = !done && index == _segments.length && _hasSession;

    final String timeText;
    if (done) {
      timeText = formatDuration(_segments[index].duration);
    } else if (isCurrent && !_isResting) {
      timeText = formatStopwatch(_currentSegment);
    } else {
      timeText = '--';
    }

    final TextStyle? labelStyle = theme.textTheme.bodyLarge?.copyWith(
      color: isCurrent ? kPrimaryColor : kTextColor,
      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.normal,
    );
    final TextStyle? timeStyle = theme.textTheme.bodyLarge?.copyWith(
      color: done ? kTextColor : kMutedTextColor,
      fontWeight: done ? FontWeight.w600 : FontWeight.normal,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: <Widget>[
          Expanded(flex: 3, child: Text(label, style: labelStyle)),
          Expanded(
            flex: 3,
            child: Text(
              '${distance}m',
              style: theme.textTheme.bodyLarge?.copyWith(color: kMutedTextColor),
            ),
          ),
          Expanded(flex: 4, child: Text(timeText, style: timeStyle)),
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
        ],
      ),
    );
  }
}
