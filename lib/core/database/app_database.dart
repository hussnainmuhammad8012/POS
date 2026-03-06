import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Centralized SQLite database initialization and access.
///
/// Uses `sqflite_common_ffi` so it works on Windows/macOS/Linux without a
/// separate database server.
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'migrations/migration_v2.dart';
import 'migrations/migration_v3.dart';

/// Centralized SQLite database initialization and access.
class AppDatabase {
  static const String _databaseName = 'utility_store_pos.db';
  static const int _databaseVersion = 3; // Increment to 3 for UUID Transaction Types

  static final AppDatabase instance = AppDatabase._();

  AppDatabase._();

  late Database _db;
  bool _initialized = false;

  Database get db {
    if (!_initialized) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return _db;
  }

  // Alias for compatibility with roadmap code
  Database get database => db;

  Future<void> initialize() async {
    if (_initialized) return;

    sqfliteFfiInit();
    final databaseFactory = databaseFactoryFfi;

    final appDataDir = await _resolveAppDataDirectory();
    final dbPath = p.join(appDataDir.path, _databaseName);

    _db = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _databaseVersion,
        onCreate: (db, version) async {
          await migrateToV2(db);
          await migrateToV3(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await migrateToV2(db);
          }
          if (oldVersion < 3) {
            await migrateToV3(db);
          }
        },
      ),
    );

    _initialized = true;
  }

  Future<Directory> _resolveAppDataDirectory() async {
    final currentDir = Directory.current;
    final dataDir = Directory(p.join(currentDir.path, 'data'));
    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }
    return dataDir;
  }

  Future<void> close() async {
    if (_initialized) {
      await _db.close();
      _initialized = false;
    }
  }
}

