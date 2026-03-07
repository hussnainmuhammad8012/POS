import 'dart:io';
import 'package:path/path.dart' as p;
import '../database/app_database.dart';

class DatabaseBackupService {
  static const String _databaseName = 'utility_store_pos.db';

  Future<String> getDatabasePath() async {
    final currentDir = Directory.current;
    return p.join(currentDir.path, 'data', _databaseName);
  }

  Future<void> exportDatabase(String targetPath) async {
    final dbPath = await getDatabasePath();
    final dbFile = File(dbPath);

    if (await dbFile.exists()) {
      // Ensure target directory exists
      final targetFile = File(targetPath);
      final targetDir = targetFile.parent;
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      
      await dbFile.copy(targetPath);
    } else {
      throw Exception('Database file not found at $dbPath');
    }
  }

  Future<void> restoreDatabase(String sourcePath) async {
    final dbPath = await getDatabasePath();
    final sourceFile = File(sourcePath);

    if (!await sourceFile.exists()) {
      throw Exception('Backup file not found at $sourcePath');
    }

    // 1. Close current database connection
    await AppDatabase.instance.close();

    // 2. Replace the current database with the backup
    final dbFile = File(dbPath);
    if (await dbFile.exists()) {
      await dbFile.delete();
    }
    await sourceFile.copy(dbPath);

    // 3. Re-initialize the database
    await AppDatabase.instance.initialize();
  }

  Future<void> clearDatabase() async {
    final dbPath = await getDatabasePath();
    
    // 1. Close current database connection
    await AppDatabase.instance.close();

    // 2. Delete the database file
    final dbFile = File(dbPath);
    if (await dbFile.exists()) {
      await dbFile.delete();
    }

    // 3. Re-initialize (this will trigger onCreate/migrations)
    await AppDatabase.instance.initialize();
  }

  Future<int> getDatabaseSize() async {
    final dbPath = await getDatabasePath();
    final dbFile = File(dbPath);
    if (await dbFile.exists()) {
      return await dbFile.length();
    }
    return 0;
  }
}
