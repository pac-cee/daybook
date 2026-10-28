import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../domain/task.dart';
import 'task_controller.dart';

class TaskEditor extends StatefulWidget {
  const TaskEditor({super.key, required this.controller, this.task});
  final TaskController controller;
  final Task? task;
  @override
  State<TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<TaskEditor> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.task?.title);
  late final _notes = TextEditingController(text: widget.task?.notes);
  late int _priority = widget.task?.priority ?? 0;
  late DateTime? _due = widget.task?.due;
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final task = Task(
      id: widget.task?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: _title.text,
      notes: _notes.text.trim(),
      priority: _priority,
      done: widget.task?.done ?? false,
      due: _due,
      created: widget.task?.created,
    );
    final saved = await widget.controller.save(task);
    if (!mounted) return;
    if (saved) {
      Navigator.pop(context);
    } else {
      setState(() {
        _saving = false;
        _error = widget.controller.error ?? 'Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.task == null
                            ? 'A little intention.'
                            : 'Your task',
                        style: const TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -.8,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close editor',
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      icon: const Icon(CupertinoIcons.xmark, size: 19),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  key: const Key('task-title'),
                  controller: _title,
                  autofocus: widget.task == null,
                  maxLength: 160,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Task',
                    hintText: 'What would you like to do?',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Give your task a name.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('task-notes'),
                  controller: _notes,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 5000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'An idea, a detail, a next step…',
                  ),
                ),
                const SizedBox(height: 16),
                const SectionLabel('Priority', CupertinoIcons.flag),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (var i = 0; i < 3; i++)
                      ChoiceChip(
                        label: Text(const ['Normal', 'Important', 'High'][i]),
                        selected: _priority == i,
                        selectedColor: blueWash,
                        onSelected: _saving
                            ? null
                            : (_) => setState(() => _priority = i),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(CupertinoIcons.calendar, size: 19),
                        label: Text(
                          _due == null
                              ? 'Add a due date'
                              : '${shortDate(_due!)} ${_due!.year}',
                        ),
                        onPressed: _saving
                            ? null
                            : () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _due ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (date != null && mounted) {
                                  setState(() => _due = date);
                                }
                              },
                      ),
                    ),
                    if (_due != null)
                      IconButton(
                        tooltip: 'Remove due date',
                        onPressed: _saving
                            ? null
                            : () => setState(() => _due = null),
                        icon: const Icon(CupertinoIcons.xmark_circle),
                      ),
                  ],
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_error!),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const CupertinoActivityIndicator()
                        : Text(
                            widget.task == null ? 'Add task' : 'Save changes',
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Saved on this device',
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
