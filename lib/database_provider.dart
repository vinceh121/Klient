/*
 * This file is part of the Klient (https://github.com/lolocomotive/klient)
 *
 * Copyright (C) 2022 lolocomotive
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:klient/config_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    hide getDatabasesPath, openDatabase, deleteDatabase;
import 'package:sqflite_sqlcipher/sqflite.dart';

class DatabaseProvider {
  static Database? _database;
  static bool lock = false;
  static Future<Database> getDB() async {
    // Keeps database from being created twice at the same time
    while (lock) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (_database != null) return _database!;
    lock = true;
    await initDB();
    lock = false;
    return _database!;
  }

  static initDB() async {
    final String dbDir;
    if (Platform.isWindows || Platform.isLinux) {
      // Initialize FFI
      sqfliteFfiInit();
      // Change the default factory
      dbDir = '${(await getApplicationDocumentsDirectory()).path}/klient';
    } else {
      dbDir = await getDatabasesPath();
    }

    final dbPath = '$dbDir/klient.db';

    ConfigProvider.dbPassword = ConfigProvider.dbPassword ??
        base64Url.encode(List<int>.generate(32, (i) => Random.secure().nextInt(256)));
    try {
      _database = await openDB(dbPath, ConfigProvider.dbPassword!);
    } on DatabaseException catch (e, st) {
      // Delete database if password is wrong
      debugPrint(e.toString());
      debugPrintStack(stackTrace: st);
      print('Deleting database');
      await deleteDb(dbPath);
      _database = await openDB(dbPath, ConfigProvider.dbPassword!);
    }
  }

  static deleteDb(dbPath) {
    if (Platform.isWindows || Platform.isLinux) {
      return databaseFactoryFfi.deleteDatabase(dbPath);
    } else {
      return deleteDatabase(dbPath);
    }
  }

  static Future<void> createTables(Database db) async {
    await db.rawQuery('''
      CREATE TABLE IF NOT EXISTS Cache (
        Id INTEGER PRIMARY KEY AUTOINCREMENT,
        Uri TEXT NOT NULL UNIQUE,
        Data TEXT NOT NULL,
        DateTime TEXT NOT NULL
      );
    ''');
  }

  static Future<Database> openDB(String dbPath, String password) async {
    if (Platform.isLinux || Platform.isWindows) {
      final db = await databaseFactoryFfi.openDatabase(dbPath);
      print('Opening databse with FFI');
      await createTables(db);
      return db;
    }
    return openDatabase(
      dbPath,
      password: password,
      version: 1,
      onCreate: (db, version) async {
        await createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {},
    );
  }
}
