// ignore_for_file: avoid_print

import 'package:audioplayers/audioplayers.dart';
import 'package:music_player_native/track_model.dart';

class MusicPlayer {
  static PlayerState isPlaying = PlayerState.playing;
  static bool isPlayingTrack = true;
  static final player = AudioPlayer();

  static playAudio(TrackModel audio) async {
    isPlayingTrack = true;

    await player.play(DeviceFileSource(audio.path!));
    player.setReleaseMode(ReleaseMode.loop);
  }

  static stopAudio() async {
    await player.stop();
  }

  static pauseAudio() async {
    isPlayingTrack = false;
    print(isPlayingTrack);

    await player.pause();
  }

  static Future<TrackModel> playNext(
      List<TrackModel> mp3FilesData, int index) async {
    index++;
    if (mp3FilesData.length == index) {
      index = 0;
    }

    await player.play(DeviceFileSource(mp3FilesData[index].path!));
    player.setReleaseMode(ReleaseMode.loop);
    isPlayingTrack = true;

    return Future.value(mp3FilesData[index]);
  }

  static Future<TrackModel> playPrevious(
      List<TrackModel> mp3FilesData, int index) async {
    index--;
    if (-1 == index) {
      index = mp3FilesData.length - 1;
    }

    await player.play(DeviceFileSource(mp3FilesData[index].path!));
    player.setReleaseMode(ReleaseMode.loop);
    isPlayingTrack = true;

    return Future.value(mp3FilesData[index]);
  }

  static resumeAudio() async {
    isPlayingTrack = true;

    await player.resume();
  }
}
