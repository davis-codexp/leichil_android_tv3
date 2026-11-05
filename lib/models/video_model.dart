class VideoModel {
  final String id;
  final String title;
  final String description;

  final String year;
  final String duration;
  final String category;
  final String contentCategory;
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
  final bool isPremium;

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
    this.contentCategory = "",
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
    this.isPremium = false,
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
    String? contentCategory,
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
    bool? isPremium,
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
      contentCategory: contentCategory ?? this.contentCategory,
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
      isPremium: isPremium ?? this.isPremium,
      progress: progress ?? this.progress,
      isSeries: isSeries ?? this.isSeries,
      seasons: seasons ?? this.seasons,
    );
  }

  static bool _isTrue(dynamic value) {
    if (value == true || value == 1) return true;

    final text = value?.toString().trim().toLowerCase() ?? '';

    return text == 'true' || text == '1' || text == 'yes';
  }

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json["id"]?.toString() ?? "",
      title: json["title"] ?? "",
      description: json["description"] ?? "",
      year: json["year"]?.toString() ?? "",
      duration: json["duration"]?.toString() ?? "",
      category: json["category"] ?? "",
      contentCategory:
          (json["content_category"] ?? json["category"] ?? "").toString(),
      language: json["language"] ?? "",
      rating: (json["rating"] ?? 0).toDouble(),

      thumbnail: json["thumbnail"] ?? "",
      tvThumbnail: json["tv_thumbnail"] ?? "",
      banner: json["banner"] ?? json["thumbnail"] ?? "",
      titleImage: json["title_image"] ?? "",

      genres: List<String>.from(json["genres"] ?? []),
      cast: List<String>.from(json["cast"] ?? []),
      directors: List<String>.from(json["directors"] ?? []),

      featured: _isTrue(json["featured"]),
      trending: _isTrue(json["trending"]),
      continueWatching: _isTrue(json["continueWatching"]),

      isPremium: _isTrue(json["is_premium"] ?? json["isPremium"]),

      progress: (json["progress"] ?? 0).toDouble(),

      isSeries: _isTrue(json["isSeries"]),
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
      "content_category": contentCategory,
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
      "is_premium": isPremium,
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
