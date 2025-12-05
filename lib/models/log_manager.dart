import 'package:hive_flutter/hive_flutter.dart';
import 'learning_log.dart';

class LogManager {
  final Map<DateTime, LearningLog> _logs = {};

  final Box _box = Hive.box('learning_logs');

  LogManager() {
    _loadFromHive();
  }

  void _loadFromHive() {
    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw is Map) {
        final log = LearningLog.fromMap(Map<dynamic, dynamic>.from(raw));
        final normalized = LearningLog.normalizeDate(log.date);
        _logs[normalized] = log;
      }
    }

    print('Loaded logs count: ${_logs.length}');
  }

  void _saveToHive(LearningLog log) {
    final key = LearningLog.keyFromDate(log.date);
    _box.put(key, log.toMap());
    print('Saved log for $key : ${log.totalMinutes} 分');
  }

  LearningLog getTodayLog() {
    final today = LearningLog.normalizeDate(DateTime.now());

    if (!_logs.containsKey(today)) {
      _logs[today] = LearningLog(date: today);
      _saveToHive(_logs[today]!);
    }

    return _logs[today]!;
  }

  void addStudyTime(String subjectName, int minutes) {
    final log = getTodayLog();
    log.timeBySubject[subjectName] =
        (log.timeBySubject[subjectName] ?? 0) + minutes;
    _saveToHive(log);
  }

  void addTaskProgress(String taskTitle, int amount) {
    final log = getTodayLog();
    log.amountByTask[taskTitle] =
        (log.amountByTask[taskTitle] ?? 0) + amount;
    _saveToHive(log);
  }

  Map<DateTime, LearningLog> get allLogs => _logs;

  // ----------------------------------------------------------------------
  // ★ 追加した便利メソッド
  // ----------------------------------------------------------------------

  /// 今日の科目別勉強時間（例： {"英語": 30, "数学": 20}）
  Map<String, int> getTodayMinutesBySubject() {
    final todayLog = getTodayLog();
    return Map<String, int>.from(todayLog.timeBySubject);
  }

  /// 全期間の科目別合計勉強時間（例： {"英語": 120, "数学": 90}）
  Map<String, int> getTotalMinutesBySubject() {
    final Map<String, int> totals = {};

    for (final log in _logs.values) {
      log.timeBySubject.forEach((subject, minutes) {
        totals[subject] = (totals[subject] ?? 0) + minutes;
      });
    }

    return totals;
  }

  /// 直近7日間の日付 → 合計勉強時間
  Map<DateTime, int> getLast7DaysTotalMinutes() {
    final Map<DateTime, int> results = {};

    final now = DateTime.now();

    for (int i = 0; i < 7; i++) {
      final date = LearningLog.normalizeDate(
        DateTime(now.year, now.month, now.day - i),
      );

      final log = _logs[date];
      final total = log?.timeBySubject.values.fold(0, (a, b) => a + b) ?? 0;

      results[date] = total;
    }

    return results;
  }
}
