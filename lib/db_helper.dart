import 'dart:async';

import 'package:sqflite/sqflite.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart';

import 'db.dart';

class DatabaseHelper {
  Database? _database;

  Future<Database> get dataBase async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initialize();
    return _database!;
  }

  fullPath() async {
    const name = "musicplayer";
    final path = await getDatabasesPath();
    return join(path, name);
  }

  _initialize() async {
    final path = await fullPath();
    var database =
        openDatabase(path, version: 1, onCreate: create, singleInstance: true);

    return database;
  }

  FutureOr<void> create(Database db, int version) async =>
      await Db().createTable(db);
}
