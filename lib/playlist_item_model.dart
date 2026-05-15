// SPDX-License-Identifier: GPL-3.0-only
import 'package:path/path.dart' as path;

import 'dart:convert';

/// An item in a playlist.
class PlaylistItemModel {
  PlaylistItemModel({
    required this.filepath,
    this.isMissing = false,
    this.isUnplayable = false,
  });

  final String filepath;
  bool isMissing;
  bool isUnplayable;

  String toPrefString() {
    return jsonEncode(this);
  }

  static PlaylistItemModel fromPrefString(String json) {
    return fromJson(jsonDecode(json));
  }

  static PlaylistItemModel fromJson(Map<String, dynamic> json) {
    return PlaylistItemModel(
      filepath: json['path'] as String,
      isMissing: json['missing'] == null ? false : json['missing'] as bool,
      isUnplayable: json['unplayable'] == null
          ? false
          : json['unplayable'] as bool,
    );
  }

  /// Use shorted versions of variable names in JSON to keep file size smaller
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {'path': filepath};
    if (isMissing) {
      json['missing'] = true;
    }
    if (isUnplayable) {
      json['unplayable'] = true;
    }

    //debugPrint(jsonEncode(json));
    return json;
  }

  String get title => path.withoutExtension(path.basename(filepath));
}
