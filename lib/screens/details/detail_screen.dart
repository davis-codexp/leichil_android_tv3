import 'package:flutter/material.dart';
import 'package:leichil_android_tv/widgets/cards/tv_movie_card_landscape.dart';
import '../../core/theme/app_dimensions.dart';
import '../../services/api_service.dart';
import '../../services/content_service.dart';
import '../../models/video_model.dart';
import '../../widgets/navigation/tv_focus_style.dart';
import '../../widgets/navigation/tv_focus_wrapper.dart';
import '../player/player_screen.dart';

class DetailScreen extends StatefulWidget {
    final int contentId;
    const DetailScreen({super.key, required this.contentId});

    @override
    State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  Map<String, dynamic>? _content;
  bool _loading = true;
  bool _watchlistLoading = false;
  bool _isWatchlisted = false;
  List<dynamic> _episodeList = [];
  List<dynamic> _allMovies = [];
  bool _moviesLoading = false;
  bool _moviesLoaded = false;
  String _selectedSeason = '1';

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadContent();
    _loadWatchlist();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handlePrimaryFocusChange() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final focusContext = FocusManager.instance.primaryFocus?.context;
      final renderObject = focusContext?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) return;
      final position = _scrollController.position;
      final screenHeight = MediaQuery.sizeOf(context).height;
      final targetY = screenHeight * 0.50;
      final focusedCenterY = renderObject
          .localToGlobal(renderObject.size.center(Offset.zero))
          .dy;
      final delta = focusedCenterY - targetY;
      if (delta.abs() < 14) return;
      final targetOffset = (position.pixels + delta)
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble();
      if ((targetOffset - position.pixels).abs() < 2) return;
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    if (_moviesLoaded || _moviesLoading) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 700) {
      _moviesLoaded = true;
      _loadMovies();
    }
  }

  Future<void> _loadContent() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    final response = await ContentService.getContent(widget.contentId);
    if (!mounted) {
      return;
    }

    if (response.statusCode == 200 &&
        response.data is Map &&
        response.data['success'] == true) {
      final result = response.data['result'];
      if (result is Map) {
        final content = Map<String, dynamic>.from(result);
        setState(() {
          _content = content;
          _loading = false;
        });
        if (_isSeries) {
          _generateEpisodes(1);
        }
        // _loadMovies();
        return;
      }
    }

    setState(() {
      _loading = false;
    });
  }

  Future<void> _loadWatchlist() async {
    try {
      final response = await ApiService.get(
        '/api/v1/app/activities/favourites?limit=1000',
      );

      if (!mounted) {
        return;
      }

      if (response.statusCode != 200 ||
          response.data is! Map ||
          response.data['success'] != true) {
        return;
      }

      final result = response.data['result'];

      List<dynamic> list = [];

      if (result is Map && result['list'] is List) {
        list = List<dynamic>.from(result['list']);
      } else if (result is List) {
        list = List<dynamic>.from(result);
      }

      final found = list.any((item) {
        if (item is! Map) {
          return false;
        }

        final id = item['content_id'] ?? item['id'];

        return id?.toString() == widget.contentId.toString();
      });

      setState(() {
        _isWatchlisted = found;
      });
    } catch (_) {}
  }

  Future<void> _toggleWatchlist() async {
    if (_watchlistLoading) {
      return;
    }

    setState(() {
      _watchlistLoading = true;
    });

    try {
      final response = await ApiService.post(
        '/api/v1/app/activities/favourites',

        {'content_id': widget.contentId},
      );

      if (!mounted) {
        return;
      }

      if (response.statusCode == 200 &&
          response.data is Map &&
          response.data['success'] == true) {
        final result = response.data['result'];

        bool newState = !_isWatchlisted;

        if (result is Map && result['is_favourite'] != null) {
          newState = result['is_favourite'] == true;
        }

        setState(() {
          _isWatchlisted = newState;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _watchlistLoading = false;
        });
      }
    }
  }

  Future<void> _loadMovies() async {
    if (_moviesLoading) {
      return;
    }

    setState(() {
      _moviesLoading = true;
    });

    try {
      final response = await ApiService.get('/api/v1/app/contents');

      if (!mounted) {
        return;
      }

      if (response.statusCode == 200 &&
          response.data is Map &&
          response.data['success'] == true) {
        final result = response.data['result'];

        List<dynamic> list = [];

        if (result is Map && result['list'] is List) {
          list = List<dynamic>.from(result['list']);
        } else if (result is List) {
          list = List<dynamic>.from(result);
        }

        final content = list.where((item) {
          if (item is! Map) return false;

          final type =
              (item['content_type'] ?? item['contentType'] ?? item['type'])
                  ?.toString()
                  .trim()
                  .toUpperCase();

          final id = item['content_id'] ?? item['id'];

          return (type == 'MOVIE' || type == 'SERIES') &&
              id?.toString() != widget.contentId.toString();
        }).toList();

        setState(() {
          _allMovies = content;

          _moviesLoading = false;

          _moviesLoaded = true;
        });
      } else {
        setState(() {
          _moviesLoading = false;

          _moviesLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _moviesLoading = false;

          _moviesLoaded = true;
        });
      }
    }
  }

  bool get _isSeries {
    return (_content?['content_type'] ?? _content?['type'])
            ?.toString()
            .toUpperCase() ==
        'SERIES';
  }

  int get _contentId {
    final value = _content?['id'] ?? widget.contentId;

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString()) ?? widget.contentId;
  }

  String _imageUrl(dynamic value) {
    final image = value?.toString().trim() ?? '';

    if (image.isEmpty) {
      return '';
    }

    if (image.startsWith('http://') || image.startsWith('https://')) {
      return image;
    }

    if (image.startsWith('/')) {
      return 'https://assets.leichiltv.com$image';
    }

    return 'https://assets.leichiltv.com/$image';
  }

  void _generateEpisodes(int season) {
    final episodes = _content?['episodes'];

    final result = <dynamic>[];

    if (episodes is List) {
      for (final episode in episodes) {
        if (episode is! Map) {
          continue;
        }

        final rawSeason = episode['season'];

        final episodeSeason = rawSeason is num
            ? rawSeason.toInt()
            : int.tryParse(rawSeason?.toString() ?? '');

        if (episodeSeason == season) {
          result.add(episode);
        }
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _episodeList = result;
    });
  }

  int _seasonCount() {
    final value = _content?['seasons'];

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String get _contentCategory {
    return (_content?['category'] ?? '').toString().trim().toUpperCase();
  }

  bool get _isPremiumContent =>
      _contentCategory == 'PREMIUM' || _contentCategory == 'SHARED';

  bool get _isSubscriptionContent => _contentCategory == 'SUBSCRIPTION';

  Future<bool> _verifyContentAccess() async {
    try {
      if (!_isPremiumContent && !_isSubscriptionContent) {
        return true;
      }

      final endpoint = _isPremiumContent
          ? '/api/v1/app/orders/purchases/$_contentId'
          : '/api/v1/app/subscriptions/verify';

      final response = await ApiService.get(endpoint);

      debugPrint('CONTENT CATEGORY: $_contentCategory');
      debugPrint('ACCESS ENDPOINT: $endpoint');
      debugPrint('ACCESS RESPONSE: ${response.data}');

      return response.statusCode == 200 &&
          response.data is Map &&
          response.data['success'] == true;
    } catch (e, stackTrace) {
      debugPrint('Content access verification error: $e');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

    Future<void> _openPaymentScreen({String? episodeTitle}) async {
        final title = episodeTitle ?? _content?['name']?.toString() ?? 'Movie';
        String qrImg = "";

        try {
            final response = await ApiService.post("/api/v1/app/orders/qr", {"content_id": _contentId}); 
            if (!mounted) return;
            if (response.statusCode == 200 && response.data["success"] == true) {
                qrImg = response.data["result"];
                debugPrint("$_contentId");
            }
        } catch(err) {
            debugPrint("$err");
            return;
        }

        if (_isPremiumContent) {
            Navigator.of(context, rootNavigator: true).pushNamed(
                '/checkout',
                arguments: <String, dynamic>{
                    'contentId': _contentId,
                    'title': title,
                    'posterUrl': _imageUrl(_content?['thumbnail']),
                    'price': (_content?['price'] as num?)?.toInt() ??
                            int.tryParse(_content?['price']?.toString() ?? '') ?? 0,
                    'qrImg': qrImg,
                },
            );
            return;
        }
        if (_isSubscriptionContent) {
            
            try {
                final response = await ApiService.get("/api/v1/app/subscription-plans"); 
                if (!mounted) return;
                if (response.statusCode == 200 && response.data["success"] == true) {
                    final result = response.data["result"]["list"][0];
                    Map<String, dynamic>.from(result);
                    String planName = result["name"];
                    int price = result["price"];
                    Navigator.of(context, rootNavigator: true).pushNamed(
                        '/subscription',
                        arguments: <String, dynamic>{
                            'price': price,
                            'planName': planName,
                            'qrImg': qrImg,
                        },
                    );
                    return;
                }
            } catch(err) {
                debugPrint("$err");
                return;
            } 
        }
        _showMessage('Unable to verify access. Please try again.');
    }

  Future<void> _play() async {
    try {
      final hasAccess = await _verifyContentAccess();
      if (!mounted) return;

      if (!hasAccess) {
        _openPaymentScreen();
        return;
      }

      final streamUrl = _content?['video']?.toString().trim() ?? '';
      if (streamUrl.isEmpty) {
        _showMessage('Video is not available.');
        return;
      }

      final signedUrl = await _getSignedStreamUrl(streamUrl);
      if (!mounted) return;

      if (signedUrl == null) {
        _showMessage('Unable to generate video URL.');
        return;
      }

      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => PlayerScreen(
            streamUrl: signedUrl,
            title: _content?['name']?.toString() ?? '',
            contentId: _contentId,
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Playback error: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) _showMessage('Unable to play this content.');
    }
  }

  Future<void> _playEpisode(Map<String, dynamic> episode) async {
    try {
      // A series uses its parent content category for entitlement verification.
      final hasAccess = await _verifyContentAccess();
      if (!mounted) return;

      if (!hasAccess) {
        _openPaymentScreen(episodeTitle: episode['name']?.toString());
        return;
      }

      final streamUrl =
          (episode['video'] ??
                  episode['video_url'] ??
                  episode['stream_url'] ??
                  episode['url'])
              ?.toString()
              .trim() ??
          '';

      if (streamUrl.isEmpty) {
        _showMessage('Episode video is not available.');
        return;
      }

      final signedUrl = await _getSignedStreamUrl(streamUrl);
      if (!mounted) return;

      if (signedUrl == null) {
        _showMessage('Unable to generate episode URL.');
        return;
      }

      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => PlayerScreen(
            streamUrl: signedUrl,
            title:
                episode['name']?.toString() ??
                _content?['name']?.toString() ??
                '',
            contentId: _contentId,
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Episode playback error: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) _showMessage('Unable to play this episode.');
    }
  }

  Future<String?> _getSignedStreamUrl(String streamUrl) async {
    try {
      final response = await ApiService.post('/api/v1/app/stream', {
        'url': streamUrl,
      });

      if (response.statusCode != 200 ||
          response.data is! Map ||
          response.data['success'] != true) {
        return null;
      }

      final signedUrl = response.data['url']?.toString().trim() ?? '';

      return signedUrl.isEmpty ? null : signedUrl;
    } catch (e) {
      // debugPrint('Signed URL error: $e');
      return null;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,

        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_content == null) {
      return Scaffold(
        backgroundColor: Colors.black,

        body: Center(
          child: TvFocusWrapper(
            autofocus: true,

            style: TvFocusStyle.button,

            onFocusChanged: (_) => _handlePrimaryFocusChange(),

            onPressed: _loadContent,

            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),

              decoration: BoxDecoration(
                color: Colors.white10,

                borderRadius: BorderRadius.circular(12),
              ),

              child: const Text(
                'Retry',

                style: TextStyle(
                  color: Colors.white,

                  fontSize: 18,

                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),

      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,

          physics: const ClampingScrollPhysics(),

          slivers: [
            SliverToBoxAdapter(child: _buildHero()),

            SliverToBoxAdapter(child: _buildDetails()),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    final title = _content?['name']?.toString() ?? '';
    final titleImage = _imageUrl(
      _content?['title_image'] ?? _content?['titleImage'],
    );
    final dpr = MediaQuery.devicePixelRatioOf(context);

    final year = _content?['release_year']?.toString() ?? '';

    final genre = _content?['genre']?.toString() ?? '';

    final ratingValue = _content?['rating']?.toString().trim() ?? '';

    final rating =
        ratingValue.isEmpty ||
            ratingValue == '0' ||
            ratingValue == '0.0' ||
            ratingValue.toLowerCase() == 'null' ||
            ratingValue.toLowerCase() == 'not rated yet'
        ? 'Not Rated Yet'
        : ratingValue;

    final runtimeMinutes =
        int.tryParse(_content?['runtime']?.toString() ?? '') ?? 0;

    final hours = runtimeMinutes ~/ 60;
    final minutes = runtimeMinutes % 60;

    final runtime = runtimeMinutes > 0
        ? [
            if (hours > 0) '${hours}hr',
            if (minutes > 0) '${minutes}min',
          ].join(' ')
        : '';

    final synopsis =
        (_content?['synopsis'] ?? _content?['description'])
            ?.toString()
            .trim() ??
        '';

    final image = _imageUrl(_content?['banner'] ?? '');

    final screenSize = MediaQuery.sizeOf(context);
    final heroHeight = (screenSize.height * 0.90)
        .clamp(720.0, 850.0)
        .toDouble();

    return SizedBox(
      width: double.infinity,
      height: heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (image.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Image.network(
                image,
                width: screenSize.width,
                cacheWidth: (screenSize.width * dpr).round(),
                fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter,
                errorBuilder: (_, _, _) => const SizedBox(
                  width: double.infinity,
                  height: 300,
                  child: ColoredBox(color: Color.fromARGB(255, 0, 0, 0)),
                ),
              ),
            )
          else
            const ColoredBox(color: Color.fromARGB(255, 0, 0, 0)),

          // Darken only the lower part of the hero image.
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.48, 0.72, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Color(0x99000000),
                      Color(0xE6000000),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned.fill(
            child: Align(
              alignment: const Alignment(0, -0.38),
              child: TvFocusWrapper(
                autofocus: true,
                style: TvFocusStyle.button,
                focusBorderRadius: 18,
                onFocusChanged: (_) => _handlePrimaryFocusChange(),
                onPressed: _play,
                child: Container(
                  width: 88,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.30),
                      width: 1.2,
                    ),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),

          // const DecoratedBox(
          //   decoration: BoxDecoration(
          //     gradient: LinearGradient(
          //       begin: Alignment.centerLeft,
          //       end: Alignment.centerRight,
          //       stops: [0.0, 0.35, 0.65, 1.0],
          //       colors: [
          //         Colors.black,
          //         Color(0xF0000000),
          //         Color(0x99000000),
          //         Colors.transparent,
          //       ],
          //     ),
          //   ),
          // ),

          // const DecoratedBox(
          //   decoration: BoxDecoration(
          //     gradient: LinearGradient(
          //       begin: Alignment.bottomCenter,
          //       end: Alignment.topCenter,
          //       stops: [0.0, 0.20, 0.48, 0.78, 1.0],
          //       colors: [
          //         Colors.black,
          //         Colors.black,
          //         Color(0xE6000000),
          //         Color(0x66000000),
          //         Colors.transparent,
          //       ],
          //     ),
          //   ),
          // ),

          Padding(
            padding: EdgeInsets.fromLTRB(
              AppDimensions.screenHorizontal,

              26,

              AppDimensions.screenHorizontal,

              34,
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                TvFocusWrapper(
                  autofocus: false,
                  style: TvFocusStyle.button,

                  focusBorderRadius: 24,

                  onFocusChanged: (_) => _handlePrimaryFocusChange(),

                  onPressed: () => Navigator.pop(context),

                  child: Container(
                    width: 46,

                    height: 46,

                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 75, 73, 73),

                      borderRadius: BorderRadius.circular(24),
                    ),

                    child: const Icon(
                      Icons.arrow_back_rounded,

                      color: Colors.white,

                      size: 24,
                    ),
                  ),
                ),

                const Spacer(),

                Transform.translate(
                  offset: const Offset(0, -80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                const SizedBox(height: 16),

                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: titleImage.isNotEmpty
                      ? Image.network(
                          titleImage,
                          cacheWidth: (420 * dpr).round(),
                          width: 420,
                          height: 180,
                          fit: BoxFit.contain,
                          alignment: Alignment.centerLeft,
                          errorBuilder: (_, _, _) => Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 58,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.05,
                            ),
                          ),
                        )
                      : Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 58,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.05,
                          ),
                        ),
                ),

                const SizedBox(height: 20),

                Wrap(
                  spacing: 12,

                  runSpacing: 6,

                  crossAxisAlignment: WrapCrossAlignment.center,

                  children: [
                    if (year.isNotEmpty) _HeroMeta(text: year),

                    if (runtime.isNotEmpty) _HeroMeta(text: runtime),

                    if (rating.isNotEmpty)
                      _HeroMeta(
                        icon: rating == 'Not Rated Yet'
                            ? null
                            : Icons.star_rounded,

                        text: rating,

                        iconColor: const Color(0xFFFFD27A),
                      ),

                    if (genre.isNotEmpty) _HeroMeta(text: genre),

                    if (_isSeries)
                      Container(
                        width: 5,

                        height: 5,

                        decoration: const BoxDecoration(
                          color: Color(0xFF63DDF5),

                          shape: BoxShape.circle,
                        ),
                      ),

                    _HeroMeta(text: _isSeries ? "SERIES" : "MOVIES"),
                  ],
                ),

                if (synopsis.isNotEmpty) ...[
                  const SizedBox(height: 18),

                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 650),

                    child: Text(
                      synopsis,

                      maxLines: 3,

                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        color: Color(0xFFD0D4D8),

                        fontSize: 16,

                        height: 1.45,

                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],

                // const SizedBox(height: 24),

                // Row(
                //   mainAxisSize: MainAxisSize.min,
                //   children: [
                //     // Play button only for movies.
                //     if (!_isSeries) ...[
                //       TvFocusWrapper(
                //         autofocus: false,
                //         style: TvFocusStyle.button,
                //         focusBorderRadius: 14,
                //         onFocusChanged: (_) => _handlePrimaryFocusChange(),
                //         onPressed: _play,
                //         child: Container(
                //           height: 54,
                //           padding: const EdgeInsets.symmetric(horizontal: 25),
                //           decoration: BoxDecoration(
                //             color: const Color(0xFFF2F4F5),
                //             borderRadius: BorderRadius.circular(13),
                //           ),
                //           child: const Row(
                //             mainAxisSize: MainAxisSize.min,
                //             children: [
                //               Icon(
                //                 Icons.play_arrow_rounded,
                //                 color: Color(0xFF101317),
                //                 size: 27,
                //               ),
                //               SizedBox(width: 9),
                //               Text(
                //                 'Play',
                //                 style: TextStyle(
                //                   color: Color(0xFF101317),
                //                   fontSize: 16,
                //                   fontWeight: FontWeight.w800,
                //                 ),
                //               ),
                //             ],
                //           ),
                //         ),
                //       ),
                //       const SizedBox(width: 12),
                //     ],

                //     // Watchlist button for both movies and series.
                //     TvFocusWrapper(
                //       style: TvFocusStyle.button,
                //       focusBorderRadius: 27,
                //       onFocusChanged: (_) => _handlePrimaryFocusChange(),
                //       onPressed: _toggleWatchlist,
                //       child: Container(
                //         width: 54,
                //         height: 54,
                //         decoration: const BoxDecoration(
                //           color: Color.fromARGB(255, 73, 75, 77),
                //           shape: BoxShape.circle,
                //         ),
                //         child: _watchlistLoading
                //             ? const Padding(
                //                 padding: EdgeInsets.all(16),
                //                 child: CircularProgressIndicator(
                //                   strokeWidth: 2,
                //                   color: Colors.white,
                //                 ),
                //               )
                //             : Icon(
                //                 _isWatchlisted
                //                     ? Icons.check_rounded
                //                     : Icons.add_rounded,
                //                 color: Colors.white,
                //                 size: 27,
                //               ),
                //       ),
                //     ),
                //   ],
                // ),
                const SizedBox(height: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.screenHorizontal,

        30,

        AppDimensions.screenHorizontal,

        70,
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          if (_hasCast) ...[const SizedBox(height: 40), _buildCastSection()],

          if (_isSeries) ...[
            const SizedBox(height: 40),
            _buildEpisodesSection(),
          ],

          const SizedBox(height: 40),

          if (_isSeries) _buildSeriesLikeThis() else _buildMoviesLikeThis(),
        ],
      ),
    );
  }

  Widget _buildEpisodesSection() {
    final seasons = _seasonCount();

    if (seasons <= 0) {
      return const SizedBox.shrink();
    }

    if ((int.tryParse(_selectedSeason) ?? 1) > seasons) {
      _selectedSeason = '1';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        _sectionTitle('Episodes'),

        const SizedBox(height: 16),

        SizedBox(
          height: 58,

          child: ListView.separated(
            scrollDirection: Axis.horizontal,

            itemCount: seasons,

            padding: const EdgeInsets.symmetric(vertical: 4),

            separatorBuilder: (_, _) => const SizedBox(width: 12),

            itemBuilder: (context, index) {
              final season = (index + 1).toString();

              final selected = _selectedSeason == season;

              return TvFocusWrapper(
                style: TvFocusStyle.button,

                focusBorderRadius: 14,

                onFocusChanged: (_) => _handlePrimaryFocusChange(),

                onPressed: () {
                  if (_selectedSeason == season) return;

                  setState(() {
                    _selectedSeason = season;
                  });

                  _generateEpisodes(int.parse(season));
                },

                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),

                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,

                    vertical: 12,
                  ),

                  decoration: BoxDecoration(
                    // color: selected ? const Color(0xFF36C8D5) : Colors.white10,

                    color: selected
                        ? const Color(0xFF36C8D5) // Selected season
                        : const Color.fromARGB(
                            255,
                            54,
                            56,
                            58,
                          ), // Unselected season

                    borderRadius: BorderRadius.circular(14),

                    border: Border.all(
                      color: selected
                          ? const Color(0xFF36C8D5)
                          : Colors.white24,
                    ),
                  ),

                  child: Text(
                    'Season $season',

                    style: TextStyle(
                      color: selected ? Colors.black : Colors.white,

                      fontSize: 15,

                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        if (_episodeList.isEmpty)
          Container(
            width: 800,

            padding: const EdgeInsets.all(25),

            decoration: BoxDecoration(
              color: Colors.white10,

              borderRadius: BorderRadius.circular(14),
            ),

            child: const Text(
              'No episodes available for this season.',

              style: TextStyle(color: Colors.white54, fontSize: 15),
            ),
          )
        else
          SizedBox(
            height: 218,

            child: ListView.separated(
              clipBehavior: Clip.none,

              scrollDirection: Axis.horizontal,

              itemCount: _episodeList.length,

              padding: const EdgeInsets.fromLTRB(8, 12, 24, 12),

              separatorBuilder: (_, _) => const SizedBox(width: 16),

              itemBuilder: (context, index) {
                final episode = _episodeList[index];

                if (episode is! Map) {
                  return const SizedBox.shrink();
                }

                return _EpisodeCard(
                  episode: Map<String, dynamic>.from(episode),

                  autofocus: false,

                  onPressed: () =>
                      _playEpisode(Map<String, dynamic>.from(episode)),

                  onFocus: _handlePrimaryFocusChange,
                );
              },
            ),
          ),
      ],
    );
  }

  bool get _hasCast {
    final cast = _content?['cast'] ?? _content?['casts'] ?? _content?['actors'];
    return cast is List && cast.isNotEmpty;
  }

  Widget _buildCastSection() {
    final cast = _content?['cast'] ?? _content?['casts'] ?? _content?['actors'];

    if (cast is! List || cast.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        _sectionTitle('Cast'),

        const SizedBox(height: 16),

        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.only(top: 12, bottom: 12),
            itemCount: cast.length,

            separatorBuilder: (_, _) => const SizedBox(width: 16),

            itemBuilder: (_, index) {
              final item = cast[index];

              if (item is! Map) {
                return const SizedBox.shrink();
              }

              final actor = Map<String, dynamic>.from(item);

              return _CastCard(
                name:
                    actor['actor_name']?.toString() ??
                    actor['name']?.toString() ??
                    'Unknown Actor',

                imageUrl: _imageUrl(
                  actor['image'] ??
                      actor['actor_image'] ??
                      actor['profile_image'] ??
                      actor['photo'] ??
                      actor['thumbnail'],
                ),

                autofocus: false,

                onFocus: _handlePrimaryFocusChange,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMoviesLikeThis() {
    final movies = _allMovies.where((item) {
      if (item is! Map) return false;

      return (item['content_type'] ?? item['contentType'] ?? item['type'])
              ?.toString()
              .trim()
              .toUpperCase() ==
          'MOVIE';
    }).toList();

    return _buildRelatedContentRow(title: 'More Like This', items: movies);
  }

  Widget _buildSeriesLikeThis() {
    final series = _allMovies.where((item) {
      if (item is! Map) return false;

      return (item['content_type'] ?? item['contentType'] ?? item['type'])
              ?.toString()
              .trim()
              .toUpperCase() ==
          'SERIES';
    }).toList();

    return _buildRelatedContentRow(title: 'Series Like This', items: series);
  }

  Widget _buildRelatedContentRow({
    required String title,

    required List<dynamic> items,
  }) {
    if (!_moviesLoaded || _moviesLoading || items.isEmpty) {
      return const SizedBox.shrink();
    }

    final cardWidth = AppDimensions.posterWidth(context) * 1.65;

    final cardHeight = cardWidth * 9 / 16;

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          _sectionTitle(title),

          const SizedBox(height: 18),

          SizedBox(
            height: cardHeight + 40,

            child: ListView.separated(
              clipBehavior: Clip.none,

              scrollDirection: Axis.horizontal,

              physics: const ClampingScrollPhysics(),

              itemCount: items.length,

              padding: const EdgeInsets.fromLTRB(8, 12, 24, 12),

              separatorBuilder: (_, _) => const SizedBox(width: 18),

              itemBuilder: (context, index) {
                final item = Map<String, dynamic>.from(items[index] as Map);
                final rawId = item['content_id'] ?? item['id'];
                final id = rawId?.toString() ?? '';
                final video = VideoModel(
                  id: id,
                  title: (item['name'] ?? item['title'] ?? '').toString(),
                  description: (item['description'] ?? '').toString(),
                  year: (item['release_year'] ?? '').toString(),
                  duration: (item['runtime'] ?? '').toString(),
                  category: (item['genre'] ?? '').toString(),
                  language: (item['language'] ?? '').toString(),
                  thumbnail: (item['thumbnail'] ?? '').toString(),
                  tvThumbnail: (item['tv_thumbnail'] ?? '').toString(),
                  banner:
                      (item['banner'] ??
                              item['tv_thumbnail'] ??
                              item['thumbnail'] ??
                              '')
                          .toString(),
                );

                return SizedBox(
                  width: cardWidth,
                  child: TvMovieCardLandscape(
                    key: ValueKey('${title}_$id'),
                    video: video,
                    landscape: true,
                    autofocus: false,
                    onPressed: () {
                      final contentId = int.tryParse(id);
                      if (contentId == null || contentId <= 0) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailScreen(contentId: contentId),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      mainAxisSize: MainAxisSize.min,

      children: [
        Container(
          width: 4,

          height: 27,

          decoration: BoxDecoration(
            color: const Color(0xFF36C8D5),

            borderRadius: BorderRadius.circular(3),
          ),
        ),

        const SizedBox(width: 12),

        Text(
          title,

          style: const TextStyle(
            color: Color(0xFFF4F7FA),

            fontSize: 27,

            letterSpacing: -0.4,

            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _HeroMeta extends StatelessWidget {
  const _HeroMeta({
    required this.text,

    this.icon,

    this.iconColor = const Color(0xFFD7DCE0),
  });

  final String text;

  final IconData? icon;

  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,

      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: iconColor),

          const SizedBox(width: 5),
        ],

        Text(
          text,

          style: const TextStyle(
            color: Color(0xFFE0E3E6),

            fontSize: 14,

            fontWeight: FontWeight.w600,

            letterSpacing: 0.15,
          ),
        ),
      ],
    );
  }
}

class _EpisodeCard extends StatefulWidget {
  final Map<String, dynamic> episode;
  final bool autofocus;
  final VoidCallback onPressed;
  final VoidCallback? onFocus;

  const _EpisodeCard({
    required this.episode,
    required this.autofocus,
    required this.onPressed,
    this.onFocus,
  });

  @override
  State<_EpisodeCard> createState() => _EpisodeCardState();
}

class _EpisodeCardState extends State<_EpisodeCard> {
  bool _focused = false;

  String _imageUrl(dynamic value) {
    final image = value?.toString().trim() ?? '';
    if (image.isEmpty) return '';
    if (image.startsWith('http://') || image.startsWith('https://')) {
      return image;
    }
    if (image.startsWith('/')) return 'https://assets.leichiltv.com$image';
    return 'https://assets.leichiltv.com/$image';
  }

  @override
  Widget build(BuildContext context) {
    final episode = widget.episode;
    final image = _imageUrl(episode['thumbnail']);
    final number = episode['episode_number']?.toString() ?? '0';
    final title = episode['name']?.toString().trim() ?? '';
    final runtime = episode['runtime']?.toString().trim() ?? '0';
    final synopsis = episode['synopsis']?.toString().trim() ?? '';

    return TvFocusWrapper(
      autofocus: widget.autofocus,
      style: TvFocusStyle.card,
      focusBorderRadius: 18,
      onPressed: widget.onPressed,
      onFocusChanged: (focused) {
        if (_focused != focused && mounted) {
          setState(() => _focused = focused);
        }
        if (focused) widget.onFocus?.call();
      },
      // The wrapper provides the blue glow around the entire episode card.
      // Only the text panel changes color; the poster stays unchanged.
      child: Container(
        width: 420,
        height: 170,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF050608),
          borderRadius: BorderRadius.circular(18),
        ),
        // Paint the outline above the poster and text panel so all four
        // rounded corners remain visible, including over the image.
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF263642), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 185,
              child: image.isNotEmpty
                  ? Image.network(
                      image,
                      cacheWidth: 370,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: Colors.white10,
                        child: const Icon(
                          Icons.movie_outlined,
                          color: Colors.white30,
                          size: 40,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.white10,
                      child: const Icon(
                        Icons.movie_outlined,
                        color: Colors.white30,
                        size: 40,
                      ),
                    ),
            ),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 170),
                curve: Curves.easeOutCubic,
                color: _focused
                    ? const Color.fromARGB(255, 42, 43, 43)
                    : const Color(0xFF050608),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EPISODE $number',
                      style: TextStyle(
                        color: _focused ? Colors.white70 : Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      title.isEmpty ? 'Untitled Episode' : title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          color: Colors.white54,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$runtime mins',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (synopsis.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        synopsis,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _focused ? Colors.white70 : Colors.white60,
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                    ],
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

class _CastCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final bool autofocus;
  final VoidCallback? onFocus;

  const _CastCard({
    required this.name,
    required this.imageUrl,
    required this.autofocus,
    this.onFocus,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TvFocusWrapper(
            autofocus: autofocus,
            style: TvFocusStyle.card,
            focusBorderRadius: 46,
            scaleOnFocus: false,
            onPressed: () {},
            onFocusChanged: (focused) {
              if (focused) onFocus?.call();
            },
            // Focus/glow is deliberately limited to the circular portrait.
            child: Container(
              width: 92,
              height: 92,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white10,
              ),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      cacheWidth: 184,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.person_rounded,
                        color: Colors.white38,
                        size: 40,
                      ),
                    )
                  : const Icon(
                      Icons.person_rounded,
                      color: Colors.white38,
                      size: 40,
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
