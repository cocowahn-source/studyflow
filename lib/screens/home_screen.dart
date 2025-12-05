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

  late List<Subject> subjects = [
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

    @override
  void initState() {
    super.initState();
    // main.dart で openBox 済みなので、そのインスタンスを取得するだけ
    _subjectsBox = Hive.box('subjects');
    _loadSubjects();
  }

void _loadSubjects() {
  try {
    final saved = _subjectsBox.get('subjects'); // 何もなければ null

    if (saved is List) {
      subjects = saved.map((e) {
        if (e is Map) {
          // fromMap 内部で DateTime / String 両方対応
          return Subject.fromMap(Map<dynamic, dynamic>.from(e));
        } else {
          throw Exception('Invalid subject data element: $e');
        }
      }).toList();
    } else {
      // 型が List じゃない場合も含めてデフォルトに戻す
      _setDefaultSubjects();
    }
  } catch (e) {
    // ここに来たら一旦全部捨ててデフォルトに戻す
    print('Failed to load subjects: $e');
    _setDefaultSubjects();
  }
}

/// デフォルト科目を設定して保存
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
      final nextColor = Subject.presetColors[
        subjects.length % Subject.presetColors.length
      ];
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
      appBar: AppBar(
        title: const Text('StudyFlow'),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
      ),
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
                Navigator.pop(context); // Drawer を閉じる
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
              backgroundColor: Colors.teal, // ティール色
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
