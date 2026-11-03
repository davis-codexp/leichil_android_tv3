class VideoData {
  final int id;
  final String title;
  final String description;
  final int year;
  final String duration;
  final String category;
  final double rating;
  final String thumbnail;
  final String banner;
  final bool isSeries;
  final List<SeasonData> seasons;

  const VideoData({
    required this.id,
    required this.title,
    this.description = '',
    this.year = 0,
    this.duration = '',
    this.category = '',
    this.rating = 0.0,
    this.thumbnail = '',
    this.banner = '',
    this.isSeries = false,
    this.seasons = const [],
  });

  factory VideoData.fromJson(Map<String, dynamic> json) {
    return VideoData(
      id: _toInt(json['id']),
      title: (json['title'] ?? json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      year: _toInt(json['year'] ?? json['release_year']),
      duration: (json['duration'] ?? json['runtime'] ?? '').toString(),
      category: _toCategory(json['category'] ?? json['genre']),
      rating: _toDouble(json['rating']),
      thumbnail: (json['thumbnail'] ?? '').toString(),
      banner: (json['banner'] ?? json['backdrop'] ?? '').toString(),
      isSeries: _isSeries(json['isSeries'] ?? json['content_type']),
      seasons: (json['seasons'] is List)
          ? (json['seasons'] as List)
                .whereType<Map>()
                .map(
                  (item) =>
                      SeasonData.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static String _toCategory(dynamic value) {
    if (value is List) return value.join(', ');
    return value?.toString() ?? '';
  }

  static bool _isSeries(dynamic value) {
    if (value is bool) return value;
    final text = value?.toString().toUpperCase() ?? '';
    return text == 'SERIES' || text == 'TRUE';
  }
}

class SeasonData {
  final int seasonNumber;
  final List<EpisodeData> episodes;

  const SeasonData({required this.seasonNumber, this.episodes = const []});

  factory SeasonData.fromJson(Map<String, dynamic> json) {
    final rawEpisodes = json['episodes'];

    return SeasonData(
      seasonNumber: _toInt(json['season_number'] ?? json['seasonNumber']),
      episodes: rawEpisodes is List
          ? rawEpisodes
                .whereType<Map>()
                .map(
                  (item) =>
                      EpisodeData.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class EpisodeData {
  final int id;
  final int episodeNumber;
  final String title;
  final String description;
  final String videoUrl;
  final String thumbnail;

  const EpisodeData({
    required this.id,
    required this.episodeNumber,
    required this.title,
    this.description = '',
    this.videoUrl = '',
    this.thumbnail = '',
  });

  factory EpisodeData.fromJson(Map<String, dynamic> json) {
    return EpisodeData(
      id: _toInt(json['id']),
      episodeNumber: _toInt(json['episode_number'] ?? json['episodeNumber']),
      title: (json['title'] ?? json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      videoUrl: (json['video_url'] ?? json['videoUrl'] ?? '').toString(),
      thumbnail: (json['thumbnail'] ?? '').toString(),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
