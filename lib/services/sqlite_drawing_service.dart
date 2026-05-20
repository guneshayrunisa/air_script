import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/saved_drawing.dart';

class SQLiteDrawingService {
  static final SQLiteDrawingService instance = SQLiteDrawingService._init();

  SQLiteDrawingService._init();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('airscript_drawings.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE drawings (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        pointsJson TEXT NOT NULL
      )
    ''');
  }

  Future<void> saveDrawing(SavedDrawing drawing) async {
    final db = await database;

    await db.insert(
      'drawings',
      {
        'id': drawing.id,
        'name': drawing.name,
        'createdAt': drawing.createdAt.toIso8601String(),
        'pointsJson': jsonEncode(drawing.toJson()['points']),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SavedDrawing>> getDrawings() async {
    final db = await database;

    final result = await db.query(
      'drawings',
      orderBy: 'createdAt DESC',
    );

    return result.map((row) {
      return SavedDrawing.fromJson({
        'id': row['id'],
        'name': row['name'],
        'createdAt': row['createdAt'],
        'points': jsonDecode(row['pointsJson'] as String),
      });
    }).toList();
  }

  Future<void> deleteDrawing(String id) async {
    final db = await database;

    await db.delete(
      'drawings',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}