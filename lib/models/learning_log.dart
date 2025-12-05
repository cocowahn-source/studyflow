class LearningLog {
  final DateTime date;

  /// 科目ごとの勉強時間（分）
  Map<String, int> timeBySubject;

  /// タスクごとの実績（ページ/回）
  Map<String, int> amountByTask;

  LearningLog({
    required this.date,
    Map<String, int>? timeBySubject,
    Map<String, int>? amountByTask,
  })  : timeBySubject = timeBySubject ?? {},
        amountByTask = amountByTask ?? {};

  /// 日付を 00:00:00 にそろえる
  static DateTime normalizeDate(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  /// ★ 合計勉強時間（分）
  int get totalMinutes {
    if (timeBySubject.isEmpty) return 0;
    return timeBySubject.values.fold(0, (a, b) => a + b);
  }

  /// ★ タスク進捗の合計
  int get totalAmount {
    if (amountByTask.isEmpty) return 0;
    return amountByTask.values.fold(0, (a, b) => a + b);
  }

  /// ★ Hive 保存用：Map に変換
  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'timeBySubject': timeBySubject,
      'amountByTask': amountByTask,
    };
  }

  /// ★ Hive から復元
  factory LearningLog.fromMap(Map<dynamic, dynamic> map) {
    return LearningLog(
      date: DateTime.parse(map['date'] as String),
      timeBySubject: Map<String, int>.from(
        (map['timeBySubject'] ?? {}) as Map,
      ),
      amountByTask: Map<String, int>.from(
        (map['amountByTask'] ?? {}) as Map,
      ),
    );
  }

  /// ★ Box のキー用（同じ日を同じキーにする）
  static String keyFromDate(DateTime dt) {
    final n = normalizeDate(dt);
    return n.toIso8601String(); // "2025-11-23T00:00:00.000"
  }
}
