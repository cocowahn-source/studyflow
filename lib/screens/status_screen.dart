import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:study_flow/models/log_manager.dart';
import '../models/subject.dart';
import 'package:study_flow/models/learning_log.dart';

class StatusScreen extends StatelessWidget {
  final List<Subject> subjects;
  final LogManager logManager;

  const StatusScreen({
    super.key,
    required this.subjects,
    required this.logManager,
  });

  /// 今日の合計時間
  int getTodayMinutes() {
    if (logManager.allLogs.isEmpty) return 0;

    final latestEntry = logManager.allLogs.entries.reduce(
      (a,b) => a.key.isAfter(b.key) ? a : b,
    );

    return latestEntry.value.totalMinutes;
  }


  /// 今週の 7 日分のデータ取得
  List<int> getWeeklyMinutes() {
    final now = DateTime.now();
    List<int> week = [];

    for (int i = 0; i < 7; i++) {
      final day = DateTime(now.year, now.month, now.day - i);
      final log = logManager.allLogs[LearningLog.normalizeDate(day)];
      week.add(log?.totalMinutes ?? 0);
    }

    return week.reversed.toList(); // 古い→新しい順
  }

  /// 今月の日別データ
  List<FlSpot> getMonthlySpots() {
    final now = DateTime.now();
    List<FlSpot> spots = [];

    for (int d = 1; d <= now.day; d++) {
      final date = DateTime(now.year, now.month, d);
      final log = logManager.allLogs[LearningLog.normalizeDate(date)];
      final minutes = log?.totalMinutes ?? 0;

      spots.add(FlSpot(d.toDouble(), minutes.toDouble()));
    }

    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final today = getTodayMinutes();
    final weekly = getWeeklyMinutes();
    final monthly = getMonthlySpots();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ★ 今日の総勉強時間カード
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7F2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("今日の勉強時間",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  "${today ~/ 60} 時間 ${today % 60} 分",
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // ★ 今週の棒グラフ
          const Text("今週の勉強時間（分）",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                barGroups: [
                  for (int i = 0; i < weekly.length; i++)
                    BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: weekly[i].toDouble(),
                        color: Colors.teal,
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                      )
                    ])
                ],
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
              ),
            ),
          ),

          const SizedBox(height: 30),

          // ★ 今月の折れ線グラフ
          const Text("今月の日別勉強時間（分）",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: monthly,
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                ],
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
