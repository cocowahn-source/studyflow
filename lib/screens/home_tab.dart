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
  /// 今日（≒一番新しいログ）の勉強時間（分）
  int _getTodayMinutes() {
    if (widget.logManager.allLogs.isEmpty) return 0;

    final latestEntry = widget.logManager.allLogs.entries.reduce(
      (a, b) => a.key.isAfter(b.key) ? a : b,
    );

    return latestEntry.value.totalMinutes;
  }

  /// 今日、そのタスクで記録した量（ページ/回）
  int _getTodayDoneForTask(Task task) {
    final todayLog = widget.logManager.getTodayLog();
    return todayLog.amountByTask[task.title] ?? 0;
  }

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

  /// 共通：白カードUI
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 3),
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
  Widget _buildTodayTasksSection(BuildContext context) {
    final todayTasks = widget.tasks.where((task) {
      return task.isPlanned &&
          task.dueDate != null &&
          task.isTodayExecutionDate();
    }).toList();

    if (todayTasks.isEmpty) {
      return const Text(
        "今日やるべき計画タスクはありません",
        style: TextStyle(color: Colors.grey),
      );
    }

    final List<Widget> rows = [];
    for (int i = 0; i < todayTasks.length; i++) {
      final task = todayTasks[i];
      final todayPlan = task.todayAmount;
      final doneToday = _getTodayDoneForTask(task);
      final remainingToday =
          (todayPlan - doneToday).clamp(0, double.infinity);

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
                    "今日のノルマ: ${todayPlan.toStringAsFixed(1)} $unit",
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    "今日やった: $doneToday $unit / 残り: ${remainingToday.toStringAsFixed(1)} $unit",
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _showDoneDialog(task, context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    vertical: 8, horizontal: 12),
              ),
              child: const Text(
                "進捗を記録",
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );

      if (i < todayTasks.length - 1) {
        rows.add(const Divider(
          height: 18,
          thickness: 1,
          color: Colors.black12,
        ));
      }
    }

    return Column(children: rows);
  }

  /// もうすぐ締切の通常タスク
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左側
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
                    style: const TextStyle(fontSize: 12, color: Colors.red),
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

          _whiteCard(
            title: "今日のタスク（計画）",
            child: _buildTodayTasksSection(context),
          ),

          _whiteCard(
            title: "もうすぐ締切のタスク（通常）",
            child: _buildUpcomingDeadlineSection(),
          ),
        ],
      ),
    );
  }
}
