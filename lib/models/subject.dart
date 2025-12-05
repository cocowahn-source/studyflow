enum GoalType {
  time,
  pages,
  tasks,
}

class Subject {
  String id;
  String name;
  GoalType goalType;
  double goalAmount;
  double progressAmount;
  DateTime deadline;

  /// ★追加：累積学習時間（分）
  int totalStudyMinutes;

  Subject({
    required this.id,
    required this.name,
    required this.goalType,
    required this.goalAmount,
    this.progressAmount = 0,
    required this.deadline,

    /// ★追加部分（初期値0）
    this.totalStudyMinutes = 0,
  });

  /// ★追加：ストップウォッチの記録を保存
  void addStudyMinutes(int minutes) {
    totalStudyMinutes += minutes;
  }

  /// 既存：1日の目標（変更なし）
  double get dailyTarget {
    final daysLeft = deadline.difference(DateTime.now()).inDays;
    if (daysLeft <= 0) return 0;
    final remaining = goalAmount - progressAmount;
    return remaining / daysLeft;
  }
}
