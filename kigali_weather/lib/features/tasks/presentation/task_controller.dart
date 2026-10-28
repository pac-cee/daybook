import 'package:flutter/foundation.dart';

import '../data/task_repository.dart';
import '../domain/task.dart';

enum TaskFilter { all, today, upcoming, completed }

class TaskController extends ChangeNotifier {
  TaskController(this.repository);
  final TaskRepository repository;
  List<Task> tasks = [];
  bool loading = true, busy = false, canUndo = false;
  String? error;
  String query = '';
  TaskFilter filter = TaskFilter.all;
  bool _disposed = false;
  List<Task> get visible {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return tasks.where((t) {
      if (!'${t.title} ${t.notes}'.toLowerCase().contains(
        query.toLowerCase(),
      )) {
        return false;
      }
      return switch (filter) {
        TaskFilter.all => !t.done,
        TaskFilter.today => !t.done && t.due != null && !t.due!.isAfter(today),
        TaskFilter.upcoming =>
          !t.done && t.due != null && t.due!.isAfter(today),
        TaskFilter.completed => t.done,
      };
    }).toList();
  }

  void search(String value) {
    query = value;
    _emit();
  }

  void setFilter(TaskFilter value) {
    filter = value;
    _emit();
  }

  Future<void> load() async {
    loading = true;
    error = null;
    _emit();
    try {
      tasks = await repository.load();
      canUndo = await repository.canUndo;
    } catch (_) {
      error = 'Your tasks could not be opened. Please try again.';
    }
    loading = false;
    _emit();
  }

  Future<bool> save(Task task) => _change(() => repository.save(task));
  Future<bool> delete(Task task) => _change(() => repository.delete(task));
  Future<bool> undo() => _change(repository.undoDelete);
  Future<bool> _change(Future<void> Function() write) async {
    if (busy) return false;
    busy = true;
    error = null;
    _emit();
    try {
      await write();
      tasks = await repository.load();
      canUndo = await repository.canUndo;
      return true;
    } catch (_) {
      error = 'That change could not be saved. Please try again.';
      return false;
    } finally {
      busy = false;
      _emit();
    }
  }

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
