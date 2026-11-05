import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../models/video_model.dart';
import '../../services/api_service.dart';
import '../../widgets/navigation/tv_focus_style.dart';
import '../../widgets/navigation/tv_focus_wrapper.dart';
import '../details/detail_screen.dart';

class SearchScreen extends StatefulWidget {

  const SearchScreen({
    super.key,
    this.onBack,
    this.onVideoSelected,
    this.onFocusSidebar,
    this.entryFocusNode,
  });

  final VoidCallback? onBack;
  final ValueChanged<VideoModel>? onVideoSelected;
  final VoidCallback? onFocusSidebar;
  final FocusNode? entryFocusNode;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  // final FocusNode _backFocusNode = FocusNode(debugLabel: 'SearchBackButton');
  final FocusNode _searchFocusNode = FocusNode(debugLabel: 'SearchInput');
  final FocusNode _clearFocusNode = FocusNode(debugLabel: 'SearchClearButton');
  final FocusNode _firstCardFocusNode = FocusNode(
    debugLabel: 'FirstSearchResult',
  );
  bool _searchHasFocus = false;
  bool _clearHasFocus = false;
  static const List<List<String>> _keyboardRows = <List<String>>[
    <String>['A', 'B', 'C', 'D', 'E', 'F'],
    <String>['G', 'H', 'I', 'J', 'K', 'L'],
    <String>['M', 'N', 'O', 'P', 'Q', 'R'],
    <String>['S', 'T', 'U', 'V', 'W', 'X'],
    <String>['Y', 'Z', '1', '2', '3', '4'],
    <String>['5', '6', '7', '8', '9', '0'],
  ];

