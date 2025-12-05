import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';

class AddTaskScreen extends StatefulWidget {
  final Task? existingTask; // ★ ここが null なら新規、非nullなら編集

  const AddTaskScreen({super.key, this.existingTask});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _totalController = TextEditingController();
  final _intervalController = TextEditingController();

  bool isPlanned = false;
  String? selectedUnit;
  DateTime? _selectedDate;

  // 実行パターン（1=毎日, 2=〇日おき, 3=曜日指定）
  int selectedPattern = 1;
  List<bool> weekdayChecks = List.filled(7, false);

  @override
  void initState() {
    super.initState();

    final existing = widget.existingTask;
    if (existing != null) {
      // ★ 既存タスクの値をフォームに反映
      _titleController.text = existing.title;
      isPlanned = existing.isPlanned;
      if (existing.totalAmount != null) {
        _totalController.text = existing.totalAmount.toString();
      }
      selectedUnit = existing.unit;
      _selectedDate = existing.dueDate;

      if (existing.weekdays.isNotEmpty) {
        selectedPattern = 3;
        for (final w in existing.weekdays) {
          if (w >= 0 && w < 7) {
            weekdayChecks[w] = true;
          }
        }
      } else if (existing.intervalDays > 0) {
        selectedPattern = 2;
        _intervalController.text = existing.intervalDays.toString();
      } else {
        selectedPattern = 1;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _totalController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  List<int> _getSelectedWeekdays() {
    List<int> result = [];
    for (int i = 0; i < 7; i++) {
      if (weekdayChecks[i]) result.add(i);
    }
    return result;
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final existing = widget.existingTask;

      final task = Task(
        id: existing?.id ?? const Uuid().v4(),
        title: _titleController.text,
        dueDate: _selectedDate,
        isPlanned: isPlanned,
        totalAmount:
            isPlanned ? int.tryParse(_totalController.text) ?? 0 : null,
        unit: isPlanned ? selectedUnit : null,
        intervalDays: isPlanned && selectedPattern == 2
            ? int.tryParse(_intervalController.text) ?? 0
            : 0,
        weekdays: isPlanned && selectedPattern == 3
            ? _getSelectedWeekdays()
            : [],
        // 既存タスクなら完了状態と進捗を引き継ぐ
        isCompleted: existing?.isCompleted ?? false,
        progressAmount: existing?.progressAmount ?? 0,
      );

      Navigator.pop(context, task);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingTask != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "タスクを編集" : "タスクを追加"),
        backgroundColor: const Color(0xFFB2DFDB),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // タスク名
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "タスク名"),
                validator: (v) =>
                    v == null || v.isEmpty ? "入力してください" : null,
              ),
              const SizedBox(height: 16),

              // 計画タスクチェック
              Row(
                children: [
                  Checkbox(
                    value: isPlanned,
                    onChanged: (v) => setState(() {
                      isPlanned = v ?? false;
                    }),
                  ),
                  const Text("計画タスクとして設定する"),
                ],
              ),
              const SizedBox(height: 8),

              // 🔥 計画タスクのUI（チェックしたときだけ表示）
              if (isPlanned) ...[
                TextFormField(
                  controller: _totalController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "合計量（例：100）"),
                  validator: (v) {
                    if (!isPlanned) return null;
                    if (v == null || v.isEmpty) return "入力してください";
                    if (int.tryParse(v) == null) return "数値で入力してください";
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: selectedUnit,
                  items: const [
                    DropdownMenuItem(
                        value: "ページ", child: Text("ページ")),
                    DropdownMenuItem(value: "回", child: Text("回")),
                  ],
                  decoration: const InputDecoration(labelText: "単位"),
                  onChanged: (v) => setState(() => selectedUnit = v),
                  validator: (v) {
                    if (!isPlanned) return null;
                    if (v == null) return "選択してください";
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 実行パターン
                const Text("実行パターン",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Column(
                  children: [
                    // 毎日
                    RadioListTile(
                      value: 1,
                      groupValue: selectedPattern,
                      onChanged: (v) =>
                          setState(() => selectedPattern = v as int),
                      title: const Text("毎日"),
                    ),
                    // ◯日おき
                    RadioListTile(
                      value: 2,
                      groupValue: selectedPattern,
                      onChanged: (v) =>
                          setState(() => selectedPattern = v as int),
                      title: Row(
                        children: [
                          const Text("◯日おき："),
                          SizedBox(
                            width: 60,
                            child: TextField(
                              controller: _intervalController,
                              enabled: selectedPattern == 2,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: "2",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 曜日指定
                    RadioListTile(
                      value: 3,
                      groupValue: selectedPattern,
                      onChanged: (v) =>
                          setState(() => selectedPattern = v as int),
                      title: const Text("曜日指定"),
                    ),
                    if (selectedPattern == 3)
                      Wrap(
                        spacing: 8,
                        children: List.generate(7, (i) {
                          const labels = ["月", "火", "水", "木", "金", "土", "日"];
                          return FilterChip(
                            label: Text(labels[i]),
                            selected: weekdayChecks[i],
                            onSelected: (v) =>
                                setState(() => weekdayChecks[i] = v),
                          );
                        }),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ],

              // 期限
              Row(
                children: [
                  Expanded(
                    child: Text(_selectedDate == null
                        ? "期限が未設定"
                        : "期限: ${_selectedDate!.toLocal().toString().split(' ')[0]}"),
                  ),
                  TextButton(
                      onPressed: _pickDate, child: const Text("日付を選択")),
                ],
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _saveTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFCCBC),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Text(isEditing ? "更新する" : "保存"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
