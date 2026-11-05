import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../services/activity_service.dart';
import '../../services/content_service.dart';

class PlayerScreen extends StatefulWidget {
  final String? streamUrl;
  final String? title;
  final int contentId;
  final int? episodeId;

  const PlayerScreen({
    super.key,
    required this.streamUrl,
    required this.title,
    required this.contentId,
    this.episodeId,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _controller;

  Timer? _controlsTimer;
  Timer? _seekTimer;
  Timer? _nextEpisodeCountdownTimer;
  List<Map<String, dynamic>> _episodes = [];
  bool _isSeries = false;
  bool _changingEpisode = false;
  bool _isReplacingForNextEpisode = false;
  bool _nextEpisodeTriggered = false;
  bool _showNextEpisodeCountdown = false;
  bool _nextOverlayFocused = false;
  int _nextEpisodeCountdown = 5;
  Timer? _seekCommitTimer;

Duration? _pendingSeekPosition;
Duration? _seekPreviewPosition;

  static const Duration _nextEpisodeThreshold = Duration(seconds: 15);

  bool _isLoading = true;
  bool _hasError = false;
  bool _showControls = false;
  bool _muted = false;
  bool _activityRecorded = false;
  bool _isSeeking = false;

  String? _errorMessage;

  int _selectedControl = 2;

  static const int _controlCount = 7;

  double _seekIndicator = 0;
  bool _showSeekIndicator = false;

  @override
  void initState() {
    super.initState();

    unawaited(_setPlayerSystemUi());
    unawaited(_loadEpisodes());
    _initializePlayer();
  }

  Future<void> _setPlayerSystemUi() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _initializePlayer() async {
    final url = widget.streamUrl?.trim();

    if (url == null || url.isEmpty) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Video URL is not available.';
      });

      return;
    }