  late final List<FocusNode> _keyboardFocusNodes = List<FocusNode>.generate(
    39,
    (i) => i == 0
        ? (widget.entryFocusNode ?? FocusNode(debugLabel: 'SearchKey-$i'))
        : FocusNode(debugLabel: 'SearchKey-$i'),
  );
  List<VideoModel> _allVideos = <VideoModel>[];
  List<VideoModel> _filteredVideos = <VideoModel>[];
  bool _isLoading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _clearFocusNode.addListener(_handleClearFocusChanged);
    _loadContent();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _keyboardFocusNodes.isNotEmpty) {
        _keyboardFocusNodes.first.requestFocus();
      }
    });
  }

  void _handleClearFocusChanged() {
    if (!mounted || _clearHasFocus == _clearFocusNode.hasFocus) return;
    setState(() => _clearHasFocus = _clearFocusNode.hasFocus);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _clearFocusNode.removeListener(_handleClearFocusChanged);
    _clearFocusNode.dispose();
    _firstCardFocusNode.dispose();

    for (var i = 0; i < _keyboardFocusNodes.length; i++) {
      if (i != 0 || widget.entryFocusNode == null) {
        _keyboardFocusNodes[i].dispose();
      }
    }

    super.dispose();
  }

  Future<void> _loadContent() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      const pageSize = 100;
      var offset = 0;
      final rawItems = <Map<String, dynamic>>[];
      final seenIds = <String>{};
      var pageCount = 0;
      while (pageCount < 100) {
        final response = await ApiService.get(
          '/api/v1/app/contents?limit=$pageSize&offset=$offset',
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
        List<dynamic> pageItems = <dynamic>[];
        if (result is Map && result['list'] is List) {
          pageItems = List<dynamic>.from(result['list'] as List);
        } else if (result is List) {
          pageItems = List<dynamic>.from(result);
        }

        if (pageItems.isEmpty) break;

        var newItems = 0;

        for (final raw in pageItems) {
          if (raw is! Map) continue;

          final item = Map<String, dynamic>.from(raw);

          final id = (item['id'] ?? item['content_id'] ?? '').toString().trim();

          if (id.isEmpty || !seenIds.add(id)) continue;

          rawItems.add(item);

          newItems++;
        }

        // debugPrint(
        //   'SEARCH CATALOGUE: page=$pageCount received=${pageItems.length} '
        //   'new=$newItems total=${rawItems.length} offset=$offset',
        // );

        if (newItems == 0) break;

        offset += pageItems.length;

        pageCount++;
      }

      final videos = rawItems
          .map(_toVideoModel)
          .where(
            (video) =>
                video.id.trim().isNotEmpty && video.title.trim().isNotEmpty,
          )
          .toList(growable: false);

      if (!mounted) return;

      setState(() {
        _allVideos = videos;

        _applyFilter();

        _isLoading = false;

        if (_allVideos.isEmpty) {
          _error = 'No content was returned by the catalogue API.';
        }
      });

      // debugPrint('SEARCH CATALOGUE COMPLETE: ${videos.length} titles');
    } catch (error, stackTrace) {
      // debugPrint('SEARCH LOAD ERROR: $error');

      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _isLoading = false;

        _error = 'Unable to load the catalogue. Please try again.';
      });
    }
  }

  VideoModel _toVideoModel(Map<String, dynamic> item) {
    final genre = (item['genre'] ?? '').toString();

    final genres = genre
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    final contentType = (item['content_type'] ?? '')
        .toString()
        .trim()
        .toUpperCase();

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

      banner: (item['banner'] ?? item['thumbnail'] ?? '').toString(),

      genres: genres,

      isSeries: contentType == 'SERIES',
    );
  }

  void _applyFilter() {
    final query = _query.trim().toLowerCase();

    if (query.isEmpty) {
      _filteredVideos = List<VideoModel>.from(_allVideos);
      return;
    }

    _filteredVideos = _allVideos.where((video) {
      return video.title.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  void _onSearchChanged(String value) {
    if (!mounted) return;

    setState(() {
      _query = value;

      _applyFilter();
    });

    if (value.trim().isNotEmpty && _filteredVideos.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _searchFocusNode.hasFocus) {
        }
      });
    }
  }

  void _goBack() {
    if (widget.onBack != null) {
      widget.onBack!.call();

      return;
    }

    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  void _openVideo(VideoModel video) {
    if (widget.onVideoSelected != null) {
      widget.onVideoSelected!(video);

      return;
    }

    final contentId = int.tryParse(video.id);

    if (contentId == null || contentId <= 0) {
      _showMessage('Invalid content ID.');

      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DetailScreen(contentId: contentId),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _thumbnailUrl(String path) {
    final value = path.trim();

    if (value.isEmpty) return '';

    if (value.startsWith('https://') || value.startsWith('http://'))
      return value;

    return 'https://assets.leichiltv.com/${value.replaceFirst(RegExp(r'^/+'), '')}';
  }

  bool _isBackKey(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.escape ||
      key == LogicalKeyboardKey.goBack ||
      key == LogicalKeyboardKey.browserBack;

  Widget _buildSearchField() {
    return Row(
      children: [
        Expanded(
          child: Focus(
            onFocusChange: (focused) {
              if (!mounted || _searchHasFocus == focused) return;
              setState(() => _searchHasFocus = focused);
            },
            onKeyEvent: (node, event) {
              if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
                return KeyEventResult.ignored;
              }

              final key = event.logicalKey;

              if (_isBackKey(key)) {
                _goBack();
                return KeyEventResult.handled;
              }

              if (key == LogicalKeyboardKey.arrowDown) {
                _keyboardFocusNodes.first.requestFocus();
                return KeyEventResult.handled;
              }

              if (key == LogicalKeyboardKey.arrowLeft ||
                  key == LogicalKeyboardKey.arrowUp) {
                widget.onFocusSidebar?.call();
                return KeyEventResult.handled;
              }

              if (key == LogicalKeyboardKey.arrowRight) {
                _clearFocusNode.requestFocus();
                return KeyEventResult.handled;
              }

              return KeyEventResult.ignored;
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              constraints: const BoxConstraints(minWidth: 180, maxWidth: 520),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _searchHasFocus
                      ? const Color(0xFF36C8D5)
                      : AppColors.inputBorder,
                  width: _searchHasFocus ? 2 : 1,
                ),
                boxShadow: _searchHasFocus
                    ? [
                        BoxShadow(
                          color: const Color(
                            0xFF1E9AE2,
                          ).withValues(alpha: 0.25),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ]
                    : const [],
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                autofocus: false,
                // Search is controlled by the on-screen TV keyboard.
                readOnly: true,
                showCursor: true,
                enableInteractiveSelection: false,
                onTap: () => _searchFocusNode.requestFocus(),
                onChanged: _onSearchChanged,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                cursorColor: AppColors.textPrimary,
                decoration: const InputDecoration(
                  hintText: 'Search movie or series name…',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.textSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Separate Clear button, outside the search input.
        TvFocusWrapper(
          focusNode: _clearFocusNode,
          style: TvFocusStyle.button,
          scaleOnFocus: true,
          onPressed: () {
            if (_query.isEmpty) return;
            _searchController.clear();
            _onSearchChanged('');
            _searchFocusNode.requestFocus();
          },
          onKeyEvent: (node, event) {
            if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
              return KeyEventResult.ignored;
            }

            final key = event.logicalKey;

            if (_isBackKey(key)) {
              _goBack();
              return KeyEventResult.handled;
            }

            if (key == LogicalKeyboardKey.arrowLeft) {
              _searchFocusNode.requestFocus();
              return KeyEventResult.handled;
            }

            if (key == LogicalKeyboardKey.arrowDown ||
                key == LogicalKeyboardKey.arrowRight) {
              _keyboardFocusNodes.first.requestFocus();
              return KeyEventResult.handled;
            }

            if (key == LogicalKeyboardKey.arrowUp) {
              _searchFocusNode.requestFocus();
              return KeyEventResult.handled;
            }

            return KeyEventResult.ignored;
          },
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _query.isEmpty
                  ? AppColors.surface
                  : const Color(0xFF263B59),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _clearHasFocus
                    ? const Color(0xFF36C8D5)
                    : AppColors.inputBorder,
              ),
            ),
            child: Text(
              'CLEAR',
              style: TextStyle(
                color: _query.isEmpty
                    ? AppColors.textMuted
                    : AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BoxConstraints constraints) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        constraints.maxWidth < 700 ? 20 : 34,
        22,
        constraints.maxWidth < 700 ? 20 : 34,
        16,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Search',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Find movies and series',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _pressKeyboardKey(String key) {
    var value = _searchController.text;
    if (key == '⌫') {
      if (value.isNotEmpty) value = value.substring(0, value.length - 1);
    } else if (key == 'CLEAR') {
      value = '';
    } else if (key == 'SPACE') {
      value += ' ';
    } else {
      value += key;
    }
    _searchController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    _onSearchChanged(value);
  }

  KeyEventResult _handleKeyboardNavigation(int index, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    final isActionRow = index >= 36;

    if (key == LogicalKeyboardKey.arrowLeft) {
      if (isActionRow) {
        if (index > 36) {
          _keyboardFocusNodes[index - 1].requestFocus();
          return KeyEventResult.handled;
        }
        widget.onFocusSidebar?.call();
        return KeyEventResult.handled;
      }

      if (index % 6 != 0) {
        _keyboardFocusNodes[index - 1].requestFocus();
        return KeyEventResult.handled;
      }

      widget.onFocusSidebar?.call();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowRight) {
      if (isActionRow) {
        if (index < 38) {
          _keyboardFocusNodes[index + 1].requestFocus();
          return KeyEventResult.handled;
        }
      } else if (index % 6 != 5) {
        _keyboardFocusNodes[index + 1].requestFocus();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      if (isActionRow) {
        final target = switch (index) {
          36 => 31,
          37 => 33,
          _ => 35,
        };
        _keyboardFocusNodes[target].requestFocus();
        return KeyEventResult.handled;
      }

      if (index < 6) {
        _searchFocusNode.requestFocus();
        return KeyEventResult.handled;
      }

      _keyboardFocusNodes[index - 6].requestFocus();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowDown) {
      if (isActionRow) {
        if (_query.trim().isNotEmpty && _filteredVideos.isNotEmpty) {
          _firstCardFocusNode.requestFocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      }

      if (index < 30) {
        _keyboardFocusNodes[index + 6].requestFocus();
        return KeyEventResult.handled;
      }

      final column = index % 6;
      final actionIndex = column < 2 ? 36 : (column < 4 ? 37 : 38);
      _keyboardFocusNodes[actionIndex].requestFocus();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Widget _buildKeyboardKey(
    String label,
    int index, {
    bool wide = false,
    bool accent = false,
  }) {
    final nodeIndex = index.clamp(0, _keyboardFocusNodes.length - 1);
    return TvFocusWrapper(
      key: ValueKey('search-key-$label-$index'),
      focusNode: _keyboardFocusNodes[nodeIndex],
      autofocus: false,
      style: TvFocusStyle.button,
      onPressed: () => _pressKeyboardKey(label),
      onKeyEvent: (node, event) => _handleKeyboardNavigation(nodeIndex, event),
      child: Container(
        height: wide ? 36 : 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: accent ? const Color(0xFF2D4262) : const Color(0xFF172C58),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: Colors.white.withValues(alpha: 0.055)),
        ),
        child: label == 'SPACE'
            ? const Icon(Icons.space_bar_rounded, color: Colors.white, size: 18)
            : label == '⌫'
            ? const Icon(
                Icons.backspace_outlined,
                color: Colors.white,
                size: 18,
              )
            : label == 'CLEAR'
            ? const Icon(Icons.close_rounded, color: Colors.white, size: 18)
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildOnScreenKeyboard() {
    var index = 0;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x66101B30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchField(),
          const SizedBox(height: 10),
          for (final row in _keyboardRows) ...[
            Row(
              children: [
                for (final key in row) ...[
                  Expanded(child: _buildKeyboardKey(key, index++)),
                  if (key != row.last) const SizedBox(width: 4),
                ],
              ],
            ),
            const SizedBox(height: 4),
          ],
          Row(
            children: [
              Expanded(child: _buildKeyboardKey('SPACE', index++, wide: true)),
              const SizedBox(width: 5),
              Expanded(child: _buildKeyboardKey('⌫', index++)),
              const SizedBox(width: 5),
              Expanded(
                child: _buildKeyboardKey('CLEAR', index++, accent: true),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Use your remote to select a key',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieCard(VideoModel video, int index) {
    final imageUrl = _thumbnailUrl(video.thumbnail);

    return TvFocusWrapper(
      key: ValueKey(
        'search-${video.isSeries ? 'series' : 'movie'}-${video.id}',
      ),
      focusNode: index == 0 ? _firstCardFocusNode : null,
      style: TvFocusStyle.card,
      focusBorderRadius: 0,
      onPressed: () => _openVideo(video),
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: AppColors.surface,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.movie_outlined,
                  size: 42,
                  color: AppColors.textMuted,
                ),
              ),
              if (imageUrl.isNotEmpty)
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: AppColors.surface,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      size: 36,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.textSecondary,
              size: 44,
            ),

            const SizedBox(height: 14),

            Text(
              _error ?? 'Unable to load content.',

              textAlign: TextAlign.center,

              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 18),

            TvFocusWrapper(
              style: TvFocusStyle.button,

              autofocus: true,

              onPressed: _loadContent,

              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),

                decoration: BoxDecoration(
                  color: AppColors.buttonPrimary,
                  borderRadius: BorderRadius.circular(10),
                ),

                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: AppColors.buttonText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(BoxConstraints constraints) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.textPrimary),
      );
    }
    if (_error != null && _allVideos.isEmpty) return _buildErrorState();

    if (_query.trim().isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.inputBorder.withValues(alpha: 0.7),
                  ),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  size: 34,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'What are you in the mood for?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Search for a movie, series, genre or year.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final results = _filteredVideos;
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_off_rounded,
                color: AppColors.textMuted,
                size: 48,
              ),
              const SizedBox(height: 14),
              Text(
                'No results for "$_query"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Try another title or check the spelling.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, box) {
        final horizontalPadding = box.maxWidth < 600 ? 8.0 : 4.0;
        final spacing = box.maxWidth < 600 ? 10.0 : 18.0;
        final usableWidth = (box.maxWidth - horizontalPadding * 2)
            .clamp(1.0, double.infinity)
            .toDouble();
        final targetWidth = box.maxWidth < 600 ? 112.0 : 150.0;
        final columns = ((usableWidth + spacing) / (targetWidth + spacing))
            .floor()
            .clamp(1, 12)
            .toInt();
        final cardWidth = (usableWidth - spacing * (columns - 1)) / columns;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            2,
            horizontalPadding,
            24,
          ),
          child: FocusTraversalGroup(
            policy: ReadingOrderTraversalPolicy(),
            child: Wrap(
              spacing: spacing,
              runSpacing: 28,
              children: [
                for (var index = 0; index < results.length; index++)
                  SizedBox(
                    width: cardWidth,
                    child: _buildMovieCard(results[index], index),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
        SingleActivator(LogicalKeyboardKey.goBack): DismissIntent(),
        SingleActivator(LogicalKeyboardKey.browserBack): DismissIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              _goBack();
              return null;
            },
          ),
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 850;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(constraints),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          compact ? 14 : 30,
                          0,
                          compact ? 14 : 30,
                          22,
                        ),
                        child: compact
                            ? Column(
                                children: [
                                  SizedBox(
                                    height: (constraints.maxHeight * 0.44)
                                        .clamp(180.0, 350.0)
                                        .toDouble(),
                                    child: SingleChildScrollView(
                                      child: _buildOnScreenKeyboard(),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Expanded(child: _buildResults(constraints)),
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(
                                    width: constraints.maxWidth * 0.29,
                                    child: SingleChildScrollView(
                                      child: _buildOnScreenKeyboard(),
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            0,
                                            3,
                                            0,
                                            14,
                                          ),
                                          child: Row(
                                            children: [
                                              const Expanded(
                                                child: Text(
                                                  'Popular Searches',
                                                  style: TextStyle(
                                                    color:
                                                        AppColors.textPrimary,
                                                    fontSize: 19,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                _isLoading
                                                    ? 'Loading catalogue…'
                                                    : _query.trim().isEmpty
                                                    ? 'Type to search'
                                                    : '${_filteredVideos.length} results',
                                                style: const TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildResults(constraints),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
