import 'package:flutter/material.dart';

import '../app_info.dart';
import '../theme/app_theme.dart';
import 'history_screen.dart';
import 'pace_screen.dart';
import 'timer_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          children: <Widget>[
            Text(
              kAppDisplayName,
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 6),
            Text(
              '跑圈计时 · 比赛配速模拟',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: kMutedTextColor),
            ),
            const SizedBox(height: 20),
            _ModuleCard(
              title: '跑圈计时',
              subtitle: '开始 / 暂停 / 休息计时 / 计圈 / 结束，自动记录每一圈用时并保存到本地。',
              actionText: '进入计时',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => const TimerScreen(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _ModuleCard(
              title: '中距离比赛配速模拟器',
              subtitle: '800m - 10000m 目标完赛时间拆分为分段用时与配速表。',
              actionText: '开始模拟',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => const PaceScreen(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppCardButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => const HistoryScreen(),
                ),
              ),
            ),
            const SizedBox(height: 26),
            Center(
              child: Text(
                '版本 $kAppVersionName',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: kMutedTextColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final String actionText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: kPrimaryContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: kOnPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: kOnPrimaryContainer,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 58,
              child: ElevatedButton(
                onPressed: onPressed,
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
                child: Text(actionText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppCardButton extends StatelessWidget {
  const AppCardButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: const Color(0xFFE6EBF2),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '历史训练记录',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '查看本机保存的历次训练数据',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: kMutedTextColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(onPressed: onPressed, child: const Text('查看')),
          ],
        ),
      ),
    );
  }
}
