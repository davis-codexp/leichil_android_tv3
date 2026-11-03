import 'package:flutter/foundation.dart';

class VideoModel {
  final String id;
  final String title;
  final String description;

  final String year;
  final String duration;
  final String category;
  final String language;

  final double rating;

  final String thumbnail;
  final String tvThumbnail;
  final String banner;
  final String titleImage;

  final List<String> genres;
  final List<String> cast;
  final List<String> directors;

  final bool featured;
  final bool trending;
  final bool continueWatching;

  final double progress;

  final bool isSeries;
  final List<Season> seasons;

  const VideoModel({
    this.id = "",
    required this.title,
    this.description = "",
    required this.year,
    this.duration = "",
    required this.category,
    this.language = "English",
    this.rating = 0,
    required this.thumbnail,
    String? tvThumbnail,
    String? banner,
    String? titleImage,
    this.genres = const [],
    this.cast = const [],
    this.directors = const [],
    this.featured = false,
    this.trending = false,
    this.continueWatching = false,
    this.progress = 0,
    this.isSeries = false,
    this.seasons = const [],
  })  : tvThumbnail = tvThumbnail ?? "",
        banner = banner ?? thumbnail,
        titleImage = titleImage ?? "";

  VideoModel copyWith({
    String? id,
    String? title,
    String? description,
    String? year,
    String? duration,
    String? category,
    String? language,
    double? rating,
    String? thumbnail,
    String? tvThumbnail,
    String? banner,
    String? titleImage,
    List<String>? genres,
    List<String>? cast,
    List<String>? directors,
    bool? featured,
    bool? trending,
    bool? continueWatching,
    double? progress,
    bool? isSeries,
    List<Season>? seasons,
  }) {
    return VideoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      year: year ?? this.year,
      duration: duration ?? this.duration,
      category: category ?? this.category,
      language: language ?? this.language,
      rating: rating ?? this.rating,
      thumbnail: thumbnail ?? this.thumbnail,
      tvThumbnail: tvThumbnail ?? this.tvThumbnail,
      banner: banner ?? this.banner,
      titleImage: titleImage ?? this.titleImage,
      genres: genres ?? this.genres,
      cast: cast ?? this.cast,
      directors: directors ?? this.directors,
      featured: featured ?? this.featured,
      trending: trending ?? this.trending,
      continueWatching: continueWatching ?? this.continueWatching,
      progress: progress ?? this.progress,
      isSeries: isSeries ?? this.isSeries,
      seasons: seasons ?? this.seasons,
    );
  }

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    debugPrint('TV THUMBNAIL VALUE: ${json["tv_thumbnail"]}');
    debugPrint('AVAILABLE KEYS: ${json.keys.toList()}');
    return VideoModel(
      id: json["id"]?.toString() ?? "",
      title: json["title"] ?? "",
      description: json["description"] ?? "",
      year: json["year"]?.toString() ?? "",
      duration: json["duration"]?.toString() ?? "",
      category: json["category"] ?? "",
      language: json["language"] ?? "",
      rating: (json["rating"] ?? 0).toDouble(),

      thumbnail: json["thumbnail"] ?? "",
      tvThumbnail: json["tv_thumbnail"] ?? "",
      banner: json["banner"] ?? json["thumbnail"] ?? "",
      titleImage: json["title_image"] ?? "",

      genres: List<String>.from(json["genres"] ?? []),
      cast: List<String>.from(json["cast"] ?? []),
      directors: List<String>.from(json["directors"] ?? []),

      featured: json["featured"] ?? false,
      trending: json["trending"] ?? false,
      continueWatching: json["continueWatching"] ?? false,
      progress: (json["progress"] ?? 0).toDouble(),

      isSeries: json["isSeries"] ?? false,
      seasons: (json["seasons"] as List<dynamic>?)
              ?.map((e) => Season.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      "description": description,
      "year": year,
      "duration": duration,
      "category": category,
      "language": language,
      "rating": rating,
      "thumbnail": thumbnail,
      "tv_thumbnail": tvThumbnail,
      "banner": banner,
      "title_image": titleImage,
      "genres": genres,
      "cast": cast,
      "directors": directors,
      "featured": featured,
      "trending": trending,
      "continueWatching": continueWatching,
      "progress": progress,
      "isSeries": isSeries,
      "seasons": seasons.map((e) => e.toJson()).toList(),
    };
  }
}

class Season {
  final String name;
  final List<Episode> episodes;

  const Season({
    required this.name,
    required this.episodes,
  });

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      name: json["name"] ?? "",
      episodes: (json["episodes"] as List<dynamic>?)
              ?.map((e) => Episode.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "episodes": episodes.map((e) => e.toJson()).toList(),
    };
  }
}

class Episode {
  final int number;
  final String title;
  final String description;
  final String duration;
  final String thumbnail;

  const Episode({
    required this.number,
    required this.title,
    required this.description,
    required this.duration,
    required this.thumbnail,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      number: json["number"] ?? 1,
      title: json["title"] ?? "",
      description: json["description"] ?? "",
      duration: json["duration"] ?? "",
      thumbnail: json["thumbnail"] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "number": number,
      "title": title,
      "description": description,
      "duration": duration,
      "thumbnail": thumbnail,
    };
  }
}
