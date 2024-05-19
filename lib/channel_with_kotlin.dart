// ignore_for_file: avoid_print

import 'package:flutter/services.dart';

class ChannelWithKotlin {
  static const MethodChannel channel = MethodChannel('music_player');

  static Future<List<String>> getMp3FilesPaths() async {
    try {
      final List<String>? mp3FilesPaths =
          await channel.invokeListMethod('getMp3Files');
      return mp3FilesPaths!;
    } on PlatformException catch (e) {
      // show error using a snackbar
      print("Failed to get MP3 files: '${e.message}'.");
      return <String>[];
    }
  }

  static Future<void> startService() async {
    try {
      // ignore: unused_local_variable
      final result = await channel.invokeMethod('StartService');
    } on PlatformException catch (e) {
      print("Failed to invoke method: '${e.message}'.");
    }
  }

  static Stream get notificationActionStream async* {
    try {
      while (true) {
        var result = await channel.invokeMethod(
          'getNotificationActionStream',
        );
        yield result; // Yield the received proximity data
      }
    } on PlatformException catch (e) {
      print("Failed to get proximity data: '${e.message}'.");
      // Handle error
    }
  }
}
