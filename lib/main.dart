import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ★ Hive 初期化（Web対応）
  await Hive.initFlutter();

  // ログ用
  await Hive.openBox('learning_logs');

  // ★ タスク保存用 Box
  await Hive.openBox('tasks');

  runApp(const StudyFlowApp());
}

class StudyFlowApp extends StatelessWidget {
  const StudyFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.tealAccent,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFDF6F0),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFB2DFDB),
          foregroundColor: Colors.black,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFFFCCBC),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
