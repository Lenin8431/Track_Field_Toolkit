import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const TrackToolkitApp());
}

class TrackToolkitApp extends StatelessWidget {
  const TrackToolkitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '田径通用工具',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const HomeScreen(),
    );
  }
}
