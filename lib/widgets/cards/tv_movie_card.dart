import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../models/video_model.dart';
import '../navigation/tv_focus_style.dart';
import '../navigation/tv_focus_wrapper.dart';

class TvMovieCard extends StatefulWidget {
  const TvMovieCard({
    super.key,
    required this.video,
    this.onPressed,
    this.autofocus = false,
    this.focusNode,
    this.onKeyEvent,
    this.landscape = false,
  });

  final VideoModel video;
  final VoidCallback? onPressed;
  final bool autofocus;
  final FocusNode? focusNode;
  final FocusOnKeyEventCallback? onKeyEvent;

  // Retained for compatibility with existing calls.
  // Cards always display in portrait orientation.
  final bool landscape;

  @override
  State<TvMovieCard> createState() => _TvMovieCardState();
}

class _TvMovieCardState extends State<TvMovieCard> {
  static const Color _accent = Color(0xFF36C8D5);

  bool _isFocused = false;

  String _imageUrl(String path) {
    final value = path.trim();

    if (value.isEmpty) return '';

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    return 'https://assets.leichiltv.com/'
        '${value.replaceFirst(RegExp(r'^/+'), '')}';
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _imageUrl(widget.video.thumbnail);

    const aspectRatio = 2 / 3;
    final width = AppDimensions.posterWidth(context) * 1.15;

    return SizedBox(
      width: width,
      child: Builder(
        builder: (cardContext) {
          return Align(
            alignment: Alignment.topCenter,
            child: TvFocusWrapper(
              focusNode: widget.focusNode,
              autofocus: widget.autofocus,
              style: TvFocusStyle.card,
              onPressed: widget.onPressed,
              onKeyEvent: widget.onKeyEvent,
              onFocusChanged: (focused) {
                if (mounted && _isFocused != focused) {
                  setState(() => _isFocused = focused);
                }

                if (focused) {
                  Scrollable.ensureVisible(
                    cardContext,
                    alignment: 0.35,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                  );
                }
              },
              child: AnimatedScale(
                scale: _isFocused ? 1.035 : 1.0,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _isFocused
                          ? _accent
                          : Colors.transparent,
                      width: 2.2,
                    ),
                    boxShadow: _isFocused
                        ? [
                            BoxShadow(
                              color: _accent.withValues(alpha: 0.24),
                              blurRadius: 20,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: ClipRect(
                    child: AspectRatio(
                      aspectRatio: aspectRatio,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildImage(imageUrl: imageUrl),

                          if (widget.video.isPremium)
                            Positioned(
                              top: 10,
                              left: 10,
                              child: _buildPremiumBadge(),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPremiumBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE5B84B),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Text(
        'PREMIUM',
        style: TextStyle(
          color: Color(0xFF17130A),
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildImage({required String imageUrl}) {
    if (imageUrl.isEmpty) {
      return _buildPlaceholder();
    }

    return Image.network(
      imageUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('TV MOVIE IMAGE ERROR: $imageUrl');
        return _buildPlaceholder();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;

        return Container(
          color: AppColors.surface,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _accent,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.surface,
      alignment: Alignment.center,
      child: const Icon(
        Icons.movie_creation_outlined,
        color: AppColors.textMuted,
        size: 42,
      ),
    );
  }
}