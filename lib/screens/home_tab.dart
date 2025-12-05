import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../models/task.dart';
import 'package:study_flow/models/log_manager.dart';

class HomeTab extends StatefulWidget {
  final List<Subject> subjects;
  final List<Task> tasks;
  final VoidCallback onStartStopwatch;
  final LogManager logManager;

  const HomeTab({
    super.key,
    required this.subjects,
    required this.tasks,
    required this.onStartStopwatch,
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

  /// パステルカード（共通UI）
  Widget pastelCard({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(20),
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F2),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: child,
    );
  }

  /// 🔥 今日やる計画タスク一覧（今日実行日のものだけ）
  List<Widget> _buildTodayTaskWidgets(BuildContext context) {
    final todayTasks = widget.tasks.where((task) {
      return task.isPlanned &&
          task.dueDate != null &&
          task.isTodayExecutionDate();
    }).toList();

    if (todayTasks.isEmpty) {
      return const [
        Text("今日やるべき計画タスクはありません"),
      ];
    }

    return todayTasks.map((task) {
      final todayPlan = task.todayAmount; // 今日のノルマ（残り全体 / 残り日数）
      final doneToday = _getTodayDoneForTask(task);
      final remainingToday = (todayPlan - doneToday).clamp(0, double.infinity);

      final unit = task.unit ?? "";

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 3,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // タスク名 + 今日のノルマ & 進捗
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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

            // 進捗入力ボタン
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB2DFDB),
              ),
              onPressed: () {
                _showDoneDialog(task, context);
              },
              child: const Text("進捗を記録"),
            ),
          ],
        ),
      );
    }).toList();
  }

  /// 🔥 もうすぐ締切の通常タスク（isPlanned = false）
  List<Widget> _buildUpcomingDeadlineTasks() {
    final normalTasks = widget.tasks.where((task) {
      return !task.isPlanned && task.dueDate != null;
    }).toList();

    if (normalTasks.isEmpty) {
      return const [
        Text("締切が近い通常タスクはありません"),
      ];
    }

    // 期限が近い順にソート
    normalTasks.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

    final top3 = normalTasks.take(3).toList();

    return top3.map((task) {
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

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 3,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // タスク名 + 期限
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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

            // チェックボックス（完了済みかどうか）
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
    }).toList();
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
          pastelCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "今日の勉強時間",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  "$todayHours 時間 $todayRemainMinutes 分",
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // 今日の計画タスク
          pastelCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "今日のタスク（計画）",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ..._buildTodayTaskWidgets(context),
              ],
            ),
          ),

          // もうすぐ締切の通常タスク
          pastelCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "もうすぐ締切のタスク（通常）",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ..._buildUpcomingDeadlineTasks(),
              ],
            ),
          ),

          // ストップウォッチ開始ボタン
          pastelCard(
            padding: const EdgeInsets.all(30),
            child: Center(
              child: ElevatedButton(
                onPressed: widget.onStartStopwatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB2DFDB),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 40,
                  ),
                ),
                child: const Text(
                  "ストップウォッチを開始",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
