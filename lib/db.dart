// ignore_for_file: avoid_print

import 'package:music_player_native/track_model.dart';
import 'package:sqflite/sqflite.dart';

import 'db_helper.dart';

class Db {
  final tableName = "musicplayer";

  createTable(Database database) async {
    await database.execute("""CREATE TABLE IF NOT EXISTS $tableName (
         "path" TEXT NOT NULL,
         PRIMARY KEY ("path" ));""");
  }

  create({required TrackModel track}) async {
    final database = await DatabaseHelper().dataBase;
    return await database.rawInsert(
        '''INSERT INTO $tableName (path) VALUES (?)''', [track.path]);
  }

  delete({required TrackModel track}) async {
    final database = await DatabaseHelper().dataBase;
    return await database
        .delete(tableName, where: "path=?", whereArgs: [track.path]);
  }

  // update({required NoteModel ogNote, required NoteModel newNote}) async {
  //   final database = await DatabaseHelper().dataBase;

  //   return await database.update(tableName, ogNote.toMap(newNote),
  //       where: 'id=?', whereArgs: [ogNote.id]);
  // }

  clearFavorites() async {
    final database = await DatabaseHelper().dataBase;

    return await database.rawDelete("DELETE FROM $tableName");
  }

  Future<List<String>> getAllNotes() async {
    final database = await DatabaseHelper().dataBase;
    final tracks = await database.rawQuery('''SELECT * FROM $tableName ''');
    print("------{tracks}------");
    print(tracks);
    List<String> paths = tracks.map((e) => e["path"] as String).toList();
    for (var element in paths) {
      print(element);
    }
    print("-----------------");

    return paths;
  }
}
