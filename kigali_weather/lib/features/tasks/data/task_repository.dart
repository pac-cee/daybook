import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../core/app_database.dart';
import '../domain/task.dart';

class TaskRepository {
  TaskRepository(this.database);
  final AppDatabase database;
  Future<List<Task>> load() async {
    final db = await database.connection;
    await db.transaction((txn) async {
      final seeded = await txn.query(
        'metadata',
        where: 'key = ?',
        whereArgs: ['tasks_seeded'],
      );
      if (seeded.isEmpty) {
        final now = DateTime.now();
        for (final task in [
          Task(
            id: 'sample-1',
            title: 'Make room for one good idea',
            notes: 'Use this notebook for the things that matter to you. Tap any task to edit its notes.',
            priority: 1,
            due: DateTime(now.year, now.month, now.day),
          ),
          Task(
            id: 'sample-2',
            title: 'Finish the Session 5 assignment',
            notes: 'Check the weather, try offline mode, and make three changes that survive a restart.',
            priority: 2,
          ),
          Task(
            id: 'sample-3',
            title: 'Take a walk after class',
            notes: 'Check the weather before heading out.',
          ),
        ]) {
          await txn.insert('tasks', task.toJson());
        }
        await txn.insert('metadata', {'key': 'tasks_seeded', 'value': '1'});
      }
    });
    final rows = await db.query(
      'tasks',
      orderBy: 'done ASC, priority DESC, created ASC',
    );
    return rows.map(Task.fromJson).toList();
  }

  Future<void> save(Task task) async {
    final db = await database.connection;
    await db.insert(
      'tasks',
      task.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(Task task) async {
    final db = await database.connection;
    await db.transaction((txn) async {
      await txn.insert('task_undo', {
        'id': 1,
        'payload': jsonEncode(task.toJson()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.delete('tasks', where: 'id = ?', whereArgs: [task.id]);
    });
  }

  Future<bool> get canUndo async =>
      (await (await database.connection).query('task_undo')).isNotEmpty;
  Future<void> undoDelete() async {
    final db = await database.connection;
    await db.transaction((txn) async {
      final rows = await txn.query('task_undo');
      if (rows.isEmpty) return;
      final task = Task.fromJson(
        jsonDecode(rows.first['payload'] as String) as Map<String, dynamic>,
      );
      await txn.insert(
        'tasks',
        task.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.delete('task_undo');
    });
  }
}
