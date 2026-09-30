import 'dart:async';

import 'package:flutter/material.dart';

import '../models/training_record.dart';
import '../services/training_repository.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';
import '../widgets/app_widgets.dart';
import 'record_detail_screen.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  final TrainingRepository _repository = TrainingRepository();
  final TextEditingController _lapDistanceController = TextEditingController(
    text: '400',
  );

  final Stopwatch _runStopwatch = Stopwatch();
  final Stopwatch _restStopwatch = Stopwatch();
  final List<int> _laps = <int>[];

  Timer? _ticker;
  Duration _runAccumulated = Duration.zero;
  Duration _restAccumulated = Duration.zero;
  Duration _lastLapMark = Duration.zero;
  int _lapDistanceMeters = 400;
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
    _lapDistanceController.dispose();
    super.dispose();
  }

  Duration get _runElapsed =>
      _runAccumulated + (_isRunning ? _runStopwatch.elapsed : Duration.zero);

  Duration get _currentRest =>
      _isResting ? _restStopwatch.elapsed : Duration.zero;

  Duration get _restTotal => _restAccumulated + _currentRest;

  Duration get _totalElapsed => _runElapsed + _restTotal;

  Duration get _currentLap => _runElapsed - _lastLapMark;

  bool get _hasSession =>
      _runElapsed > Duration.zero ||
      _restTotal > Duration.zero ||
      _laps.isNotEmpty ||
      _isRunning ||
      _isResting;

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

  void _recordLap() {
    final Duration runElapsed = _runElapsed;
    final Duration split = runElapsed - _lastLapMark;
    if (split <= Duration.zero) {
      return;
    }
    setState(() {
      _laps.add(split.inMilliseconds);
      _lastLapMark = runElapsed;
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
      _lastLapMark = Duration.zero;
      _laps.clear();
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
        _laps.isEmpty) {
      return;
    }

    final List<int> laps = List<int>.from(_laps);
    final Duration remaining = runElapsed - _lastLapMark;
    if (remaining > Duration.zero) {
      laps.add(remaining.inMilliseconds);
    }

    final TrainingRecord record = TrainingRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      totalMillis: (runElapsed + restTotal).inMilliseconds,
      runMillis: runElapsed.inMilliseconds,
      restMillis: restTotal.inMilliseconds,
      lapDistanceMeters: _lapDistanceMeters,
      laps: laps,
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
            Text('圈数：${record.lapCount} 圈 × ${record.lapDistanceMeters}m'),
            Text('总距离：${record.totalDistanceMeters}m'),
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
                  _buildLapDistanceCard(),
                  const SizedBox(height: 14),
                  _buildTimerCard(theme),
                  const SizedBox(height: 14),
                  _buildLapActionCard(theme),
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
                  _buildLapListCard(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLapDistanceCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SectionTitle('单圈距离'),
          const SizedBox(height: 10),
          TextField(
            controller: _lapDistanceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '单圈距离（米）',
              suffixText: '米',
              border: OutlineInputBorder(),
            ),
            onChanged: (String value) {
              final int? parsed = int.tryParse(value);
              if (parsed != null && parsed > 0) {
                setState(() {
                  _lapDistanceMeters = parsed.clamp(20, 20000).toInt();
                });
              }
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: <int>[200, 400, 800, 1000].map((int distance) {
              return ChoiceChip(
                label: Text('${distance}m'),
                selected: _lapDistanceMeters == distance,
                onSelected: (bool selected) {
                  _lapDistanceController.text = '$distance';
                  setState(() => _lapDistanceMeters = distance);
                },
              );
            }).toList(),
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
                    label: '已计圈数',
                    value: '${_laps.length} 圈',
                  ),
                ),
                Expanded(
                  child: LabeledValue(
                    label: '本次休息',
                    value: formatStopwatch(_currentRest),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLapActionCard(ThemeData theme) {
    return AppCard(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SectionTitle('本圈用时'),
                const SizedBox(height: 4),
                Text(
                  formatStopwatch(_currentLap),
                  style: theme.textTheme.headlineMedium,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 62,
            child: ElevatedButton(
              onPressed: (_isRunning && _currentLap > Duration.zero)
                  ? _recordLap
                  : null,
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

  Widget _buildLapListCard(ThemeData theme) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionTitle('分圈记录（共 ${_laps.length} 圈）'),
          const SizedBox(height: 8),
          if (_laps.isEmpty)
            Text(
              '开始计时后点击【计圈】即可记录每一圈用时。',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: kMutedTextColor,
              ),
            )
          else
            ...List<Widget>.generate(_laps.length, (int i) {
              final int index = _laps.length - 1 - i;
              final int millis = _laps[index];
              final int distance = _lapDistanceMeters <= 0
                  ? 1
                  : _lapDistanceMeters;
              final double pace = millis / 1000 / distance * 1000;
              return Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            '第 ${index + 1} 圈',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        Text(
                          formatDuration(Duration(milliseconds: millis)),
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '配速 ${formatPace(pace)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: kMutedTextColor,
                          ),
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
    );
  }
}
