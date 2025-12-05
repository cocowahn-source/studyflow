import 'package:hive_flutter/hive_flutter.dart';
import 'task.dart';

class TaskManager {
  final List<Task> _tasks = [];

  // ★ タスク保存用 Box
  final Box _box = Hive.box('tasks');

  TaskManager() {
    _loadFromHive();
  }

  void _loadFromHive() {
    _tasks.clear();
    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw is Map) {
        final task = Task.fromMap(Map<dynamic, dynamic>.from(raw));
        _tasks.add(task);
      }
    }

    print("Loaded tasks count: ${_tasks.length}");
  }

  List<Task> get allTasks => _tasks;

  void _saveToHive(Task task) {
    _box.put(task.id, task.toMap());
  }

  void addTask(Task task) {
    _tasks.add(task);
    _saveToHive(task);
  }

  void updateTask(Task task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
    }
    _saveToHive(task);
  }

  void deleteTask(Task task) {
    _tasks.removeWhere((t) => t.id == task.id);
    _box.delete(task.id);
  }
}
