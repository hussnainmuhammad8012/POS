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
import 'migrations/migration_v4.dart';
import 'migrations/migration_v5.dart';
import 'migrations/migration_v6.dart';
import 'migrations/migration_v7.dart';
import 'migrations/migration_v8.dart';
import 'migrations/migration_v9.dart';
import 'migrations/migration_v10.dart';
import 'migrations/migration_v11.dart';
import 'migrations/migration_v12.dart';
import 'migrations/migration_v13.dart';
import 'migrations/migration_v14.dart';
import 'migrations/migration_v15.dart';
import 'migrations/migration_v16.dart';
import 'migrations/migration_v17.dart';
import 'migrations/migration_v18.dart';

/// Centralized SQLite database initialization and access.
class AppDatabase {
  static const String _databaseName = 'utility_store_pos.db';
  static const int _databaseVersion = 18; 

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
          await migrateToV4(db);
          await migrateToV5(db);
          await migrateToV6(db);
          await migrateToV7(db);
          await migrateToV8(db);
          await migrateToV9(db);
          await migrateToV10(db);
          await migrateToV11(db);
          await migrateToV12(db);
          await migrateToV13(db);
          await migrateToV14(db);
          await migrateToV15(db);
          await migrateToV16(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await migrateToV2(db);
          }
          if (oldVersion < 3) {
            await migrateToV3(db);
          }
          if (oldVersion < 4) {
            await migrateToV4(db);
          }
          if (oldVersion < 5) {
            await migrateToV5(db);
          }
          if (oldVersion < 6) {
            await migrateToV6(db);
          }
          if (oldVersion < 7) {
            await migrateToV7(db);
          }
          if (oldVersion < 8) {
            await migrateToV8(db);
          }
          if (oldVersion < 9) {
            await migrateToV9(db);
          }
          if (oldVersion < 10) {
            await migrateToV10(db);
          }
          if (oldVersion < 11) {
            await migrateToV11(db);
          }
          if (oldVersion < 12) {
            await migrateToV12(db);
          }
          if (oldVersion < 13) {
            await migrateToV13(db);
          }
          if (oldVersion < 14) {
            await migrateToV14(db);
          }
          if (oldVersion < 15) {
            await migrateToV15(db);
          }
          if (oldVersion < 17) {
            await migrateToV17(db);
          }
          if (oldVersion < 18) {
            await migrateToV18(db);
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

