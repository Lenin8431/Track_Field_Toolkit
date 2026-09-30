String _two(int value) => value.toString().padLeft(2, '0');

/// 秒表格式：不足 1 小时为 MM:SS.CC，超过 1 小时为 H:MM:SS.CC（精确到 0.01 秒）。
String formatStopwatch(Duration duration) {
  final int millis = duration.inMilliseconds < 0 ? 0 : duration.inMilliseconds;
  final int centiseconds = (millis ~/ 10) % 100;
  final int totalSeconds = millis ~/ 1000;
  final int seconds = totalSeconds % 60;
  final int minutes = (totalSeconds ~/ 60) % 60;
  final int hours = totalSeconds ~/ 3600;
  if (hours > 0) {
    return '$hours:${_two(minutes)}:${_two(seconds)}.${_two(centiseconds)}';
  }
  return '${_two(minutes)}:${_two(seconds)}.${_two(centiseconds)}';
}

String formatDuration(Duration duration) => formatStopwatch(duration);

/// 分段用时 / 配速格式，例如 1:02.4。
String formatSegmentSeconds(double seconds) {
  if (seconds <= 0 || !seconds.isFinite) {
    return '--';
  }
  final int totalTenths = (seconds * 10).round();
  final int tenths = totalTenths % 10;
  final int totalSeconds = totalTenths ~/ 10;
  final int sec = totalSeconds % 60;
  final int min = (totalSeconds ~/ 60) % 60;
  final int hour = totalSeconds ~/ 3600;
  if (hour > 0) {
    return '$hour:${_two(min)}:${_two(sec)}.$tenths';
  }
  return '$min:${_two(sec)}.$tenths';
}

String formatPace(double secondsPerKm) => formatSegmentSeconds(secondsPerKm);

String formatDateTime(DateTime time) {
  return '${time.year}-${_two(time.month)}-${_two(time.day)} '
      '${_two(time.hour)}:${_two(time.minute)}';
}

/// 解析目标完赛时间，支持 "30:00"、"1:05:00"、"95"（秒）。
double? parseTimeToSeconds(String input) {
  final String text = input.trim();
  if (text.isEmpty) {
    return null;
  }
  final List<String> parts = text.split(':');
  if (parts.length > 3) {
    return null;
  }
  final List<double> numbers = <double>[];
  for (final String part in parts) {
    final double? value = double.tryParse(part.trim());
    if (value == null || value < 0) {
      return null;
    }
    numbers.add(value);
  }

  double seconds;
  if (numbers.length == 1) {
    seconds = numbers[0];
  } else if (numbers.length == 2) {
    seconds = numbers[0] * 60 + numbers[1];
  } else {
    seconds = numbers[0] * 3600 + numbers[1] * 60 + numbers[2];
  }
  if (seconds <= 0) {
    return null;
  }
  return seconds;
}
