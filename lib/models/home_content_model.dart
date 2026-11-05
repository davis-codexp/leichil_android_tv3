class HomeContentItem {
  final int id;
  final String name;
  final String genre;
  final String releaseYear;

  final String thumbnail;
  final String tvThumbnail;
  final String banner;
  final String titleImage;

  final double rating;

  final String contentCategory;
  final bool isPremium;

  const HomeContentItem({
    required this.id,
    required this.name,
    required this.genre,
    required this.releaseYear,
    required this.thumbnail,
    this.tvThumbnail = '',
    this.banner = '',
    this.titleImage = '',
    required this.rating,
    this.contentCategory = '',
    this.isPremium = false,
  });

  factory HomeContentItem.fromJson(Map<String, dynamic> json) {
    final category = (
      json['content_category'] ??
      json['category'] ??
      ''
    ).toString().trim().toUpperCase();

    final premiumFlag = _isTrue(
      json['is_premium'] ?? json['isPremium'],
    );

    return HomeContentItem(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      genre: json['genre']?.toString() ?? '',
      releaseYear: json['release_year']?.toString() ?? '',

      thumbnail: json['thumbnail']?.toString() ?? '',
      tvThumbnail: json['tv_thumbnail']?.toString() ?? '',
      banner: json['banner']?.toString() ?? '',
      titleImage: json['title_image']?.toString() ?? '',

      rating: _toDouble(json['rating']),

      contentCategory: category,

      isPremium: premiumFlag ||
          category == 'PREMIUM' ||
          category == 'SHARED',
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _isTrue(dynamic value) {
    if (value == true || value == 1) return true;

    final text = value?.toString().trim().toLowerCase() ?? '';

    return text == 'true' || text == '1' || text == 'yes';
  }
}

class HomeSegment {
  final String title;
  final String contentType;
  final String listType;
  final List<HomeContentItem> items;

  const HomeSegment({
    required this.title,
    required this.contentType,
    required this.listType,
    required this.items,
  });

  factory HomeSegment.fromJson(Map<String, dynamic> json) {
    final rawList = json['list'];
    final items = <HomeContentItem>[];

    if (rawList is List) {
      for (final item in rawList) {
        if (item is Map) {
          items.add(
            HomeContentItem.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    return HomeSegment(
      title: json['title']?.toString() ?? '',
      contentType: json['content_type']?.toString() ?? '',
      listType: json['list_type']?.toString() ?? '',
      items: items,
    );
  }
}

class HomeContentResponse {
  final List<HomeContentItem> carousel;
  final List<HomeContentItem> continueWatching;
  final List<HomeSegment> segments;

  const HomeContentResponse({
    required this.carousel,
    required this.continueWatching,
    required this.segments,
  });

  factory HomeContentResponse.fromJson(Map<String, dynamic> json) {
    final carousel = <HomeContentItem>[];

    if (json['carousel'] is List) {
      for (final item in json['carousel']) {
        if (item is Map) {
          carousel.add(
            HomeContentItem.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    final continueWatching = <HomeContentItem>[];

    if (json['continue_watching'] is List) {
      for (final item in json['continue_watching']) {
        if (item is Map) {
          continueWatching.add(
            HomeContentItem.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    final segments = <HomeSegment>[];

    if (json['segments'] is List) {
      for (final item in json['segments']) {
        if (item is Map) {
          segments.add(
            HomeSegment.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    return HomeContentResponse(
      carousel: carousel,
      continueWatching: continueWatching,
      segments: segments,
    );
  }
}
