import 'package:flutter/material.dart';
import 'package:study_flow/models/task_manager.dart';
import '../models/task.dart';
import 'add_task_screen.dart';

class TaskListScreen extends StatefulWidget {
  final TaskManager taskManager;

  const TaskListScreen({super.key, required this.taskManager});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  void _addTask(Task task) {
    setState(() {
      widget.taskManager.addTask(task);
    });
  }

  void _updateTask(Task task) {
    setState(() {
      widget.taskManager.updateTask(task);
    });
  }

  void _toggleTaskCompletion(Task task) {
    setState(() {
      task.isCompleted = !task.isCompleted;
      widget.taskManager.updateTask(task);
    });
  }

  void _navigateToAddTask() async {
    final newTask = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddTaskScreen()),
    );
    if (newTask != null && newTask is Task) {
      _addTask(newTask);
    }
  }

  void _navigateToEditTask(Task task) async {
    final updatedTask = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTaskScreen(existingTask: task),
      ),
    );
    if (updatedTask != null && updatedTask is Task) {
      _updateTask(updatedTask);
    }
  }

  /// 計画内容の説明テキスト
  String _buildPlanDescription(Task task) {
    if (!task.isPlanned || task.totalAmount == null) return "";

    final base = "合計 ${task.totalAmount} ${task.unit ?? ""}".trim();

    if (task.weekdays.isNotEmpty) {
      const labels = ["月", "火", "水", "木", "金", "土", "日"];
      final days = task.weekdays.map((i) => labels[i]).join("・");
      return "$base / 曜日指定：$days";
    }

    if (task.intervalDays > 0) {
      return "$base / ${task.intervalDays}日おき";
    }

    return "$base / 毎日";
  }

  @override
  Widget build(BuildContext context) {
    final tasks = widget.taskManager.allTasks;

    return Column(
      children: [
        Container(
          color: const Color(0xFFB2DFDB),
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          child: const Text(
            "タスク一覧",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: tasks.isEmpty
              ? const Center(
                  child: Text(
                    'まだタスクがありません',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final isPlanned = task.isPlanned;
                    final planText = _buildPlanDescription(task);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: task.isCompleted
                          ? Colors.green[50]
                          : Colors.white,
                      child: ListTile(
                        onTap: () => _navigateToEditTask(task), // ★ タップで編集
                        title: Text(
                          task.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 4, bottom: 2),
                              child: Text(
                                isPlanned ? "計画タスク" : "通常タスク",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isPlanned
                                      ? Colors.deepPurple
                                      : Colors.grey[700],
                                ),
                              ),
                            ),
                            if (isPlanned && planText.isNotEmpty)
                              Text(
                                planText,
                                style: const TextStyle(fontSize: 12),
                              ),
                            if (task.dueDate != null)
                              Text(
                                "期限: ${task.dueDate!.toLocal().toString().split(' ')[0]}",
                                style: const TextStyle(fontSize: 12),
                              ),
                          ],
                        ),
                        trailing: Checkbox(
                          value: task.isCompleted,
                          onChanged: (_) => _toggleTaskCompletion(task),
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: FloatingActionButton(
            onPressed: _navigateToAddTask,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
