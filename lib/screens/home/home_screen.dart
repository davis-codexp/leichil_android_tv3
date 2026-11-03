import 'package:palette_generator/palette_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/home_content_model.dart';
import '../../models/video_model.dart';
import '../../services/content_service.dart';
import '../../widgets/banners/tv_banner.dart';
import '../../widgets/navigation/tv_focus_style.dart';
import '../../widgets/navigation/tv_focus_wrapper.dart';
import '../../widgets/rows/tv_movie_row_landscape.dart';
import '../details/detail_screen.dart';
import '../player/player_screen.dart';
import '../view_all/view_all_screen.dart';
import '../../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onFocusSidebar;
  final FocusNode? entryFocusNode;

  const HomeScreen({
    super.key,
    this.onFocusSidebar,
    this.entryFocusNode,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _background = Color.fromARGB(255, 0, 0, 0);
  static const Color _surface = Color.fromARGB(255, 0, 0, 0);
  static const Color _accent = Color(0xFF36C8D5);

  Color _heroTint = const Color(0xFF10141B);

  Future<void> _updateHeroTint(VideoModel? video) async {
    if (video == null || video.tvThumbnail.trim().isEmpty) return;

    var imageUrl = video.tvThumbnail.trim();

    if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
      imageUrl =
          'https://assets.leichiltv.com/${imageUrl.replaceFirst(RegExp(r'^/+'), '')}';
    }

    try {
      final palette = await PaletteGenerator.fromImageProvider(
        NetworkImage(imageUrl),
        size: const Size(200, 120),
        maximumColorCount: 12,
      );

      if (!mounted) return;

      setState(() {
        _heroTint =
            palette.dominantColor?.color ??
            palette.vibrantColor?.color ??
            const Color(0xFF10141B);
      });
    } catch (e) {
      debugPrint('Hero palette extraction failed: $e');
    }
  }

  final ScrollController _scrollController = ScrollController();
  late final FocusNode _playFocus =
      widget.entryFocusNode ?? FocusNode(debugLabel: 'HomePlayNow');
  final FocusNode _infoFocus = FocusNode(debugLabel: 'HomeMoreInfo');
  final FocusNode _movieFirstFocus = FocusNode(debugLabel: 'MovieFirstPoster');
  final FocusNode _seriesFirstFocus = FocusNode(
    debugLabel: 'SeriesFirstPoster',
  );
  final FocusNode _continueWatchingFocus = FocusNode(
    debugLabel: 'ContinueWatchingFirstPoster',
  );
  final FocusNode _seriesContinueWatchingFocus = FocusNode(
    debugLabel: 'SeriesContinueWatchingFirstPoster',
  );
  final FocusNode _firstViewAllFocus = FocusNode(debugLabel: 'FirstViewAll');
  final Map<String, List<FocusNode>> _rowFocusNodes = {};
  final Map<String, GlobalKey> _rowContextKeys = {};
  final Map<String, ValueChanged<int>> _rowFocusRequests = {};
  final List<String> _rowOrder = [];
  int _rowNavigationGeneration = 0;

  void _navigateBetweenRows({
    required String currentRowKey,
    required int posterIndex,
    required int direction,
  }) {
    final currentRowIndex = _rowOrder.indexOf(currentRowKey);
    if (currentRowIndex < 0) return;
    final targetRowIndex = currentRowIndex + direction;
    if (targetRowIndex < 0) {
      ++_rowNavigationGeneration;
      _scrollToTop();
      if (_heroVideo() != null) {
        _infoFocus.requestFocus();
      } else {
        widget.onFocusSidebar?.call();
      }
      return;
    }

    if (targetRowIndex >= _rowOrder.length) return;
    final targetKey = _rowOrder[targetRowIndex];
    final targetNodes = _rowFocusNodes[targetKey];
    if (targetNodes == null || targetNodes.isEmpty) return;
    final targetIndex = posterIndex.clamp(0, targetNodes.length - 1).toInt();
    final generation = ++_rowNavigationGeneration;
    _rowFocusRequests[targetKey]?.call(targetIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _rowNavigationGeneration) return;
      final rowContext = _rowContextKeys[targetKey]?.currentContext;
      if (rowContext == null || !_scrollController.hasClients) return;
      Scrollable.ensureVisible(
        rowContext,
        alignment: 0.50,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );
    });
  }

  HomeContentResponse? _homeData;
  HomeContentResponse? _seriesData;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    _loadHome();
    _updateHeroTint(_heroVideo());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    if (widget.entryFocusNode == null) _playFocus.dispose();
    _infoFocus.dispose();
    _movieFirstFocus.dispose();
    _seriesFirstFocus.dispose();
    _continueWatchingFocus.dispose();
    _seriesContinueWatchingFocus.dispose();
    _firstViewAllFocus.dispose();
    super.dispose();
  }

  // API INTEGRATION

  Future<void> _loadHome({bool refresh = false}) async {
    if (_isRefreshing) return;

    if (mounted) {
      setState(() {
        if (refresh && (_homeData != null || _seriesData != null)) {
          _isRefreshing = true;
        } else {
          _isLoading = true;
        }

        _error = null;
      });
    }

    try {
      final results = await Future.wait<HomeContentResponse?>([
        ContentService.loadMoviesHome(),

        ContentService.loadSeriesHome(),
      ]);

      if (!mounted) return;
      final movies = results[0];
      final series = results[1];
      if (movies == null && series == null) {
        setState(() {
          _isLoading = false;

          _isRefreshing = false;

          _error = 'Unable to load content. Please try again.';
        });

        return;
      }

      setState(() {
        _homeData = movies;
        _seriesData = series;
        _isLoading = false;
        _isRefreshing = false;
        _error = null;
      });

      debugPrint(
        'LEICHIL TV: movie segments=${movies?.segments.length ?? 0}, '
        'series segments=${series?.segments.length ?? 0}',
      );

      for (final segment in movies?.segments ?? <HomeSegment>[]) {
        debugPrint(
          'MOVIE SEGMENT: title="${segment.title}", '
          'type="${segment.contentType}", '
          'listType="${segment.listType}", '
          'items=${segment.items.length}',
        );
      }

      for (final segment in series?.segments ?? <HomeSegment>[]) {
        debugPrint(
          'SERIES SEGMENT: title="${segment.title}", '
          'type="${segment.contentType}", '
          'listType="${segment.listType}", '
          'items=${segment.items.length}',
        );
      }
    } catch (error, stackTrace) {
      debugPrint('HOME LOAD ERROR: $error');

      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _error = 'Unable to connect to the server.';
      });
    }
  }

  VideoModel _toVideoModel(HomeContentItem item) {
    final genres = item.genre
        .split(',')
        .map((genre) => genre.trim())
        .where((genre) => genre.isNotEmpty)
        .toList();

    return VideoModel(
      id: item.id.toString(),
      title: item.name,
      description: '',
      year: item.releaseYear,
      duration: '',
      category: item.genre,
      language: 'Manipuri',
      rating: item.rating,
      thumbnail: item.thumbnail,
      tvThumbnail: item.tvThumbnail,
      banner: item.banner,
      titleImage: item.titleImage,
      genres: genres,
    );
  }

  VideoModel _asSeries(VideoModel video) {
    return VideoModel(
      id: video.id,
      title: video.title,
      description: video.description,
      year: video.year,
      duration: video.duration,
      category: video.category,
      language: video.language,
      rating: video.rating,
      thumbnail: video.thumbnail,
      tvThumbnail: video.tvThumbnail,
      banner: video.banner,
      titleImage: video.titleImage,
      genres: video.genres,
      isSeries: true,
    );
  }

  // CONTENT HELPERS

  bool _hasContent(HomeContentResponse? response) {
    if (response == null) return false;

    return response.carousel.isNotEmpty ||
        response.continueWatching.isNotEmpty ||
        response.segments.any((segment) => segment.items.isNotEmpty);
  }

  VideoModel? _heroVideo() {
    final movies = _homeData;

    if (movies != null) {
      if (movies.carousel.isNotEmpty) {
        return _toVideoModel(movies.carousel.first);
      }

      for (final segment in movies.segments) {
        if (segment.items.isNotEmpty) {
          return _toVideoModel(segment.items.first);
        }
      }
    }

    final series = _seriesData;

    if (series != null) {
      if (series.carousel.isNotEmpty) {
        return _asSeries(_toVideoModel(series.carousel.first));
      }

      for (final segment in series.segments) {
        if (segment.items.isNotEmpty) {
          return _asSeries(_toVideoModel(segment.items.first));
        }
      }
    }

    return null;
  }

  // NAVIGATION

  void _openDetails(VideoModel video) {
    final id = int.tryParse(video.id);
    if (id == null || id <= 0) {
      debugPrint('Invalid content ID: ${video.id}');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailScreen(contentId: id)),
    );
  }

  Future<void> _playNow(VideoModel video) async {
    final id = int.tryParse(video.id);

    if (id == null || id <= 0) {
      _showHomeMessage('Unable to play this content.');
      return;
    }

    try {
      // Step 1: Verify subscription.
      final subscription = await ContentService.verifySubscription();

      if (!mounted) return;

      if (subscription.statusCode != 200 ||
          subscription.data is! Map ||
          subscription.data['success'] != true) {
        _showHomeMessage('An active subscription is required to play.');
        return;
      }

      // Step 2: Fetch the latest content details.
      final response = await ContentService.getContent(id);

      if (!mounted) return;

      if (response.statusCode != 200 ||
          response.data is! Map ||
          response.data['success'] != true ||
          response.data['result'] is! Map) {
        _showHomeMessage('Unable to load video details. Please try again.');
        return;
      }

      final content = Map<String, dynamic>.from(response.data['result']);

      var streamUrl =
          (content['video'] ??
                  content['video_url'] ??
                  content['stream_url'] ??
                  content['url'])
              ?.toString()
              .trim() ??
          '';

      int? episodeId;
      var playerTitle = content['name']?.toString() ?? video.title;

      // Step 3: For series, select the first available episode.
      if (streamUrl.isEmpty && video.isSeries && content['episodes'] is List) {
        final episodes = (content['episodes'] as List)
            .whereType<Map>()
            .map((episode) => Map<String, dynamic>.from(episode))
            .where((episode) {
              final url =
                  (episode['video'] ??
                          episode['video_url'] ??
                          episode['stream_url'] ??
                          episode['url'])
                      ?.toString()
                      .trim() ??
                  '';

              return url.isNotEmpty;
            })
            .toList();

        int number(dynamic value) => value is num
            ? value.toInt()
            : int.tryParse(value?.toString() ?? '') ?? 0;

        episodes.sort((a, b) {
          final seasonCompare = number(
            a['season'],
          ).compareTo(number(b['season']));

          if (seasonCompare != 0) return seasonCompare;

          final episodeCompare = number(
            a['episode_number'] ?? a['episode'],
          ).compareTo(number(b['episode_number'] ?? b['episode']));

          if (episodeCompare != 0) return episodeCompare;

          return number(a['id']).compareTo(number(b['id']));
        });

        if (episodes.isNotEmpty) {
          final episode = episodes.first;

          streamUrl =
              (episode['video'] ??
                      episode['video_url'] ??
                      episode['stream_url'] ??
                      episode['url'])
                  .toString()
                  .trim();

          episodeId = number(episode['id']) > 0 ? number(episode['id']) : null;

          playerTitle = episode['name']?.toString().trim().isNotEmpty == true
              ? episode['name'].toString()
              : video.title;
        }
      }

      if (streamUrl.isEmpty) {
        _showHomeMessage('Video is not available.');
        return;
      }

      // Step 4: Request the signed URL.
      final streamResponse = await ApiService.post('/api/v1/app/stream', {
        'url': streamUrl,
      });

      if (!mounted) return;

      if (streamResponse.statusCode != 200 ||
          streamResponse.data is! Map ||
          streamResponse.data['success'] != true) {
        debugPrint('SIGNED URL ERROR: ${streamResponse.data}');
        _showHomeMessage('Unable to prepare video stream. Please try again.');
        return;
      }

      final signedUrl = streamResponse.data['url']?.toString().trim() ?? '';

      if (signedUrl.isEmpty) {
        _showHomeMessage('Invalid video stream URL.');
        return;
      }

      debugPrint('SIGNED STREAM URL RECEIVED');

      // Step 5: Open the player using the signed URL.
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => PlayerScreen(
            streamUrl: signedUrl,
            title: playerTitle,
            contentId: id,
            episodeId: episodeId,
          ),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('PLAY NOW ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        _showHomeMessage('Unable to start playback. Please try again.');
      }
    }
  }

  void _showHomeMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _openViewAll(String title, String type) {
    Navigator.push(
      context,

      MaterialPageRoute(
        builder: (_) => ViewAllScreen(title: title, contentType: type),
      ),
    );
  }

  KeyEventResult _handleHeroKeys(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;

    final isDirectionKey =
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown;

    if (!isDirectionKey) return KeyEventResult.ignored;

    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      widget.onFocusSidebar?.call();

      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowRight) {
      _infoFocus.requestFocus();

      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowLeft) {
      widget.onFocusSidebar?.call();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowDown) {
      _focusFirstAvailableRow();

      return KeyEventResult.handled;
    }

    return KeyEventResult.handled;
  }

  KeyEventResult _handleInfoKeys(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;

    final isDirectionKey =
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown;

    if (!isDirectionKey) return KeyEventResult.ignored;

    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowLeft) {
      _playFocus.requestFocus();

      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      widget.onFocusSidebar?.call();

      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowDown) {
      _focusFirstAvailableRow();

      return KeyEventResult.handled;
    }

    return KeyEventResult.handled;
  }

  void _focusFirstAvailableRow() {
    final movieContinueExists = _homeData?.continueWatching.isNotEmpty ?? false;

    final moviesHaveRows =
        _homeData?.segments.any((segment) => segment.items.isNotEmpty) ?? false;

    final seriesContinueExists =
        _seriesData?.continueWatching.isNotEmpty ?? false;

    final seriesHaveRows =
        _seriesData?.segments.any((segment) => segment.items.isNotEmpty) ??
        false;

    if (movieContinueExists) {
      _continueWatchingFocus.requestFocus();
    } else if (moviesHaveRows) {
      _movieFirstFocus.requestFocus();
    } else if (seriesContinueExists) {
      _seriesContinueWatchingFocus.requestFocus();
    } else if (seriesHaveRows) {
      _seriesFirstFocus.requestFocus();
    } else {
      return;
    }

    // Wait for focus/layout to settle, then center the first content row.
    _centerFirstAvailableRow();
  }

  void _centerFirstAvailableRow() {
    final generation = ++_rowNavigationGeneration;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          generation != _rowNavigationGeneration ||
          !_scrollController.hasClients) {
        return;
      }

      for (final rowKey in _rowOrder) {
        final rowContext = _rowContextKeys[rowKey]?.currentContext;
        if (rowContext == null) continue;

        Scrollable.ensureVisible(
          rowContext,
          alignment: 0.50,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
        );
        return;
      }
    });
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOutCubic,
    );
  }

  void _onHeroFocus() {
    _scrollToTop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(child: _buildContent()),
            if (_isRefreshing)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: _accent,
                  backgroundColor: Colors.transparent,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    _rowOrder.clear();

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }

    if (_error != null) {
      return _buildMessage(
        _error!,

        buttonText: 'Try Again',

        onPressed: () => _loadHome(),
      );
    }

    final hasMovies = _hasContent(_homeData);

    final hasSeries = _hasContent(_seriesData);

    if (!hasMovies && !hasSeries) {
      return _buildMessage(
        'No content available right now.',

        buttonText: 'Refresh',

        onPressed: () => _loadHome(),
      );
    }

    return RefreshIndicator(
      color: _accent,
      backgroundColor: _surface,
      onRefresh: () => _loadHome(refresh: true),
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 70),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHero(),
            Transform.translate(
              offset: const Offset(0, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContinueWatching(),
                  _buildSegments(
                    _homeData,
                    isSeries: false,
                    firstFocusNode: _movieFirstFocus,
                  ),
                  _buildContinueWatchingSeries(),
                  _buildSegments(
                    _seriesData,
                    isSeries: true,
                    firstFocusNode: _seriesFirstFocus,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    final video = _heroVideo();

    if (video == null) {
      return Container(
        height: 360,

        width: double.infinity,

        alignment: Alignment.center,

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,

            end: Alignment.bottomRight,

            colors: [Color(0xFF151D27), _background],
          ),
        ),

        child: const Text(
          'No featured content available',

          style: TextStyle(color: Colors.white70, fontSize: 18),
        ),
      );
    }

    return TvBanner(
      video: video,

      playFocusNode: _playFocus,

      infoFocusNode: _infoFocus,

      onHeroFocus: _onHeroFocus,

      onPlay: () => _playNow(video),

      onMoreInfo: () => _openDetails(video),

      onPlayKeyEvent: _handleHeroKeys,

      onInfoKeyEvent: _handleInfoKeys,
    );
  }

  Widget _buildContinueWatching() {
    final items = _homeData?.continueWatching ?? [];

    if (items.isEmpty) return const SizedBox.shrink();

    const rowKey = 'MOVIE_CONTINUE';

    _rowOrder.add(rowKey);

    return TvMovieRowLandscape(
      key: _rowContextKeys.putIfAbsent(rowKey, GlobalKey.new),

      title: 'Continue Watching',

      videos: items.map(_toVideoModel).toList(),

      firstFocusNode: _continueWatchingFocus,

      onVideoPressed: _openDetails,

      onFocusNodesChanged: (nodes) => _rowFocusNodes[rowKey] = nodes,

      onRegisterFocusRequest: (callback) =>
          _rowFocusRequests[rowKey] = callback,

      onNavigateUp: (index) => _navigateBetweenRows(
        currentRowKey: rowKey,

        posterIndex: index,

        direction: -1,
      ),

      onNavigateDown: (index) => _navigateBetweenRows(
        currentRowKey: rowKey,

        posterIndex: index,

        direction: 1,
      ),
    );
  }

  Widget _buildContinueWatchingSeries() {
    final items = _seriesData?.continueWatching ?? [];

    if (items.isEmpty) return const SizedBox.shrink();

    const rowKey = 'SERIES_CONTINUE';

    _rowOrder.add(rowKey);

    return TvMovieRowLandscape(
      key: _rowContextKeys.putIfAbsent(rowKey, GlobalKey.new),

      title: 'Continue Watching Series',

      videos: items.map((item) => _asSeries(_toVideoModel(item))).toList(),

      firstFocusNode: _seriesContinueWatchingFocus,

      onVideoPressed: _openDetails,

      onFocusNodesChanged: (nodes) => _rowFocusNodes[rowKey] = nodes,

      onRegisterFocusRequest: (callback) =>
          _rowFocusRequests[rowKey] = callback,

      onNavigateUp: (index) => _navigateBetweenRows(
        currentRowKey: rowKey,

        posterIndex: index,

        direction: -1,
      ),

      onNavigateDown: (index) => _navigateBetweenRows(
        currentRowKey: rowKey,

        posterIndex: index,

        direction: 1,
      ),
    );
  }

  Widget _buildSegments(
    HomeContentResponse? response, {

    required bool isSeries,

    required FocusNode firstFocusNode,
  }) {
    final segments = response?.segments ?? [];

    if (segments.isEmpty) return const SizedBox.shrink();

    final seenTitles = <String>{};

    final rows = <Widget>[];

    var firstRowAssigned = false;

    for (final segment in segments) {
      if (segment.items.isEmpty) continue;

      final rawTitle = segment.title.trim();

      final normalizedTitle = rawTitle.toLowerCase();

      final title = isSeries && normalizedTitle == 'new releases'
          ? 'Series'
          : rawTitle.isEmpty
          ? (isSeries ? 'Series' : 'Newly Added on Leichil TV')
          : rawTitle;

      final dedupeKey = title.toLowerCase();

      if (!seenTitles.add(dedupeKey)) continue;

      final videos = segment.items.map(_toVideoModel).map((video) {
        return isSeries ? _asSeries(video) : video;
      }).toList();

      final rowKey = '${isSeries ? 'SERIES' : 'MOVIE'}_$dedupeKey';

      _rowOrder.add(rowKey);

      rows.add(
        TvMovieRowLandscape(
          key: _rowContextKeys.putIfAbsent(rowKey, GlobalKey.new),

          title: title,

          videos: videos,

          firstFocusNode: firstRowAssigned ? null : firstFocusNode,

          onVideoPressed: _openDetails,

          onViewAll: () => _openViewAll(title, isSeries ? 'SERIES' : 'MOVIE'),

          viewAllFocusNode: !firstRowAssigned ? _firstViewAllFocus : null,

          onFocusNodesChanged: (nodes) => _rowFocusNodes[rowKey] = nodes,

          onRegisterFocusRequest: (callback) =>
              _rowFocusRequests[rowKey] = callback,

          onNavigateUp: (index) => _navigateBetweenRows(
            currentRowKey: rowKey,

            posterIndex: index,

            direction: -1,
          ),

          onNavigateDown: (index) => _navigateBetweenRows(
            currentRowKey: rowKey,

            posterIndex: index,

            direction: 1,
          ),
        ),
      );

      firstRowAssigned = true;
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  Widget _buildMessage(
    String message, {

    required String buttonText,

    required VoidCallback onPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Container(
              width: 76,

              height: 76,

              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.10),

                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.movie_filter_outlined,

                color: _accent,

                size: 36,
              ),
            ),

            const SizedBox(height: 22),

            Text(
              message,

              textAlign: TextAlign.center,

              style: const TextStyle(
                color: Colors.white70,

                fontSize: 20,

                height: 1.4,
              ),
            ),

            const SizedBox(height: 24),

            TvFocusWrapper(
              autofocus: true,

              style: TvFocusStyle.button,

              onPressed: onPressed,

              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,

                  vertical: 14,
                ),

                decoration: BoxDecoration(
                  color: _accent,

                  borderRadius: BorderRadius.circular(12),
                ),

                child: Row(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    const Icon(Icons.refresh_rounded, color: Color(0xFF061114)),

                    const SizedBox(width: 8),

                    Text(
                      buttonText,

                      style: const TextStyle(
                        color: Color(0xFF061114),

                        fontSize: 16,

                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
