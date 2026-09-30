import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/pace_plan.dart';
import '../utils/time_format.dart';
import '../widgets/app_widgets.dart';

class PaceScreen extends StatefulWidget {
  const PaceScreen({super.key});

  @override
  State<PaceScreen> createState() => _PaceScreenState();
}

class _PaceScreenState extends State<PaceScreen> {
  static const List<int> _rowFlex = <int>[2, 3, 4, 4, 4];

  TrackEvent _event = TrackEvent.meters800;
  RunStyle _style = RunStyle.even;
  bool _detail800 = false;
  late final TextEditingController _timeController;

  @override
  void initState() {
    super.initState();
    _timeController = TextEditingController(text: _event.defaultTimeText);
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  void _selectEvent(TrackEvent event) {
    setState(() {
      _event = event;
      _detail800 = false;
      _timeController.text = event.defaultTimeText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double? totalSeconds = parseTimeToSeconds(_timeController.text);
    final List<PaceSegment> plan = totalSeconds == null
        ? const <PaceSegment>[]
        : buildPacePlan(
            event: _event,
            style: _style,
            totalSeconds: totalSeconds,
            detailed800: _detail800 && _event == TrackEvent.meters800,
          );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            AppTopBar(
              title: '配速模拟器',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: <Widget>[
                  _buildEventCard(theme),
                  const SizedBox(height: 14),
                  _buildTimeCard(theme, totalSeconds),
                  const SizedBox(height: 14),
                  _buildStyleCard(theme),
                  const SizedBox(height: 14),
                  _buildIntroCard(theme),
                  const SizedBox(height: 14),
                  _buildPlanCard(theme, plan),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(ThemeData theme) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SectionTitle('1. 选择项目'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TrackEvent.values.map((TrackEvent event) {
              return ChoiceChip(
                label: Text(event.label),
                selected: _event == event,
                onSelected: (bool selected) => _selectEvent(event),
              );
            }).toList(),
          ),
          if (_event == TrackEvent.meters800) ...<Widget>[
            const SizedBox(height: 6),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _detail800,
              onChanged: (bool value) => setState(() => _detail800 = value),
              title: const Text('细化分段'),
              subtitle: Text(
                _detail800 ? '4 × 200m 分段时间' : '2 × 400m 分段时间',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeCard(ThemeData theme, double? totalSeconds) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SectionTitle('2. 目标完赛总时间'),
          const SizedBox(height: 10),
          TextField(
            controller: _timeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: kTextColor,
            ),
            decoration: InputDecoration(
              labelText: '目标完赛总时间',
              hintText: '例如 2:00 / 16:30 / 1:05:00',
              border: const OutlineInputBorder(),
              errorText: totalSeconds == null ? '请输入 mm:ss 或 h:mm:ss 格式的时间' : null,
              helperText: totalSeconds == null
                  ? null
                  : '已识别：${formatSegmentSeconds(totalSeconds)}',
            ),
            onChanged: (String value) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleCard(ThemeData theme) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SectionTitle('3. 选择跑法风格'),
          const SizedBox(height: 10),
          DropdownButtonFormField<RunStyle>(
            value: _style,
            decoration: const InputDecoration(
              labelText: '跑法风格',
              border: OutlineInputBorder(),
            ),
            items: RunStyle.values.map((RunStyle style) {
              return DropdownMenuItem<RunStyle>(
                value: style,
                child: Text(style.label),
              );
            }).toList(),
            onChanged: (RunStyle? value) {
              if (value != null) {
                setState(() => _style = value);
              }
            },
          ),
          const SizedBox(height: 10),
          Text(
            _style.description,
            style: theme.textTheme.bodyLarge?.copyWith(color: kMutedTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard(ThemeData theme) {
    return Card(
      margin: EdgeInsets.zero,
      color: kPrimaryContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '三种跑法说明',
              style: theme.textTheme.titleMedium?.copyWith(
                color: kOnPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            ...RunStyle.values.map((RunStyle style) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${style.label}：${style.description}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: kOnPrimaryContainer,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(ThemeData theme, List<PaceSegment> plan) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const SectionTitle('4. 分段配速表'),
              const Spacer(),
              Text(
                '${_event.label} · ${_style.label}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: kMutedTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (plan.isEmpty)
            Text(
              '请输入有效的目标完赛时间后查看分段用时。',
              style: theme.textTheme.bodyLarge?.copyWith(color: kDangerColor),
            )
          else ...<Widget>[
            const _PlanRow(
              cells: <String>['段', '距离', '本段用时', '累计', '配速/km'],
              flex: _rowFlex,
              isHeader: true,
            ),
            const Divider(height: 1),
            ...plan.map((PaceSegment segment) {
              return _PlanRow(
                cells: <String>[
                  '${segment.index}',
                  '${segment.distanceMeters}m',
                  formatSegmentSeconds(segment.durationSeconds),
                  formatSegmentSeconds(segment.cumulativeSeconds),
                  formatPace(segment.paceSecondsPerKm),
                ],
                flex: _rowFlex,
                isHeader: false,
              );
            }),
            const SizedBox(height: 8),
            Text(
              '分段用时按目标总时间等比拆分，四舍五入到 0.1 秒，实际执行时可忽略极小误差。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: kMutedTextColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.cells,
    required this.flex,
    required this.isHeader,
  });

  final List<String> cells;
  final List<int> flex;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < cells.length; i++)
            Expanded(
              flex: flex[i],
              child: Text(
                cells[i],
                style: isHeader
                    ? theme.textTheme.titleMedium?.copyWith(
                        color: kPrimaryColor,
                      )
                    : theme.textTheme.bodyLarge?.copyWith(color: kTextColor),
              ),
            ),
        ],
      ),
    );
  }
}
