import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDB('notes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await databaseFactory.getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(
    Database db,
    int version,
  ) async {
    await db.execute('''
      CREATE TABLE notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertNote(
    Map<String, dynamic> row,
  ) async {
    final db = await instance.database;

    return await db.insert(
      'notes',
      row,
    );
  }

  Future<List<Map<String, dynamic>>> getNotes() async {
    final db = await instance.database;

    return await db.query(
      'notes',
      orderBy: 'id DESC',
    );
  }

  Future<int> updateNote(
    Map<String, dynamic> row,
  ) async {
    final db = await instance.database;

    return await db.update(
      'notes',
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }

  Future<int> deleteNote(
    int id,
  ) async {
    final db = await instance.database;

    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
