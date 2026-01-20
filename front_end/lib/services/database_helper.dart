import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (kIsWeb) {
      throw Exception(
        "SQLite not supported on Web. Use SharedPreferences fallback.",
      );
    }
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'midwife_offline.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE pending_ops(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            method TEXT,
            endpoint TEXT,
            body TEXT,
            created_at INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE api_cache(
            endpoint TEXT PRIMARY KEY,
            response_body TEXT,
            timestamp INTEGER
          )
        ''');
      },
    );
  }

  // --- QUEUE OPERATIONS (Writes) ---

  Future<int> insertQueueItem(
    String method,
    String endpoint,
    dynamic body,
  ) async {
    final item = {
      'method': method,
      'endpoint': endpoint,
      'body': body != null ? jsonEncode(body) : null,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      List<String> queue = prefs.getStringList('pending_ops') ?? [];
      // Generate pseudo-ID
      item['id'] = DateTime.now().millisecondsSinceEpoch;
      queue.add(jsonEncode(item));
      await prefs.setStringList('pending_ops', queue);
      return item['id'] as int;
    }

    final db = await database;
    return await db.insert('pending_ops', item);
  }

  Future<List<Map<String, dynamic>>> getQueue() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      List<String> queue = prefs.getStringList('pending_ops') ?? [];
      return queue.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    }

    final db = await database;
    return await db.query('pending_ops', orderBy: 'created_at ASC');
  }

  Future<void> deleteQueueItem(int id) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      List<String> queue = prefs.getStringList('pending_ops') ?? [];
      queue.removeWhere((e) {
        final map = jsonDecode(e);
        return map['id'] == id;
      });
      await prefs.setStringList('pending_ops', queue);
      return;
    }

    final db = await database;
    await db.delete('pending_ops', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearQueue() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pending_ops');
      return;
    }
    final db = await database;
    await db.delete('pending_ops');
  }

  // --- CACHE OPERATIONS (Reads) ---

  Future<void> cacheResponse(String endpoint, String responseBody) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      // Using a prefix for cache keys to avoid collision
      await prefs.setString('cache_$endpoint', responseBody);
      return;
    }

    final db = await database;
    await db.insert('api_cache', {
      'endpoint': endpoint,
      'response_body': responseBody,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getCachedResponse(String endpoint) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('cache_$endpoint');
    }

    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'api_cache',
      where: 'endpoint = ?',
      whereArgs: [endpoint],
    );

    if (maps.isNotEmpty) {
      return maps.first['response_body'] as String;
    }
    return null;
  }
}
