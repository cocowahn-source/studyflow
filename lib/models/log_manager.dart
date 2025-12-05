import 'package:hive_flutter/hive_flutter.dart';
import 'learning_log.dart';

class LogManager {
  final Map<DateTime, LearningLog> _logs = {};

  // ★ Hive の Box
  final Box _box = Hive.box('learning_logs');

  LogManager() {
    _loadFromHive();
  }

  /// ★ 起動時に Hive から全ログ読み込み
  void _loadFromHive() {
    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw is Map) {
        final log = LearningLog.fromMap(Map<dynamic, dynamic>.from(raw));
        final normalized = LearningLog.normalizeDate(log.date);
        _logs[normalized] = log;
      }
    }

    // ★ 読み込んだ件数を表示
    print('Loaded logs count: ${_logs.length}');
  }

  /// ★ 1件のログを Hive に保存
  void _saveToHive(LearningLog log) {
    final key = LearningLog.keyFromDate(log.date);
    _box.put(key, log.toMap());
    print('Saved log for $key : ${log.totalMinutes} 分');
  }

  /// 今日のログを返す（なければ作成）
  LearningLog getTodayLog() {
    final today = LearningLog.normalizeDate(DateTime.now());

    if (!_logs.containsKey(today)) {
      _logs[today] = LearningLog(date: today);
      _saveToHive(_logs[today]!);
    }

    return _logs[today]!;
  }

  /// 勉強時間（分）を追加
  void addStudyTime(String subjectName, int minutes) {
    final log = getTodayLog();
    log.timeBySubject[subjectName] =
        (log.timeBySubject[subjectName] ?? 0) + minutes;
    _saveToHive(log);
  }

  /// タスク実績（ページ/回）を追加
  void addTaskProgress(String taskTitle, int amount) {
    final log = getTodayLog();
    log.amountByTask[taskTitle] =
        (log.amountByTask[taskTitle] ?? 0) + amount;
    _saveToHive(log);
  }

  /// ログ全体（STATUS 画面用）
  Map<DateTime, LearningLog> get allLogs => _logs;
}
