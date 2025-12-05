import 'package:flutter/material.dart';
import 'package:study_flow/models/log_manager.dart';
import 'package:study_flow/models/task_manager.dart';
import 'task_list_screen.dart';
import 'home_tab.dart';
import 'status_screen.dart';
import '../models/subject.dart';
import 'package:uuid/uuid.dart';
import 'stopwatch_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final TaskManager taskManager = TaskManager();
  final LogManager logManager = LogManager(); // ★ ここで1個だけ作る

  final List<Subject> subjects = [
    Subject(
      id: const Uuid().v4(),
      name: "英語",
      goalType: GoalType.time,
      goalAmount: 600,
      deadline: DateTime.now().add(const Duration(days: 30)),
    ),
    Subject(
      id: const Uuid().v4(),
      name: "数学",
      goalType: GoalType.time,
      goalAmount: 600,
      deadline: DateTime.now().add(const Duration(days: 30)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeTab(
        subjects: subjects,
        tasks: taskManager.allTasks,
        onStartStopwatch: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StopwatchScreen(
                subjects: subjects,
                logManager: logManager,                 // ★ 同じ logManager を渡す
                onStudyRecorded: (_) => setState(() {}),
              ),
            ),
          );
        },
        logManager: logManager,                        // ★ HomeTab にも同じ logManager
      ),
      TaskListScreen(taskManager: taskManager),
      StatusScreen(
        subjects: subjects,
        logManager: logManager,                        // ★ StatusScreen にも同じ logManager
      ),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "ホーム",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: "タスク",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: "統計",
          ),
        ],
      ),
    );
  }
}
