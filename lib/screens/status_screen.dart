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

  /// 今日の総勉強時間
  int getTodayMinutes() {
    if (logManager.allLogs.isEmpty) return 0;

    final today = LearningLog.normalizeDate(DateTime.now());
    final log = logManager.allLogs[today];
    return log?.totalMinutes ?? 0;
  }

  /// 今週の7日分（古い→新しい順）
  List<int> getWeeklyMinutes() {
    final now = DateTime.now();
    List<int> week = [];

    for (int i = 0; i < 7; i++) {
      final day = DateTime(now.year, now.month, now.day - i);
      final log = logManager.allLogs[LearningLog.normalizeDate(day)];
      week.add(log?.totalMinutes ?? 0);
    }

    return week.reversed.toList();
  }

  /// 今月の日別データ（1日〜今日）
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
    final todayTotal = getTodayMinutes();
    final weekly = getWeeklyMinutes();
    final monthly = getMonthlySpots();
    final todayBySubject = logManager.getTodayMinutesBySubject();
    final totalBySubject = logManager.getTotalMinutesBySubject();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ① 今日の総勉強時間（カード）
          _whiteCard(
            title: "今日の総勉強時間",
            child: Text(
              "${todayTotal ~/ 60} 時間 ${todayTotal % 60} 分",
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 20),

          // ② 今日の科目別勉強時間（カードの中で線区切り）
          _whiteCard(
            title: "今日の科目別勉強時間",
            child: todayBySubject.isEmpty
                ? const Text(
                    "今日はまだ記録がありません",
                    style: TextStyle(color: Colors.grey),
                  )
                : Column(
                    children: _buildSeparatedList(todayBySubject),
                  ),
          ),

          const SizedBox(height: 20),

          // ③ 今週の勉強時間（カード）
          _whiteCard(
            title: "今週の勉強時間（分）",
            child: SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: [
                    for (int i = 0; i < weekly.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: weekly[i].toDouble(),
                            color: Colors.teal,
                            width: 18,
                            borderRadius: BorderRadius.circular(4),
                          )
                        ],
                      )
                  ],
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: false),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ④ 科目別累計勉強時間（カードの中で線区切り）
          _whiteCard(
            title: "科目別累計勉強時間",
            child: totalBySubject.isEmpty
                ? const Text(
                    "まだ勉強ログがありません",
                    style: TextStyle(color: Colors.grey),
                  )
                : Column(
                    children: _buildSeparatedList(totalBySubject),
                  ),
          ),

          const SizedBox(height: 20),

          // ⑤ 今月の日別勉強時間（カード）
          _whiteCard(
            title: "今月の日別勉強時間（分）",
            child: SizedBox(
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
          ),
        ],
      ),
    );
  }

  // 共通：白カードUI
  Widget _whiteCard({
    required String title,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(20),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
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

  // グレーの線で区切られた「科目名＋分数」のリスト
  List<Widget> _buildSeparatedList(Map<String, int> data) {
    final entries = data.entries.toList();
    return [
      for (int i = 0; i < entries.length; i++) ...[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
          // ★ 科目カラー丸アイコン
          CircleAvatar(
            radius: 6,
            backgroundColor: subjects
                .firstWhere((s) => s.name == entries[i].key)
                .colorObj,
          ),
          const SizedBox(width: 8),

          // ★ 科目名（左側に寄せる）
          Expanded(
            child: Text(
              entries[i].key,
              style: const TextStyle(fontSize: 16),
            ),
          ),            
            Text(
              "${entries[i].value} 分",
              style: const TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
              )
            ),
          ],
        ),
        if (i < entries.length - 1)
          const Divider(
            height: 16,
            thickness: 1,
            color: Colors.black12,
          ),
      ]
    ];
  }
}
