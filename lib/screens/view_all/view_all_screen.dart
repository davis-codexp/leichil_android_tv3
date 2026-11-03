import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/video_model.dart';
import '../../services/api_service.dart';
import '../../widgets/cards/tv_movie_card.dart';
import '../details/detail_screen.dart';

class ViewAllScreen extends StatefulWidget {
  const ViewAllScreen({
    super.key,
    required this.title,
    required this.contentType,
    this.onFocusSidebar,
    this.entryFocusNode,
  });

  final String title;
  final String contentType;
  final VoidCallback? onFocusSidebar;
  final FocusNode? entryFocusNode;

  @override
  State<ViewAllScreen> createState() => _ViewAllScreenState();
}

class _ViewAllScreenState extends State<ViewAllScreen> {
  static const Color _background = Color.fromARGB(255, 0, 0, 0);
  static const Color _accent = Color(0xFF36C8D5);

  static const int _pageSize = 10;

  static const double _horizontalPadding = 32;
  static const double _columnSpacing = 14;
  static const double _rowSpacing = 20;

  final ScrollController _scrollController = ScrollController();
  // final FocusNode _backFocusNode = FocusNode(debugLabel: 'CatalogueBackButton');
  final FocusNode _refreshFocusNode = FocusNode(
    debugLabel: 'CatalogueRefreshButton',
  );
  final Map<int, FocusNode> _focusNodes = {};

  List<VideoModel> _videos = [];

  bool _isLoading = true;
  bool _loadingCatalogue = false;
  String? _error;

  int? _pendingFocusIndex;
  int _navigationGeneration = 0;

  @override
  void initState() {
    super.initState();
    _loadCatalogue();
  }

