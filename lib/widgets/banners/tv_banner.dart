import 'package:flutter/material.dart';
import '../../models/video_model.dart';
import '../navigation/tv_focus_style.dart';
import '../navigation/tv_focus_wrapper.dart';

class TvBanner extends StatelessWidget {
  const TvBanner({
    super.key,
    required this.video,
    this.playFocusNode,
    this.infoFocusNode,
    this.onHeroFocus,
    this.onPlay,
    this.onMoreInfo,
    this.onPlayKeyEvent,
    this.onInfoKeyEvent,
  });

  final VideoModel video;
  final FocusNode? playFocusNode;
  final FocusNode? infoFocusNode;
  final VoidCallback? onHeroFocus;
  final VoidCallback? onPlay;
  final VoidCallback? onMoreInfo;
  final FocusOnKeyEventCallback? onPlayKeyEvent;
  final FocusOnKeyEventCallback? onInfoKeyEvent;

  static const Color _accent = Color(0xFF36C8D5);

  String _imageUrl(String path) {
    final value = path.trim();

    if (value.isEmpty) return '';

    if (value.startsWith('http://') ||
        value.startsWith('https://')) {
      return value;
    }

    return 'https://assets.leichiltv.com/${value.replaceFirst(RegExp(r'^/+'), '')}';
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _imageUrl(video.tvThumbnail);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bannerWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        final bannerHeight = bannerWidth * 9 / 16;

        return SizedBox(
          width: double.infinity,
          height: bannerHeight,
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Full-bleed hero image.
                if (imageUrl.isNotEmpty)
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return _fallback();
                    },
                  )
                else
                  _fallback(),

                // Bottom gradient only. No top background overlay.
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Color(0x55000000),
                          Color(0xE6000000),
                        ],
                        stops: [0.0, 0.45, 0.72, 1.0],
                      ),
                    ),
                  ),
                ),

                // Hero content.
                Padding(
                  padding: const EdgeInsets.fromLTRB(42, 54, 36, 54),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 590,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: _accent.withOpacity(0.45),
                              ),
                            ),
                            child: const Text(
                              'FEATURED',
                              style: TextStyle(
                                color: _accent,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ),

                          const SizedBox(height: 15),

                          Text(
                            video.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 44,
                              height: 1.04,
                              letterSpacing: 0.2,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 13),

                          Text(
                            [
                              if (video.category.trim().isNotEmpty)
                                video.category.trim(),
                              if (video.year.trim().isNotEmpty)
                                video.year.trim(),
                              if (video.rating > 0)
                                '★ ${video.rating.toStringAsFixed(1)}',
                            ].join('   •   '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 24),

                          Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            children: [
                              TvFocusWrapper(
                                focusNode: playFocusNode,
                                autofocus: true,
                                style: TvFocusStyle.button,
                                onPressed: onPlay,
                                onKeyEvent: onPlayKeyEvent,
                                onFocusChanged: (focused) {
                                  if (focused) {
                                    onHeroFocus?.call();
                                  }
                                },
                                child: const _HeroButton(
                                  icon: Icons.play_arrow_rounded,
                                  label: 'Play Now',
                                  primary: true,
                                ),
                              ),

                              TvFocusWrapper(
                                focusNode: infoFocusNode,
                                style: TvFocusStyle.button,
                                onPressed: onMoreInfo,
                                onKeyEvent: onInfoKeyEvent,
                                scaleOnFocus: true,
                                child: const _HeroButton(
                                  icon: Icons.info_outline_rounded,
                                  label: 'More Info',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _fallback() {
    return Container(
      color: const Color(0xFF171B22),
      alignment: Alignment.center,
      child: const Icon(
        Icons.movie_creation_outlined,
        color: Colors.white24,
        size: 100,
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.icon,
    required this.label,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: primary
            ? const Color(0xFFE8ECEF)
            : const Color(0xFF111216),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primary
              ? Colors.transparent
              : const Color(0xFF454951),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: primary ? Colors.black : Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: primary ? Colors.black : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
