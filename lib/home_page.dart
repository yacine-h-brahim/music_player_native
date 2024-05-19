import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:music_player_native/db.dart';
import 'package:music_player_native/music_player.dart';

import 'channel_with_kotlin.dart';
import 'track_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final Future<List<TrackModel>> mp3Files;
  List<String> mp3FavoritesDB = [];
  List<TrackModel> mp3FilesData1 = [];
  List<TrackModel> mp3FilesData2 = [];

  late StreamSubscription _notificationActionsSubscription;

  String? notificationActionPerformed;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    mp3Files = fetchMp3Files(); // Assign your Future to it.
    Db().getAllNotes().then((value) => mp3FavoritesDB = value);
    ChannelWithKotlin.channel.setMethodCallHandler((call) async {
      if (call.method == 'updateActionPerformed') {
        setState(() {
          var callAction = call.arguments['actionPerformed'];

          notificationActionPerformed = callAction;
          if (notificationActionPerformed == "action.PLAY_PAUSE") {
            MusicPlayer.isPlayingTrack
                ? MusicPlayer.pauseAudio()
                : MusicPlayer.resumeAudio();
          } else if (notificationActionPerformed == "action.PREVIOUS") {
            if (_tabController.index == 0) {
              int currentIndex = mp3FilesData1
                  .indexWhere((element) => element == currentTrack);

              MusicPlayer.playNext(mp3FilesData1, currentIndex)
                  .then((track) => setState(() {
                        currentTrack = track;
                        ChannelWithKotlin.channel.invokeMethod(
                            'passTrackNameToKotlin',
                            {'trackName': currentTrack!.metadata!.trackName});
                      }));
            } else {
              int currentIndex = mp3FilesData2
                  .indexWhere((element) => element == currentTrack);
              if (currentIndex == -1) {
                currentIndex = 0;
              }

              MusicPlayer.playPrevious(mp3FilesData2, currentIndex)
                  .then((track) => setState(() {
                        currentTrack = track;
                        ChannelWithKotlin.channel.invokeMethod(
                            'passTrackNameToKotlin',
                            {'trackName': currentTrack!.metadata!.trackName});
                      }));
            }
          } else if (notificationActionPerformed == "action.NEXT") {
            if (_tabController.index == 0) {
              int currentIndex = mp3FilesData1
                  .indexWhere((element) => element == currentTrack);

              MusicPlayer.playNext(mp3FilesData1, currentIndex)
                  .then((track) => setState(() {
                        currentTrack = track;
                        ChannelWithKotlin.channel.invokeMethod(
                            'passTrackNameToKotlin',
                            {'trackName': currentTrack!.metadata!.trackName});
                      }));
            } else {
              int currentIndex = mp3FilesData2
                  .indexWhere((element) => element == currentTrack);
              if (currentIndex == -1) {
                currentIndex = 0;
              }

              MusicPlayer.playNext(mp3FilesData2, currentIndex)
                  .then((track) => setState(() {
                        currentTrack = track;
                        ChannelWithKotlin.channel.invokeMethod(
                            'passTrackNameToKotlin',
                            {'trackName': currentTrack!.metadata!.trackName});
                      }));
            }
          } else if (notificationActionPerformed == "action.SHAKE") {
            MusicPlayer.isPlayingTrack
                ? MusicPlayer.pauseAudio()
                : MusicPlayer.resumeAudio();
          }
        });
      }
    });

    _notificationActionsSubscription =
        ChannelWithKotlin.notificationActionStream.listen((value) {
      setState(() {
        // print(value);
        // Update the state based on the received data
      });
    });
  }

  @override
  void dispose() {
    _notificationActionsSubscription.cancel(); // Cancel the stream subscription
    MusicPlayer.player.dispose();

    super.dispose();
  }

  sortingFavorites(List<TrackModel> list1, List<String> list2temp) {
    List<String> list2 = list2temp;
    for (var track in list1) {
      if (list2.contains(track.path)) {
        track.isFavorite = true;
      }
    }
  }

  List<TrackModel> keepingFavoritesOnly(List<TrackModel> list1) {
    return list1.where((track) => track.isFavorite == true).toList();
  }

  Uint8List? albumArt;
  TrackModel? currentTrack;

  Future<List<TrackModel>> fetchMp3Files() async {
    List<String> files = await ChannelWithKotlin.getMp3FilesPaths();
    List<TrackModel> mp3Files = [];

    // ignore: avoid_function_literals_in_foreach_calls
    files.forEach((file) async {
      final metadata = await MetadataRetriever.fromFile(File(file));

      debugPrint(file);
      if (metadata.trackName != null && metadata.albumArt != null) {
        mp3Files.add(TrackModel(metadata: metadata, path: file));
      }
    });

    return mp3Files;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(DateTime.now().hour < 12 ? 'Good Morning' : 'Good Evening',
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              text: 'Play List',
              icon: Icon(Icons.audiotrack_rounded),
            ),
            Tab(
              text: 'Favorites',
              icon: Icon(
                Icons.favorite,
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FutureBuilder(
                future: mp3Files,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (snapshot.data == null) {
                    return const Center(
                      child: Text('no track was found on your phone.'),
                    );
                  } else {
                    mp3FilesData1 = snapshot.data!;
                    var mp3FilesData = snapshot.data!;
                    sortingFavorites(mp3FilesData, mp3FavoritesDB);
                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 60),
                      itemCount: mp3FilesData.length,
                      separatorBuilder: (context, index) =>
                          Container(color: Colors.white, height: .2),
                      itemBuilder: (context, index) {
                        return InkWell(
                          onTap: () {
                            setState(() {
                              currentTrack = mp3FilesData[index];
                              ChannelWithKotlin.channel.invokeMethod(
                                  'passTrackNameToKotlin', {
                                'trackName': currentTrack!.metadata!.trackName
                              });

                              MusicPlayer.playAudio(currentTrack!);
                            });

                            setState(() {});
                          },
                          child: Container(
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: currentTrack == mp3FilesData[index]
                                  ? Colors.green[600]
                                  : Colors.transparent,
                            ),
                            height: 60,
                            child: Row(
                              children: [
                                Image.memory(
                                  mp3FilesData[index].metadata!.albumArt!,
                                  fit: BoxFit.cover,
                                  width: 50,
                                  height: 50,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Text(
                                  mp3FilesData[index].metadata?.trackName ??
                                      'Unknown',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                )),
                                IconButton(
                                    onPressed: () {
                                      TrackModel track = mp3FilesData[index];
                                      if (track.isFavorite!) {
                                        Db().delete(track: track);
                                        track.isFavorite = false;
                                      } else {
                                        Db().create(track: track);
                                        track.isFavorite = true;
                                      }
                                      Db().getAllNotes().then(
                                          (value) => mp3FavoritesDB = value);

                                      setState(() {});
                                    },
                                    icon: mp3FilesData[index].isFavorite!
                                        ? Icon(
                                            Icons.favorite_rounded,
                                            color: Colors.green[800],
                                          )
                                        : const Icon(
                                            Icons.favorite_outline_rounded,
                                            color: Colors.white,
                                          ))
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                }),
          ),

          /////////////// favorites
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: FutureBuilder(
                future: mp3Files,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else {
                    var mp3FilesData = snapshot.data!;

                    sortingFavorites(mp3FilesData, mp3FavoritesDB);
                    mp3FilesData = keepingFavoritesOnly(snapshot.data!);
                    mp3FilesData2 = mp3FilesData;

                    return ListView.separated(
                      itemCount: mp3FilesData.length,
                      separatorBuilder: (context, index) =>
                          Container(color: Colors.white, height: .2),
                      itemBuilder: (context, index) {
                        return InkWell(
                          onTap: () {
                            //   ChannelWithKotlin.startService();

                            setState(() {
                              currentTrack = mp3FilesData[index];

                              MusicPlayer.playAudio(mp3FilesData[index]);
                              ChannelWithKotlin.channel.invokeMethod(
                                  'passTrackNameToKotlin', {
                                'trackName': currentTrack!.metadata!.trackName
                              });
                            });
                          },
                          child: Container(
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: currentTrack == mp3FilesData[index]
                                    ? Colors.green[600]
                                    : Colors.transparent),
                            height: 60,
                            child: Row(
                              children: [
                                Image.memory(
                                  mp3FilesData[index].metadata!.albumArt!,
                                  fit: BoxFit.cover,
                                  width: 50,
                                  height: 50,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    mp3FilesData[index].metadata!.trackName!,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ),
                                IconButton(
                                    onPressed: () {
                                      TrackModel track = mp3FilesData[index];
                                      if (track.isFavorite!) {
                                        Db().delete(track: track);
                                        track.isFavorite = false;
                                      } else {
                                        Db().create(track: track);
                                        track.isFavorite = true;
                                      }
                                      Db().getAllNotes().then(
                                          (value) => mp3FavoritesDB = value);
                                      setState(() {});
                                    },
                                    icon: mp3FilesData[index].isFavorite!
                                        ? Icon(
                                            Icons.favorite_rounded,
                                            color: Colors.green[800],
                                          )
                                        : const Icon(
                                            Icons.favorite_outline_rounded,
                                            color: Colors.white,
                                          ))
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                }),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: currentTrack != null
          ? Container(
              height: 70,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10).copyWith(left: 15),
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10), color: Colors.black),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.memory(
                    currentTrack!.metadata!.albumArt!,
                    fit: BoxFit.cover,
                    width: 40,
                    height: 40,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 110,
                        child: Text(
                          currentTrack!.metadata!.trackName!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      if (currentTrack!.isFavorite!)
                        Icon(
                          Icons.favorite_rounded,
                          color: Colors.green[800],
                          size: 10,
                        ),
                    ],
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                            onPressed: () {
                              if (_tabController.index == 0) {
                                int currentIndex = mp3FilesData1.indexWhere(
                                    (element) => element == currentTrack);

                                MusicPlayer.playPrevious(
                                        mp3FilesData1, currentIndex)
                                    .then((track) => setState(() {
                                          currentTrack = track;
                                          ChannelWithKotlin.channel
                                              .invokeMethod(
                                                  'passTrackNameToKotlin', {
                                            'trackName': currentTrack!
                                                .metadata!.trackName
                                          });
                                        }));
                              } else {
                                int currentIndex = mp3FilesData2.indexWhere(
                                    (element) => element == currentTrack);
                                if (currentIndex == -1) {
                                  currentIndex = 0;
                                }

                                MusicPlayer.playPrevious(
                                        mp3FilesData2, currentIndex)
                                    .then((track) => setState(() {
                                          currentTrack = track;
                                          ChannelWithKotlin.channel
                                              .invokeMethod(
                                                  'passTrackNameToKotlin', {
                                            'trackName': currentTrack!
                                                .metadata!.trackName
                                          });
                                        }));
                              }
                              setState(() {});
                            },
                            icon: const Icon(
                              Icons.skip_previous_rounded,
                              size: 35,
                            )),
                        IconButton(
                            onPressed: () {
                              MusicPlayer.isPlayingTrack
                                  ? MusicPlayer.pauseAudio()
                                  : MusicPlayer.resumeAudio();

                              setState(() {});
                            },
                            icon: Icon(
                              MusicPlayer.isPlayingTrack
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 50,
                            )),
                        IconButton(
                            onPressed: () {
                              if (_tabController.index == 0) {
                                int currentIndex = mp3FilesData1.indexWhere(
                                    (element) => element == currentTrack);

                                MusicPlayer.playNext(
                                        mp3FilesData1, currentIndex)
                                    .then((track) => setState(() {
                                          currentTrack = track;
                                          ChannelWithKotlin.channel
                                              .invokeMethod(
                                                  'passTrackNameToKotlin', {
                                            'trackName': currentTrack!
                                                .metadata!.trackName
                                          });
                                        }));
                              } else {
                                int currentIndex = mp3FilesData2.indexWhere(
                                    (element) => element == currentTrack);
                                if (currentIndex == -1) {
                                  currentIndex = 0;
                                }

                                MusicPlayer.playNext(
                                        mp3FilesData2, currentIndex)
                                    .then((track) => setState(() {
                                          currentTrack = track;
                                          ChannelWithKotlin.channel
                                              .invokeMethod(
                                                  'passTrackNameToKotlin', {
                                            'trackName': currentTrack!
                                                .metadata!.trackName
                                          });
                                        }));
                              }
                            },
                            icon: const Icon(
                              Icons.skip_next_rounded,
                              size: 35,
                            ))
                      ],
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
