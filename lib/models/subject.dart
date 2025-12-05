import 'package:flutter/material.dart';

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
  int totalStudyMinutes;

  /// ★ 追加：科目カラー（ARGB int）
  int color;

  Subject({
    required this.id,
    required this.name,
    required this.goalType,
    required this.goalAmount,
    this.progressAmount = 0,
    required this.deadline,
    this.totalStudyMinutes = 0,
    required this.color,
  });

  /// Flutter の Color 型に変換
  Color get colorObj => Color(color);

  /// Hive 保存用：Subject → Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'goalType': goalType.index,
      'goalAmount': goalAmount,
      'progressAmount': progressAmount,
      'deadline': deadline.toIso8601String(),
      'totalStudyMinutes': totalStudyMinutes,
      'color': color,
    };
  }

  /// Hive 保存用：Map → Subject
  static Subject fromMap(Map<dynamic, dynamic> map) {
    // ★ deadline は String のことも DateTime のこともあるので分岐
    final rawDeadline = map['deadline'];
    DateTime deadline;
    if (rawDeadline is String) {
      deadline = DateTime.parse(rawDeadline);
    } else if (rawDeadline is DateTime) {
      deadline = rawDeadline;
    } else {
      // もし何かおかしい型だった場合の保険
      deadline = DateTime.now();
    }

    // --- goalType: int じゃない可能性もあるので保険 ---
    final rawGoalType = map['goalType'];
    GoalType goalType;
    if (rawGoalType is int && rawGoalType >= 0 && rawGoalType < GoalType.values.length) {
      goalType = GoalType.values[rawGoalType];
    } else if (rawGoalType is String) {
      // 以前 String で保存していた場合の救済
      goalType = GoalType.values.firstWhere(
        (g) => g.toString() == rawGoalType,
        orElse: () => GoalType.time,
      );
    } else {
      goalType = GoalType.time;
    }

    return Subject(
      id: map['id'] ?? '', 
      name: map['name'] ?? '',
      goalType: goalType,
      goalAmount: (map['goalAmount'] ?? 0).toDouble(),
      progressAmount: (map['progressAmount'] ?? 0).toDouble(),
      deadline: deadline,
      totalStudyMinutes: map['totalStudyMinutes'] ?? 0,
      color: map['color'] ?? Colors.grey.value,  // 古いデータにも対応
    );
  }

  /// 科目カラーのプリセット（好きに変更OK）
  static List<int> presetColors = [
    Colors.redAccent.value,
    Colors.blueAccent.value,
    Colors.green.value,
    Colors.orange.value,
    Colors.purple.value,
    Colors.teal.value,
    Colors.pinkAccent.value,
  ];
}