 
import 'package:flutter_media_metadata/flutter_media_metadata.dart';

class TrackModel {
  String? path;
  bool? isFavorite;

  Metadata? metadata;
  TrackModel({this.path, this.metadata, this.isFavorite = false});

  factory TrackModel.fromMap(Map<String, dynamic> map) {
    return TrackModel(path: map["path"], isFavorite: true);
  }
}
