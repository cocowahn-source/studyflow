import 'package:flutter/material.dart';
import 'package:study_flow/models/log_manager.dart';
import 'package:study_flow/models/task_manager.dart';
import 'task_list_screen.dart';
import 'home_tab.dart';
import 'status_screen.dart';
import '../models/subject.dart';
import 'package:uuid/uuid.dart';
import 'stopwatch_screen.dart';
import 'subject_edit_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final TaskManager taskManager = TaskManager();
  final LogManager logManager = LogManager();

  late Box _subjectsBox;

  late List<Subject> subjects = [];

  @override
  void initState() {
    super.initState();
    _subjectsBox = Hive.box('subjects');
    _loadSubjects();
  }

  void _loadSubjects() {
    try {
      final saved = _subjectsBox.get('subjects'); // 何もなければ null

      if (saved is List) {
        subjects = saved.map((e) {
          if (e is Map) {
            return Subject.fromMap(Map<dynamic, dynamic>.from(e));
          } else {
            throw Exception('Invalid subject data element: $e');
          }
        }).toList();
      } else {
        _setDefaultSubjects();
      }
    } catch (e) {
      print('Failed to load subjects: $e');
      _setDefaultSubjects();
    }
  }

  void _setDefaultSubjects() {
    subjects = [
      Subject(
        id: const Uuid().v4(),
        name: "英語",
        goalType: GoalType.time,
        goalAmount: 600,
        deadline: DateTime.now().add(const Duration(days: 30)),
        color: Subject.presetColors[0],
      ),
      Subject(
        id: const Uuid().v4(),
        name: "数学",
        goalType: GoalType.time,
        goalAmount: 600,
        deadline: DateTime.now().add(const Duration(days: 30)),
        color: Subject.presetColors[1],
      ),
    ];
    _saveSubjects();
  }

  void _saveSubjects() {
    final data = subjects.map((s) => s.toMap()).toList();
    _subjectsBox.put('subjects', data);
  }

  void _addSubject(String name) {
    setState(() {
      final nextColor =
          Subject.presetColors[subjects.length % Subject.presetColors.length];

      subjects.add(
        Subject(
          id: const Uuid().v4(),
          name: name,
          goalType: GoalType.time,
          goalAmount: 600,
          deadline: DateTime.now().add(const Duration(days: 30)),
          color: nextColor,
        ),
      );
      _saveSubjects();
    });
  }

  void _removeSubject(String id) {
    setState(() {
      subjects.removeWhere((s) => s.id == id);
      _saveSubjects();
    });
  }

  PreferredSizeWidget _buildAppBar() {
    const barColor = Color(0xFFB2DFDB);

    if (_selectedIndex == 1) {
      // タスクタブ：タイトルを表示
      return AppBar(
        backgroundColor: barColor,
        title: const Text('タスク一覧'),
        centerTitle: false,
      );
    } else {
      // ホーム & 統計タブ：うす緑のラインだけ
      return AppBar(
        backgroundColor: barColor,
        toolbarHeight: 4, // 細いラインにする
        elevation: 0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeTab(
        subjects: subjects,
        tasks: taskManager.allTasks,
        logManager: logManager,
      ),
      TaskListScreen(taskManager: taskManager),
      StatusScreen(
        subjects: subjects,
        logManager: logManager,
      ),
    ];

    return Scaffold(
      appBar: _buildAppBar(),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              child: Text(
                'メニュー',
                style: TextStyle(fontSize: 20),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('科目の編集'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SubjectEditScreen(
                      subjects: subjects,
                      onAddSubject: _addSubject,
                      onRemoveSubject: _removeSubject,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: screens[_selectedIndex],

      // ホームタブだけストップウォッチボタン
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StopwatchScreen(
                      subjects: subjects,
                      logManager: logManager,
                      onStudyRecorded: (_) => setState(() {}),
                    ),
                  ),
                );
              },
              backgroundColor: Colors.teal,
              child: const Icon(
                Icons.timer,
                color: Colors.white,
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

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
