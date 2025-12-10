import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../models/task.dart';
import 'package:study_flow/models/log_manager.dart';

class HomeTab extends StatefulWidget {
  final List<Subject> subjects;
  final List<Task> tasks;
  final LogManager logManager;

  const HomeTab({
    super.key,
    required this.subjects,
    required this.tasks,
    required this.logManager,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  /// 今日（= 今日の日付のログ）の総勉強時間（分）
  int _getTodayMinutes() {
    if (widget.logManager.allLogs.isEmpty) return 0;
    final todayLog = widget.logManager.getTodayLog();
    return todayLog.totalMinutes;
  }

  /// 今日、そのタスクで記録した量（ページ/回など）
  int _getTodayDoneForTask(Task task) {
    final todayLog = widget.logManager.getTodayLog();
    return todayLog.amountByTask[task.title] ?? 0;
  }

  /// 進捗入力ダイアログ
  void _showDoneDialog(Task task, BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("${task.title} の進捗を記録"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "今日やった量（例：10）",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("キャンセル"),
          ),
          TextButton(
            onPressed: () {
              final v = int.tryParse(controller.text) ?? 0;
              if (v > 0) {
                setState(() {
                  task.progressAmount += v;
                  // ログにも反映
                  widget.logManager.addTaskProgress(task.title, v);
                });
              }
              Navigator.pop(context);
            },
            child: const Text("記録する"),
          ),
        ],
      ),
    );
  }

  /// 共通の白カード UI
  Widget _whiteCard({
    required String title,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(20),
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  /// 今日の計画タスク（今日実行日のものだけ）
  /// 今日のノルマを達成したタスクは表示しない
  /// 残りノルマが多い順にソート
  Widget _buildTodayTasksSection(BuildContext context) {
    // まずは「今日実行」の計画タスクだけ取ってくる
    final allTodayTasks = widget.tasks.where((task) {
      return task.isPlanned &&
          task.dueDate != null &&
          task.isTodayExecutionDate();
    }).toList();

    // 「今日のノルマ」を計算しつつ、達成済みは除外・残りノルマでソート
    final List<_TodayTaskInfo> todayInfos = [];

    for (final task in allTodayTasks) {
      final todayPlan = task.todayAmount; // 今日のノルマ
      final doneToday = _getTodayDoneForTask(task); // 今日やった量
      final remainingToday = todayPlan - doneToday;

      // ノルマを達成していればホームからは非表示
      if (remainingToday <= 0) continue;

      todayInfos.add(
        _TodayTaskInfo(
          task: task,
          todayPlan: todayPlan,
          doneToday: doneToday,
          remainingToday: remainingToday,
        ),
      );
    }

    if (todayInfos.isEmpty) {
      return const Text(
        "今日やるべき計画タスクはありません",
        style: TextStyle(color: Colors.grey),
      );
    }

    // 残りノルマが多い順にソート（大きい→小さい）
    todayInfos.sort(
      (a, b) => b.remainingToday.compareTo(a.remainingToday),
    );

    final List<Widget> rows = [];
    for (int i = 0; i < todayInfos.length; i++) {
      final info = todayInfos[i];
      final task = info.task;
      final unit = task.unit ?? "";

      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左側：タスク名 & ノルマ
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "今日のノルマ: ${info.todayPlan.toStringAsFixed(1)} $unit",
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    "今日やった: ${info.doneToday} $unit / 残り: ${info.remainingToday.toStringAsFixed(1)} $unit",
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            ElevatedButton(
              onPressed: () => _showDoneDialog(task, context),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              ),
              child: const Text(
                "進捗を記録",
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );

      if (i < todayInfos.length - 1) {
        rows.add(const Divider(
          height: 18,
          thickness: 1,
          color: Colors.black12,
        ));
      }
    }

    return Column(children: rows);
  }

  /// もうすぐ締切の通常タスク（isPlanned = false）
  Widget _buildUpcomingDeadlineSection() {
    final normalTasks = widget.tasks.where((task) {
      return !task.isPlanned && task.dueDate != null;
    }).toList();

    if (normalTasks.isEmpty) {
      return const Text(
        "締切が近い通常タスクはありません",
        style: TextStyle(color: Colors.grey),
      );
    }

    // 期限が近い順にソート
    normalTasks.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

    final top3 = normalTasks.take(3).toList();
    final List<Widget> rows = [];

    for (int i = 0; i < top3.length; i++) {
      final task = top3[i];
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final due = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
      );
      final daysLeft = due.difference(today).inDays;

      String label;
      if (daysLeft < 0) {
        label = "期限超過";
      } else if (daysLeft == 0) {
        label = "本日締切";
      } else {
        label = "あと$daysLeft日";
      }

      rows.add(
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "期限: ${task.dueDate!.toLocal().toString().split(' ')[0]}",
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            Checkbox(
              value: task.isCompleted,
              onChanged: (_) {
                setState(() {
                  task.isCompleted = !task.isCompleted;
                });
              },
            ),
          ],
        ),
      );

      if (i < top3.length - 1) {
        rows.add(const Divider(
          height: 18,
          thickness: 1,
          color: Colors.black12,
        ));
      }
    }

    return Column(children: rows);
  }

  @override
  Widget build(BuildContext context) {
    final todayMinutes = _getTodayMinutes();
    final todayHours = todayMinutes ~/ 60;
    final todayRemainMinutes = todayMinutes % 60;

    return SafeArea(
      child: ListView(
        children: [
          // 今日の勉強時間カード
          _whiteCard(
            title: "今日の勉強時間",
            child: Text(
              "$todayHours 時間 $todayRemainMinutes 分",
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 今日の計画タスク
          _whiteCard(
            title: "今日のタスク（計画）",
            child: _buildTodayTasksSection(context),
          ),

          // もうすぐ締切の通常タスク
          _whiteCard(
            title: "もうすぐ締切のタスク（通常）",
            child: _buildUpcomingDeadlineSection(),
          ),
        ],
      ),
    );
  }
}

/// 「今日のタスク」表示用の内部クラス
class _TodayTaskInfo {
  final Task task;
  final double todayPlan;
  final int doneToday;
  final double remainingToday;

  _TodayTaskInfo({
    required this.task,
    required this.todayPlan,
    required this.doneToday,
    required this.remainingToday,
  });
}
