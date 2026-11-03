import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../navigation/tv_focus_style.dart';
import '../navigation/tv_focus_wrapper.dart';

enum ConnectionErrorType { noInternet, serverDown, general }

class ConnectionErrorScreen extends StatelessWidget {
  const ConnectionErrorScreen({
    super.key,
    required this.onReload,
    this.type = ConnectionErrorType.general,
    this.isRetrying = false,
  });

  final VoidCallback onReload;
  final ConnectionErrorType type;
  final bool isRetrying;

  static const Color _accent = Color(0xFF36C8D5);

  String get _title => switch (type) {
    ConnectionErrorType.noInternet => 'No Internet Connection',
    ConnectionErrorType.serverDown => 'Server Temporarily Unavailable',
    ConnectionErrorType.general => 'Something Went Wrong',
  };

  String get _description => switch (type) {
    ConnectionErrorType.noInternet =>
      'Check your internet connection and try again.',
    ConnectionErrorType.serverDown =>
      'We could not reach our servers. Please try again shortly.',
    ConnectionErrorType.general =>
      'We could not load your content. Please try again.',
  };

  IconData get _icon => switch (type) {
    ConnectionErrorType.noInternet => Icons.wifi_off_rounded,
    ConnectionErrorType.serverDown => Icons.cloud_off_rounded,
    ConnectionErrorType.general => Icons.refresh_rounded,
  };

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.background,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent.withValues(alpha: .09),
                  border: Border.all(
                    color: _accent.withValues(alpha: .3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _accent.withValues(alpha: .08),
                      blurRadius: 32,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Icon(_icon, size: 48, color: _accent),
              ),
              const SizedBox(height: 28),
              Text(
                _title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFADB3BD),
                  fontSize: 17,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 30),
              TvFocusWrapper(
                autofocus: true,
                style: TvFocusStyle.button,
                onPressed: isRetrying ? null : onReload,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 160),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isRetrying)
                        const SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF031114),
                          ),
                        )
                      else
                        const Icon(
                          Icons.refresh_rounded,
                          color: Color(0xFF031114),
                        ),
                      const SizedBox(width: 9),
                      Text(
                        isRetrying ? 'Please wait' : 'Reload',
                        style: const TextStyle(
                          color: Color(0xFF031114),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isRetrying) ...[
                const SizedBox(height: 18),
                const Text(
                  'Reconnecting…',
                  style: TextStyle(color: Colors.white60, fontSize: 14),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
