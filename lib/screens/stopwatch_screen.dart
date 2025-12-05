import 'dart:async';
import 'package:flutter/material.dart';
import 'package:study_flow/models/log_manager.dart';
import '../models/subject.dart';

class StopwatchScreen extends StatefulWidget {
  final List<Subject> subjects;
  final LogManager logManager;
  final Function(List<Subject>) onStudyRecorded;

  const StopwatchScreen({
    super.key,
    required this.subjects,
    required this.logManager,
    required this.onStudyRecorded,
  });

  @override
  State<StopwatchScreen> createState() => _StopwatchScreenState();
}

class _StopwatchScreenState extends State<StopwatchScreen> {
  late Timer _timer;
  late Stopwatch _stopwatch;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_stopwatch.isRunning) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _format(int ms) {
    final seconds = (ms / 1000).floor();
    final minutes = seconds ~/ 60;
    final remSec = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${remSec.toString().padLeft(2, '0')}";
  }

  /// ★ 学習時間の記録処理
  void _recordStudyTime() async {
    final ms = _stopwatch.elapsedMilliseconds;
    final minutes = (ms / 60000).floor(); // 分に変換

    if (minutes == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("1分以上計測してください")),
      );
      return;
    }

    Subject? selected;

    // ▼ 科目選択ダイアログ
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("科目を選択"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: widget.subjects.map((subject) {
                return ListTile(
                  title: Text(subject.name),
                  onTap: () {
                    selected = subject;
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );

    if (selected != null) {
      // ★ ログ記録
      widget.logManager.addStudyTime(selected!.name, minutes);

      // UI 更新
      widget.onStudyRecorded(widget.subjects);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${selected!.name} に $minutes 分を記録しました！")),
      );

      // ★ ストップウォッチリセット
      _stopwatch.reset();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final time = _format(_stopwatch.elapsedMilliseconds);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB2DFDB),
        title: const Text(
          "ストップウォッチ",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // ★ ホーム（前の画面）に戻る
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              time,
              style: const TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),

            // ボタン群
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed:
                      _stopwatch.isRunning ? null : _stopwatch.start,
                  child: const Text("開始"),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _stopwatch.isRunning
                      ? () {
                          _stopwatch.stop();
                          setState(() {});
                        }
                      : null,
                  child: const Text("停止"),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    _stopwatch.reset();
                    setState(() {});
                  },
                  child: const Text("リセット"),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ★ 記録ボタン
            ElevatedButton(
              onPressed: _stopwatch.isRunning ? null : _recordStudyTime,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
              ),
              child: const Text("この時間を記録"),
            ),
          ],
        ),
      ),
    );
  }
}
