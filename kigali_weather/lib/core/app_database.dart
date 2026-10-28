import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase({DatabaseFactory? factory, this.path})
    : factory = factory ?? databaseFactory;
  final DatabaseFactory factory;
  final String? path;
  Future<Database>? _opening;
  Future<Database> get connection => _opening ??= _open();
  Future<Database> _open() async {
    try {
      final file =
          path ?? p.join(await factory.getDatabasesPath(), 'session5.db');
      return await factory.openDatabase(
        file,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute(
              'CREATE TABLE weather_cache (city TEXT PRIMARY KEY, payload TEXT NOT NULL)',
            );
            await db.execute(
              'CREATE TABLE tasks (id TEXT PRIMARY KEY, title TEXT NOT NULL, notes TEXT NOT NULL, priority INTEGER NOT NULL CHECK(priority BETWEEN 0 AND 2), done INTEGER NOT NULL CHECK(done IN (0,1)), due TEXT, created TEXT NOT NULL)',
            );
            await db.execute(
              'CREATE TABLE metadata (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
            );
            await db.execute(
              'CREATE TABLE task_undo (id INTEGER PRIMARY KEY CHECK(id = 1), payload TEXT NOT NULL)',
            );
          },
        ),
      );
    } catch (_) {
      _opening = null;
      rethrow;
    }
  }

  Future<void> close() async {
    final pending = _opening;
    _opening = null;
    if (pending != null) await (await pending).close();
  }
}