    try {
      await _setPlayerSystemUi();

      final controller = VideoPlayerController.networkUrl(Uri.parse(url));

      _controller = controller;

      controller.addListener(_videoListener);

      await controller.initialize();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasError = false;
      });

      await controller.play();

      // Start the auto-hide timer only after playback has actually started.
      // This also runs for replacement PlayerScreen instances when autoplay
      // advances to the next episode.
      if (mounted) {
        _showControlsTemporarily();
      }

      await _recordWatchActivity();
    } catch (e) {
      debugPrint('PLAYER INITIALIZATION ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Unable to play this video.';
      });
    }
  }

  void _videoListener() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final value = controller.value;
    if (value.hasError) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
        _errorMessage = value.errorDescription ?? 'Video playback failed.';
      });
      return;
    }

    if (!value.isPlaying) {
      _controlsTimer?.cancel();
      if (mounted && !_showControls) {
        setState(() => _showControls = true);
      }
    }

    if (_hasNextEpisode && value.duration > Duration.zero) {
      final remaining = value.duration - value.position;
      if (value.position >= value.duration || remaining <= Duration.zero) {
        _cancelNextEpisodeCountdown();
        if (!_nextEpisodeTriggered && !_changingEpisode) {
          _nextEpisodeTriggered = true;
          unawaited(_playNextEpisode());
        }
      } else if (remaining <= _nextEpisodeThreshold) {
        if (!_showNextEpisodeCountdown && !_nextEpisodeTriggered) {
          _startNextEpisodeCountdown();
        }
      } else if (_showNextEpisodeCountdown) {
        _cancelNextEpisodeCountdown(resetTriggered: true);
      }
    }

    if (value.position >= value.duration && value.duration > Duration.zero) {
      _controlsTimer?.cancel();
      if (!mounted) return;
      setState(() => _showControls = true);
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _episodeUrl(Map<String, dynamic> episode) =>
      (episode['video'] ??
              episode['video_url'] ??
              episode['stream_url'] ??
              episode['url'] ??
              '')
          .toString()
          .trim();

  List<Map<String, dynamic>> get _orderedEpisodes {
    final list = _episodes.map((e) => Map<String, dynamic>.from(e)).toList();
    list.sort((a, b) {
      final season = _toInt(a['season']).compareTo(_toInt(b['season']));
      if (season != 0) return season;
      final episode = _toInt(
        a['episode_number'] ?? a['episode'],
      ).compareTo(_toInt(b['episode_number'] ?? b['episode']));
      if (episode != 0) return episode;
      return _toInt(a['id']).compareTo(_toInt(b['id']));
    });
    return list;
  }

  int get _currentEpisodeIndex {
    final list = _orderedEpisodes;
    if (widget.episodeId != null) {
      final index = list.indexWhere((e) => _toInt(e['id']) == widget.episodeId);
      if (index >= 0) return index;
    }
    final url = widget.streamUrl?.trim() ?? '';
    if (url.isNotEmpty) {
      final index = list.indexWhere((e) => _episodeUrl(e) == url);
      if (index >= 0) return index;
    }
    return -1;
  }

  bool get _hasNextEpisode {
    final index = _currentEpisodeIndex;
    return _isSeries && index >= 0 && index + 1 < _orderedEpisodes.length;
  }

  Map<String, dynamic>? get _nextEpisode {
    final index = _currentEpisodeIndex;
    final list = _orderedEpisodes;
    return index >= 0 && index + 1 < list.length ? list[index + 1] : null;
  }

  Future<void> _loadEpisodes() async {
    try {
      final response = await ContentService.getContent(widget.contentId);
      if (response.statusCode != 200 ||
          response.data is! Map ||
          response.data['success'] != true) {
        return;
      }
      final result = response.data['result'];
      if (result is! Map) return;
      final type =
          (result['content_type'] ??
                  result['content-type'] ??
                  result['type'] ??
                  '')
              .toString()
              .toUpperCase();
      final raw = result['episodes'];
      final episodes = raw is List
          ? raw
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() {
        _isSeries = type == 'SERIES' || episodes.isNotEmpty;
        _episodes = episodes;
      });
    } catch (e) {
      debugPrint('PLAYER EPISODES LOAD ERROR: $e');
    }
  }

  void _startNextEpisodeCountdown() {
    if (_changingEpisode ||
        _nextEpisodeTriggered ||
        !_hasNextEpisode ||
        _nextEpisodeCountdownTimer?.isActive == true) {
      return;
    }
    _nextEpisodeCountdown = 5;
    if (mounted) setState(() => _showNextEpisodeCountdown = true);
    _nextEpisodeCountdownTimer = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) {
      if (!mounted ||
          _changingEpisode ||
          _nextEpisodeTriggered ||
          !_hasNextEpisode) {
        timer.cancel();
        return;
      }
      if (_nextEpisodeCountdown <= 1) {
        timer.cancel();
        _nextEpisodeCountdown = 0;
        _nextEpisodeTriggered = true;
        unawaited(_playNextEpisode());
      } else {
        _nextEpisodeCountdown--;
      }
      if (mounted) setState(() {});
    });
  }

  void _cancelNextEpisodeCountdown({bool resetTriggered = false}) {
    _nextEpisodeCountdownTimer?.cancel();
    _nextEpisodeCountdownTimer = null;
    if (mounted && _showNextEpisodeCountdown) {
      setState(() => _showNextEpisodeCountdown = false);
    } else {
      _showNextEpisodeCountdown = false;
    }
    _nextEpisodeCountdown = 5;
    if (resetTriggered) _nextEpisodeTriggered = false;
  }

  Future<void> _playNextEpisode() async {
    if (_changingEpisode || !_hasNextEpisode) return;
    final next = _nextEpisode;
    if (next == null) return;
    final url = _episodeUrl(next);
    if (url.isEmpty) {
      debugPrint('NEXT EPISODE ERROR: episode URL is missing');
      _cancelNextEpisodeCountdown(resetTriggered: true);
      return;
    }
    _nextEpisodeCountdownTimer?.cancel();
    if (mounted) {
      setState(() {
        _changingEpisode = true;
        _showNextEpisodeCountdown = false;
      });
    }
    _isReplacingForNextEpisode = true;
    final episodeId = _toInt(next['id']);
    final name = (next['name'] ?? next['title'] ?? '').toString().trim();
    final season = _toInt(next['season']);
    final number = _toInt(next['episode_number'] ?? next['episode']);
    final nextTitle = name.isNotEmpty
        ? name
        : '${widget.title ?? 'Episode'} · S$season E$number';
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          streamUrl: url,
          title: nextTitle,
          contentId: widget.contentId,
          episodeId: episodeId == 0 ? null : episodeId,
        ),
      ),
    );
  }

  Future<void> _recordWatchActivity() async {
    if (_activityRecorded) {
      return;
    }

    _activityRecorded = true;

    final success = await ActivityService.recordWatch(
      contentId: widget.contentId,
      episodeId: widget.episodeId,
    );

    debugPrint('Watch activity recorded: $success');
  }

  Future<void> _togglePlayPause() async {
    final controller = _controller;

    if (controller == null) {
      return;
    }

    if (controller.value.isPlaying) {
      await controller.pause();

      _controlsTimer?.cancel();

      if (!mounted) return;

      setState(() {
        _showControls = true;
      });
    } else {
      await controller.play();

      _showControlsTemporarily();
    }
  }

  Future<void> _seekBy(Duration amount) async {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    final current = controller.value.position;
    final duration = controller.value.duration;

    var target = current + amount;

    if (target < Duration.zero) {
      target = Duration.zero;
    }

    if (target > duration) {
      target = duration;
    }

    await controller.seekTo(target);

    _showSeekFeedback(amount.inSeconds.toDouble());

    _showControlsTemporarily();
  }

  void _showSeekFeedback(double seconds) {
    _seekTimer?.cancel();

    if (!mounted) return;

    setState(() {
      _seekIndicator = seconds;
      _showSeekIndicator = true;
    });

    _seekTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;

      setState(() {
        _showSeekIndicator = false;
      });
    });
  }

  Future<void> _toggleMute() async {
    final controller = _controller;

    if (controller == null) {
      return;
    }

    final newMuted = !_muted;

    await controller.setVolume(newMuted ? 0 : 1);

    if (!mounted) return;

    setState(() {
      _muted = newMuted;
    });

    _showControlsTemporarily();
  }

  void _showControlsTemporarily() {
    if (!mounted) return;

    _controlsTimer?.cancel();

    setState(() {
      _showControls = true;
    });

    if (_selectedControl == 6 || _isSeeking) {
      return;
    }

    final controller = _controller;

    if (controller == null || !controller.value.isPlaying) {
      return;
    }

    _controlsTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;

      if (_controller?.value.isPlaying == true &&
          _selectedControl != 6 &&
          !_isSeeking) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _onDpadActivity() {
    if (!mounted) return;

    _showControlsTemporarily();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) {
      return KeyEventResult.handled;
    }

    final key = event.logicalKey;

    // While the autoplay card is visible, route D-pad input to it first.
    // This prevents the underlying playback controls from consuming Select.
    if (_showNextEpisodeCountdown && _hasNextEpisode) {
      if (key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.select ||
          key == LogicalKeyboardKey.gameButtonA) {
        unawaited(_playNextEpisode());
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowLeft ||
          key == LogicalKeyboardKey.arrowRight ||
          key == LogicalKeyboardKey.arrowUp ||
          key == LogicalKeyboardKey.arrowDown) {
        if (!_nextOverlayFocused && mounted) {
          setState(() => _nextOverlayFocused = true);
        }
        _controlsTimer?.cancel();
        return KeyEventResult.handled;
      }
    }

    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.browserBack ||
        key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.goBack) {
      _exitPlayer();

      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.gameButtonA) {
      _onDpadActivity();
    }

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.gameButtonA) {
      if (!_showControls) {
        _showControlsTemporarily();
      } else {
        _activateSelectedControl();
      }

      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowLeft) {
      if (!_showControls) {
        _showControlsTemporarily();

        return KeyEventResult.handled;
      }

      if (_selectedControl == 6) {
        _seekSeekerBy(const Duration(seconds: -10));

        return KeyEventResult.handled;
      }

      _moveControlLeft();

      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowRight) {
      if (!_showControls) {
        _showControlsTemporarily();

        return KeyEventResult.handled;
      }

      if (_selectedControl == 6) {
        _seekSeekerBy(const Duration(seconds: 10));

        return KeyEventResult.handled;
      }

      _moveControlRight();

      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      if (!_showControls) {
        _showControlsTemporarily();

        return KeyEventResult.handled;
      }

      _moveControlUp();

      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowDown) {
      if (!_showControls) {
        _showControlsTemporarily();

        return KeyEventResult.handled;
      }

      _moveControlDown();

      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _moveControlLeft() {
    if (_selectedControl == 6) {
      _seekSeekerBy(const Duration(seconds: -10));

      return;
    }

    setState(() {
      _selectedControl = (_selectedControl - 1 + _controlCount) % _controlCount;
    });

    _showControlsTemporarily();
  }

  void _moveControlRight() {
    if (_selectedControl == 6) {
      _seekSeekerBy(const Duration(seconds: 10));

      return;
    }

    setState(() {
      _selectedControl = (_selectedControl + 1) % _controlCount;
    });

    _showControlsTemporarily();
  }

  void _moveControlUp() {
    // Gradual vertical focus order:
    // bottom controls -> progress -> center Play -> top-left Back.
    setState(() {
      if (_selectedControl == 4 || _selectedControl == 5) {
        _selectedControl = 6;
        _isSeeking = true;
      } else if (_selectedControl == 6) {
        _selectedControl = 2;
        _isSeeking = false;
      } else if (_selectedControl == 1 ||
          _selectedControl == 2 ||
          _selectedControl == 3) {
        _selectedControl = 0;
        _isSeeking = false;
      } else {
        // Already on Back: keep focus there.
        _selectedControl = 0;
        _isSeeking = false;
      }
      _showControls = true;
    });

    if (_selectedControl == 6) {
      _controlsTimer?.cancel();
    } else {
      _showControlsTemporarily();
    }
  }

  void _moveControlDown() {
    // Gradual vertical focus order:
    // Back -> center Play -> progress -> bottom controls.
    setState(() {
      if (_selectedControl == 0) {
        _selectedControl = 2;
        _isSeeking = false;
      } else if (_selectedControl == 1 ||
          _selectedControl == 2 ||
          _selectedControl == 3) {
        _selectedControl = 6;
        _isSeeking = true;
      } else if (_selectedControl == 6) {
        _selectedControl = _hasNextEpisode ? 5 : 4;
        _isSeeking = false;
      } else {
        // Already on the bottom row: don't wrap to another control row.
        _isSeeking = false;
      }
      _showControls = true;
    });

    if (_selectedControl == 6) {
      _controlsTimer?.cancel();
    } else {
      _showControlsTemporarily();
    }
  }

  void _activateSelectedControl() {
    switch (_selectedControl) {
      case 0:
        _exitPlayer();
        break;

      case 1:
        _seekBy(const Duration(seconds: -10));
        break;

      case 2:
        _togglePlayPause();
        break;

      case 3:
        _seekBy(const Duration(seconds: 10));
        break;

      case 4:
        _toggleMute();
        break;

      case 5:
        if (_hasNextEpisode) unawaited(_playNextEpisode());
        break;

      case 6:
        _beginSeek();
        break;
    }
  }

  void _beginSeek() {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    _controlsTimer?.cancel();

    setState(() {
      _selectedControl = 6;
      _isSeeking = true;
      _showControls = true;
    });
  }

  // Future<void> _seekSeekerBy(Duration amount) async {
  //   final controller = _controller;

  //   if (controller == null || !controller.value.isInitialized) {
  //     return;
  //   }

  //   final duration = controller.value.duration;

  //   if (duration <= Duration.zero) {
  //     return;
  //   }

  //   final current = controller.value.position;

  //   var target = current + amount;

  //   if (target < Duration.zero) {
  //     target = Duration.zero;
  //   }

  //   if (target > duration) {
  //     target = duration;
  //   }

  //   if (!mounted) return;

  //   _controlsTimer?.cancel();

  //   setState(() {
  //     _selectedControl = 6;
  //     _isSeeking = true;
  //     _showControls = true;
  //   });

  //   try {
  //     await controller.seekTo(target);
  //   } catch (e) {
  //     debugPrint('SEEK ERROR: $e');
  //   }

  //   if (!mounted) return;

  //   setState(() {
  
  //     _showControls = true;
  //     _isSeeking = true;
  //   });
  // }

  void _seekSeekerBy(Duration amount) {
  final controller = _controller;

  if (controller == null || !controller.value.isInitialized) {
    return;
  }

  final duration = controller.value.duration;

  if (duration <= Duration.zero) return;

  // Use the preview position so repeated remote presses
  // build on the latest requested position.
  final current =
      _pendingSeekPosition ??
      _seekPreviewPosition ??
      controller.value.position;

  var target = current + amount;

  if (target < Duration.zero) {
    target = Duration.zero;
  }

  if (target > duration) {
    target = duration;
  }

  _controlsTimer?.cancel();
  _seekCommitTimer?.cancel();

  if (!mounted) return;

  setState(() {
    _selectedControl = 6;
    _isSeeking = true;
    _showControls = true;

    _pendingSeekPosition = target;
    _seekPreviewPosition = target;
  });

  // Wait briefly after the last remote press before
  // sending the actual seek request.
  _seekCommitTimer = Timer(
    const Duration(milliseconds: 180),
    _commitPendingSeek,
  );
}


Future<void> _commitPendingSeek() async {
  final controller = _controller;
  final target = _pendingSeekPosition;

  if (controller == null ||
      target == null ||
      !controller.value.isInitialized) {
    return;
  }

  _pendingSeekPosition = null;

  try {
    await controller.seekTo(target);
  } catch (e) {
    debugPrint('SEEK ERROR: $e');
  }

  if (!mounted) return;

  setState(() {
    _seekPreviewPosition = null;
  });
}

  // Future<void> _seekToPosition(Duration position) async {
  //   final controller = _controller;

  //   if (controller == null || !controller.value.isInitialized) {
  //     return;
  //   }

  //   final duration = controller.value.duration;

  //   var target = position;

  //   if (target < Duration.zero) {
  //     target = Duration.zero;
  //   }

  //   if (target > duration) {
  //     target = duration;
  //   }

  //   try {
  //     await controller.seekTo(target);
  //   } catch (e) {
  //     debugPrint('SEEK ERROR: $e');
  //   }

  //   if (!mounted) return;

  //   setState(() {
  //     _isSeeking = false;
  //     _selectedControl = 2;
  //     _showControls = true;
  //   });

  //   _showControlsTemporarily();
  // }


  Future<void> _seekToPosition(Duration position) async {
  final controller = _controller;

  if (controller == null || !controller.value.isInitialized) {
    return;
  }

  final duration = controller.value.duration;

  var target = position;

  if (target < Duration.zero) {
    target = Duration.zero;
  }

  if (target > duration) {
    target = duration;
  }

  _seekCommitTimer?.cancel();

  _pendingSeekPosition = target;

  if (!mounted) return;

  setState(() {
    _seekPreviewPosition = target;
    _isSeeking = false;
    _selectedControl = 2;
    _showControls = true;
  });

  await _commitPendingSeek();

  if (!mounted) return;

  _showControlsTemporarily();
}

  // void _exitPlayer() {
  //   Navigator.of(context).pop();
  // }

  void _exitPlayer() {
  final navigator = Navigator.of(
    context,
    rootNavigator: true,
  );

  if (navigator.canPop()) {
    navigator.pop();
  }
}

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;

    final minutes = duration.inMinutes.remainder(60);

    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '$minutes:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: _handleKey,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildVideo(),

            if (_isLoading) _buildLoading(),

            if (_hasError) _buildError(),

            if (_showSeekIndicator) _buildSeekIndicator(),

            if (!_isLoading && !_hasError && _showControls) _buildControls(),

            if (_showNextEpisodeCountdown && _hasNextEpisode)
              _buildNextEpisodeCountdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildNextEpisodeCountdown() {
    final next = _nextEpisode;
    final name = (next?['name'] ?? next?['title'] ?? '').toString().trim();
    return Positioned(
      right: 36,
      bottom: 120,
      child: Material(
        color: const Color(0xE6000000),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => unawaited(_playNextEpisode()),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _nextOverlayFocused
                    ? const Color(0xFF36C8D5)
                    : Colors.transparent,
                width: 3,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 38,
                  height: 38,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: _nextEpisodeCountdown / 5,
                        strokeWidth: 3,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF36C8D5),
                        ),
                      ),
                      Text(
                        '$_nextEpisodeCountdown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'PLAY NEXT',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      name.isNotEmpty ? name : 'Next episode',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Select to play now',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideo() {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return const ColoredBox(color: Colors.black);
    }

    final size = controller.value.size;

    if (size.width <= 0 || size.height <= 0) {
      return const ColoredBox(color: Colors.black);
    }

    final aspectRatio = size.width / size.height;

    return Center(
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: VideoPlayer(controller),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildError() {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 60),
              const SizedBox(height: 20),
              Text(
                _errorMessage ?? 'Unable to play video.',
                style: const TextStyle(color: Colors.white, fontSize: 22),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                autofocus: true,
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _isLoading = true;
                  });

                  _initializePlayer();
                },
                child: const Text('Retry'),
              ),
              const SizedBox(height: 10),
              TextButton(onPressed: _exitPlayer, child: const Text('Back')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeekIndicator() {
    final forward = _seekIndicator > 0;

    return IgnorePointer(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                forward ? Icons.forward_10 : Icons.replay_10,
                color: Colors.white,
                size: 42,
              ),
              const SizedBox(width: 10),
              Text(
                '${forward ? '+' : ''}'
                '${_seekIndicator.toInt()}s',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) => _buildControlsForValue(value),
    );
  }

  Widget _buildControlsForValue(VideoPlayerValue value) {
    // final position = value.position;
    // final duration = value.duration;

    final position = _seekPreviewPosition ?? value.position;
final duration = value.duration;

    double progress = 0;

    if (duration.inMilliseconds > 0) {
      progress = position.inMilliseconds / duration.inMilliseconds;

      progress = progress.clamp(0.0, 1.0);
    }

    return Stack(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: IgnorePointer(
            child: Container(
              height: 150,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
            ),
          ),
        ),

        Align(
          alignment: Alignment.bottomCenter,
          child: IgnorePointer(
            child: Container(
              height: 230,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
            ),
          ),
        ),

        Positioned(
          top: 24,
          left: 28,
          child: _buildControlButton(
            index: 0,
            icon: Icons.arrow_back,
            size: 36,
          ),
        ),

        Positioned(
          top: 35,
          left: 100,
          right: 40,
          child: IgnorePointer(
            child: Row(
              children: [
                const Icon(Icons.movie, color: Colors.white, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildControlButton(index: 1, icon: Icons.replay_10, size: 55),
              const SizedBox(width: 35),
              _buildControlButton(
                index: 2,
                icon: value.isPlaying ? Icons.pause : Icons.play_arrow,
                size: 72,
              ),
              const SizedBox(width: 35),
              _buildControlButton(index: 3, icon: Icons.forward_10, size: 55),
            ],
          ),
        ),

        Positioned(
          left: 40,
          right: 40,
          bottom: 25,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    _formatDuration(position),
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSeekBar(
                      position: position,
                      duration: duration,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _formatDuration(duration),
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  const Spacer(),
                  _buildControlButton(
                    index: 4,
                    icon: _muted ? Icons.volume_off : Icons.volume_up,
                    size: 42,
                  ),
                  const SizedBox(width: 18),
                  if (_hasNextEpisode)
                    _buildControlButton(
                      index: 5,
                      icon: Icons.skip_next_rounded,
                      size: 42,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSeekBar({
    required Duration position,
    required Duration duration,
  }) {
    final totalMs = duration.inMilliseconds;

    final currentMs = position.inMilliseconds.clamp(0, totalMs);

    final progress = totalMs <= 0 ? 0.0 : currentMs / totalMs;

    final selected = _selectedControl == 6;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final thumbX = width * progress;

        return SizedBox(
          height: 55,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 21,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) {
                    final tapX = details.localPosition.dx;

                    final ratio = (tapX / width).clamp(0.0, 1.0);

                    final target = Duration(
                      milliseconds: (duration.inMilliseconds * ratio).round(),
                    );

                    _seekToPosition(target);
                  },
                  child: Container(
                    height: selected ? 7 : 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          height: selected ? 7 : 5,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                left: (thumbX - 8).clamp(0.0, width - 16),
                top: selected ? 15 : 17,
                child: IgnorePointer(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: selected ? 18 : 12,
                    height: selected ? 18 : 12,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlButton({
    required int index,
    required IconData icon,
    required double size,
  }) {
    final selected = _selectedControl == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _selectedControl = index;
        });

        _showControlsTemporarily();

        _activateSelectedControl();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: size + 24,
            height: size + 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected
                  ? Colors.white.withValues(alpha: 0.20)
                  : Colors.transparent,
              border: Border.all(
                color: selected ? Colors.white : Colors.transparent,
                width: 2,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: size),
          ),
          if (index == 5) ...[
            const SizedBox(width: 6),
            const Text(
              'Next',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _seekTimer?.cancel();
    _nextEpisodeCountdownTimer?.cancel();
    _seekCommitTimer?.cancel();

    _controller?.removeListener(_videoListener);

    _controller?.dispose();

    if (!_isReplacingForNextEpisode) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    super.dispose();
  }
}
