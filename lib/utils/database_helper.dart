import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('journal.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      var factory = databaseFactoryFfiWeb;
      return await factory.openDatabase(filePath,
          options: OpenDatabaseOptions(
            version: 3,
            onCreate: _createDB,
            onUpgrade: _upgradeDB,
          ));
    } else {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);
      return await openDatabase(path, version: 3, onCreate: _createDB, onUpgrade: _upgradeDB);
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        body TEXT,
        date TEXT,
        photo_paths TEXT
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE entries ADD COLUMN photo_path TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE entries ADD COLUMN photo_paths TEXT');
      // Migrate existing photo_path to photo_paths
      var entries = await db.query('entries', columns: ['id', 'photo_path']);
      for (var entry in entries) {
        if (entry['photo_path'] != null) {
          await db.update('entries', 
            {'photo_paths': json.encode([entry['photo_path']])},
            where: 'id = ?',
            whereArgs: [entry['id']]);
        }
      }
    }
  }

  Future<int> createEntry(Map<String, dynamic> entry) async {
    final db = await instance.database;
    return await db.insert('entries', entry);
  }

  Future<List<Map<String, dynamic>>> getEntries() async {
    final db = await instance.database;
    return await db.query('entries', orderBy: 'date DESC');
  }

  Future<Map<String, dynamic>?> getEntry(int id) async {
    final db = await instance.database;
    final results = await db.query('entries', where: 'id = ?', whereArgs: [id], limit: 1);
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateEntry(int id, Map<String, dynamic> entry) async {
    final db = await instance.database;
    return await db.update('entries', entry, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteEntry(int id) async {
    final db = await instance.database;
    return await db.delete('entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getEntriesWithImagesForMonth(int year, int month) async {
    final db = await instance.database;
    final startDate = DateTime(year, month, 1).toIso8601String().split('T')[0];
    final endDate = DateTime(year, month + 1, 0).toIso8601String().split('T')[0];
    
    return await db.query(
      'entries',
      where: 'date BETWEEN ? AND ? AND photo_paths IS NOT NULL',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC'
    );
  }
}
