class Task {
  String id;
  String title;

  // 締め切り
  DateTime? dueDate;

  // 計画タスクか？
  bool isPlanned;

  // 合計量（ページ数 or 回数）
  int? totalAmount;

  // 単位（ページ / 回）
  String? unit;

  // 曜日指定（0=月曜、6=日曜）
  List<int> weekdays;

  // 何日おき？（0 = 毎日）
  int intervalDays;

  // 普通のタスク用：完了状態
  bool isCompleted;

  /// ★ 実際にやった量（ユーザーが記録する量）
  int progressAmount;

  Task({
    required this.id,
    required this.title,
    this.dueDate,
    this.isCompleted = false,

    // 計画タスクの初期値
    this.isPlanned = false,
    this.totalAmount,
    this.unit,
    this.weekdays = const [],
    this.intervalDays = 0,

    this.progressAmount = 0,
  });

  /// 🔥 今日このタスクを実行する日か？
  bool isTodayExecutionDate() {
    final today = DateTime.now();

    // 🔷 曜日指定の場合（0=月,6=日）
    if (weekdays.isNotEmpty && !weekdays.contains((today.weekday - 1) % 7)) {
      return false;
    }

    // 🔷 n日おきの場合
    if (intervalDays > 0) {
      if (dueDate == null) return true;
      final start = DateTime(today.year, today.month, today.day);
      final diff = dueDate!.difference(start).inDays.abs();
      return diff % intervalDays == 0;
    }

    // 🔷 デフォルト（毎日）
    return true;
  }

  /// 🔥 締切までの日数（0未満は1日に切り上げ）
  int daysLeft() {
    if (dueDate == null) return 0;
    final diff = dueDate!.difference(DateTime.now()).inDays;
    return diff < 1 ? 1 : diff;
  }

  /// 🔥 今日やるべき量（残り量 ÷ 残り日数）
  double get todayAmount {
    if (!isPlanned || totalAmount == null) return 0;

    final remaining = totalAmount! - progressAmount;
    if (remaining <= 0) return 0;

    final remainingDays = daysLeft();
    return remaining / (remainingDays == 0 ? 1 : remainingDays);
  }

  /// ★ Hive保存用：Mapに変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'dueDate': dueDate?.toIso8601String(),
      'isPlanned': isPlanned,
      'totalAmount': totalAmount,
      'unit': unit,
      'weekdays': weekdays,
      'intervalDays': intervalDays,
      'isCompleted': isCompleted,
      'progressAmount': progressAmount,
    };
  }

  /// ★ Hiveから復元
  factory Task.fromMap(Map<dynamic, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'] as String)
          : null,
      isPlanned: (map['isPlanned'] ?? false) as bool,
      totalAmount: map['totalAmount'] as int?,
      unit: map['unit'] as String?,
      weekdays: List<int>.from(map['weekdays'] ?? const []),
      intervalDays: (map['intervalDays'] ?? 0) as int,
      isCompleted: (map['isCompleted'] ?? false) as bool,
      progressAmount: (map['progressAmount'] ?? 0) as int,
    );
  }
}
