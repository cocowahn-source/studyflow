import 'package:flutter/material.dart';
import 'package:study_flow/models/subject.dart';

class SubjectEditScreen extends StatefulWidget {
  const SubjectEditScreen({
    super.key,
    required this.subjects,
    required this.onAddSubject,
    required this.onRemoveSubject,
  });

  final List<Subject> subjects;

  final void Function(String name) onAddSubject;

  final void Function(String subjectId) onRemoveSubject;

  @override
  State<SubjectEditScreen> createState() => _SubjectEditScreenState();
}

class _SubjectEditScreenState extends State<SubjectEditScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleAdd() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    widget.onAddSubject(text);

    setState(() {});
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = widget.subjects;

    return Scaffold(
      appBar: AppBar(
        title: const Text('科目の編集'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: '科目名を追加',
                      hintText: '例：現代文、世界史、韓国語…',
                    ),
                    onSubmitted: (_) => _handleAdd(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _handleAdd,
                  child: const Text('追加'),
                ),
              ],
            ),
          ),
          const Divider(),

          // ----------------------------
          //  科目一覧（カラー編集付き）
          // ----------------------------
          Expanded(
            child: ListView.builder(
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: subject.colorObj,
                    radius: 12,
                  ),
                  title: Text(subject.name),

                  // ★ 色選択 UI
                  subtitle: Row(
                    children: Subject.presetColors.map((c) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            subject.color = c;
                          });
                        },
                        child: Container(
                          width: 22,
                          height: 22,
                          margin: const EdgeInsets.only(right: 6, top: 4),
                          decoration: BoxDecoration(
                            color: Color(c),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: subject.color == c
                                  ? Colors.black
                                  : Colors.grey.shade300,
                              width: subject.color == c ? 2 : 1,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      widget.onRemoveSubject(subject.id);
                      setState(() {});
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