  Future<void> _loadCatalogue() async {
    if (_loadingCatalogue) return;

    _loadingCatalogue = true;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final List<dynamic> allItems = [];
      final Set<String> seenIds = {};
      int offset = 0;

      while (true) {
        final response = await ApiService.get(
          '/api/v1/app/contents?limit=$_pageSize&offset=$offset',
        );

        if (!mounted) return;

        if (response.statusCode != 200 ||
            response.data is! Map ||
            response.data['success'] != true) {
          throw Exception(
            'Catalogue request failed at offset $offset '
            '(HTTP ${response.statusCode})',
          );
        }

        final dynamic result = response.data['result'];
        List<dynamic> pageItems = [];

        if (result is Map && result['list'] is List) {
          pageItems = List<dynamic>.from(result['list']);
        } else if (result is List) {
          pageItems = List<dynamic>.from(result);
        }

        if (pageItems.isEmpty) break;

        for (final item in pageItems) {
          if (item is! Map) continue;

          final id = (item['id'] ?? item['content_id'] ?? '').toString();

          if (id.isNotEmpty && seenIds.add(id)) {
            allItems.add(item);
          }
        }

        offset += pageItems.length;

        if (pageItems.length < _pageSize) break;
      }

      final requestedType = widget.contentType.trim().toUpperCase();

      final videos = allItems
          .where((item) {
            if (item is! Map) return false;

            final type =
                item['content_type']?.toString().trim().toUpperCase() ?? '';

            return type == requestedType;
          })
          .map((item) => _toVideoModel(Map<String, dynamic>.from(item as Map)))
          .toList();

      if (!mounted) return;

      setState(() {
        _videos = videos;
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        if (_videos.isNotEmpty) {
          _focusNodeFor(0).requestFocus();
        } else {
          widget.onFocusSidebar?.call();
        }
      });
    } catch (error, stackTrace) {
      debugPrint('CATALOGUE ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = 'Unable to load ${widget.title.toLowerCase()}.';
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        // if (mounted) _backFocusNode.requestFocus();
        if (mounted) widget.onFocusSidebar?.call();
      });
    } finally {
      _loadingCatalogue = false;
    }
  }

  VideoModel _toVideoModel(Map<String, dynamic> item) {
    final genre = (item['genre'] ?? '').toString();

    final genres = genre
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    return VideoModel(
      id: (item['id'] ?? item['content_id'] ?? '').toString(),
      title: (item['name'] ?? item['title'] ?? 'Untitled').toString(),
      description: (item['synopsis'] ?? item['description'] ?? '').toString(),
      year: (item['release_year'] ?? item['year'] ?? '').toString(),
      duration: (item['runtime'] ?? item['duration'] ?? '').toString(),
      category: genre,
      language: (item['language'] ?? 'Manipuri').toString(),
      rating: item['rating'] is num
          ? (item['rating'] as num).toDouble()
          : double.tryParse(item['rating']?.toString() ?? '') ?? 0.0,

      thumbnail: (item['thumbnail'] ?? '').toString(),
      tvThumbnail: (item['tv_thumbnail'] ?? '').toString(),
      banner:
          (item['banner'] ?? item['tv_thumbnail'] ?? item['thumbnail'] ?? '')
              .toString(),
      titleImage: (item['title_image'] ?? '').toString(),

      genres: genres,
      isSeries:
          item['content_type']?.toString().trim().toUpperCase() == 'SERIES',
    );
  }

  FocusNode _focusNodeFor(int index) {
    if (index == 0 && widget.entryFocusNode != null) {
      return widget.entryFocusNode!;
    }

    return _focusNodes.putIfAbsent(
      index,
      () => FocusNode(debugLabel: 'CatalogueItem$index'),
    );
  }

  int _columnsFor(double width) {
    if (width >= 1600) return 6;
    if (width >= 1200) return 5;
    if (width >= 800) return 4;
    return 3;
  }

  KeyEventResult _handleRefreshKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowLeft) {
      widget.onFocusSidebar?.call();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowDown) {
      if (_videos.isNotEmpty) {
        _focusNodeFor(_pendingFocusIndex ?? 0).requestFocus();
      }

      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  KeyEventResult _handleCardKeyEvent(
    int index,
    FocusNode node,
    KeyEvent event,
    int columns,
    double viewportWidth,
  ) {
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

    if (_videos.isEmpty) return KeyEventResult.handled;

    final current = _pendingFocusIndex ?? index;
    var target = current;

    if (key == LogicalKeyboardKey.arrowLeft) {
      final column = current % columns;

      if (column == 0) {
        widget.onFocusSidebar?.call();
        return KeyEventResult.handled;
      }

      target = current - 1;
    } else if (key == LogicalKeyboardKey.arrowRight) {
      if (current < _videos.length - 1) {
        target = current + 1;
      } else {
        // At the final card, allow navigation to Refresh.
        _refreshFocusNode.requestFocus();
        return KeyEventResult.handled;
      }
    } else if (key == LogicalKeyboardKey.arrowUp) {
      if (current - columns >= 0) {
        target = current - columns;
      } else {
        widget.onFocusSidebar?.call();
        return KeyEventResult.handled;
      }
    } else if (key == LogicalKeyboardKey.arrowDown) {
      if (current + columns < _videos.length) {
        target = current + columns;
      }
    }

    if (target == current) return KeyEventResult.handled;

    final isVerticalMove =
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown;

    _moveToIndex(
      target,
      columns: columns,
      viewportWidth: viewportWidth,
      shouldCheckScroll: isVerticalMove,
    );

    return KeyEventResult.handled;
  }

  void _moveToIndex(
    int target, {
    required int columns,
    required double viewportWidth,
    required bool shouldCheckScroll,
  }) {
    if (target < 0 || target >= _videos.length) return;

    _pendingFocusIndex = target;
    final generation = ++_navigationGeneration;
    final destination = _focusNodeFor(target);

    destination.requestFocus();

    if (!shouldCheckScroll || !_scrollController.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _navigationGeneration) return;
      if (!_scrollController.hasClients || destination.context == null) return;

      final cardObject = destination.context!.findRenderObject();
      final viewportObject = _scrollController.position.context.storageContext
          .findRenderObject();

      if (cardObject is! RenderBox ||
          !cardObject.hasSize ||
          viewportObject is! RenderBox ||
          !viewportObject.hasSize) {
        return;
      }

      final cardTop = cardObject.localToGlobal(Offset.zero).dy;
      final cardBottom = cardTop + cardObject.size.height;
      final viewportTop = viewportObject.localToGlobal(Offset.zero).dy;
      final viewportBottom = viewportTop + viewportObject.size.height;
      const margin = 12.0;

      double delta = 0;
      if (cardTop < viewportTop + margin) {
        delta = cardTop - viewportTop - margin;
      } else if (cardBottom > viewportBottom - margin) {
        delta = cardBottom - viewportBottom + margin;
      }

      if (delta.abs() < 1) return;

      final position = _scrollController.position;
      final targetOffset = (position.pixels + delta)
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble();

      if ((targetOffset - position.pixels).abs() < 1) return;

      // Keep this short so repeated D-pad presses do not queue up long motion.
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 110),
        curve: Curves.linear,
      );
    });
  }

  void _openDetails(VideoModel video) {
    final id = int.tryParse(video.id);

    if (id == null || id <= 0) {
      debugPrint('Invalid catalogue content ID: ${video.id}');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailScreen(contentId: id)),
    );
  }

  @override
  void dispose() {
    _navigationGeneration++;
    _scrollController.dispose();
    _refreshFocusNode.dispose();

    for (final node in _focusNodes.values) {
      node.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = _columnsFor(width);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 16, 32, 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Focus(
                        focusNode: _refreshFocusNode,
                        onKeyEvent: _handleRefreshKeyEvent,
                        child: Builder(
                          builder: (context) {
                            final hasFocus = Focus.of(context).hasFocus;

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: hasFocus
                                      ? _accent
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                color: hasFocus
                                    ? _accent.withValues(alpha: 0.12)
                                    : Colors.transparent,
                              ),
                              child: IconButton(
                                tooltip: 'Refresh',
                                onPressed: _loadCatalogue,
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  color: Colors.white70,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildBody(columns: columns, viewportWidth: width),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody({required int columns, required double viewportWidth}) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white54, size: 42),
            const SizedBox(height: 14),
            Text(
              _error!,
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loadCatalogue,
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    if (_videos.isEmpty) {
      return Center(
        child: Text(
          'No ${widget.title.toLowerCase()} found.',
          style: const TextStyle(color: Colors.white70, fontSize: 20),
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        _horizontalPadding,
        16,
        _horizontalPadding,
        48,
      ),
      itemCount: _videos.length,
      // gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      //   crossAxisCount: columns,
      //   mainAxisSpacing: _rowSpacing,
      //   crossAxisSpacing: _columnSpacing,
      //   childAspectRatio: 16 / 9,
      // ),

      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: _rowSpacing,
        crossAxisSpacing: _columnSpacing,
        childAspectRatio: 2 / 3,
      ),
      itemBuilder: (context, index) {
        final video = _videos[index];
        return TvMovieCard(
          key: ValueKey(video.id),
          video: video,
          landscape: false,
          focusNode: _focusNodeFor(index),
          autofocus: false,
          onKeyEvent: (node, event) =>
              _handleCardKeyEvent(index, node, event, columns, viewportWidth),
          onPressed: () => _openDetails(video),
        );
      },
    );
  }
}
