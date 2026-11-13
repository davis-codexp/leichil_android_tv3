import 'screens/checkouts_and_subscriptions/checkout_screen.dart';
import 'screens/checkouts_and_subscriptions/subscription_screen.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'services/auth_storage.dart';
import 'screens/shell/main_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LeichilTV());
}

class LeichilTV extends StatelessWidget {
  const LeichilTV({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leichil TV',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      builder: (context, child) => FocusTraversalGroup(
        policy: ReadingOrderTraversalPolicy(),
        child: child ?? const SizedBox.shrink(),
      ),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/checkout':
            final args = settings.arguments is Map
                ? Map<String, dynamic>.from(settings.arguments as Map)
                : <String, dynamic>{};

            final rawPrice = args['price'];
            final moviePrice = rawPrice is num
                ? rawPrice.toInt()
                : int.tryParse(rawPrice?.toString() ?? '') ?? 0;

            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => CheckoutScreen(
                title: args['title']?.toString() ?? 'Movie',
                posterUrl: args['posterUrl']?.toString(),
                moviePrice: moviePrice,
                // The checkout UI includes a one-month subscription
                // and an equal discount, so the subscription is free.
                subscriptionPrice: 49,
                subscriptionDiscount: 49,
              ),
            );

          case '/subscription':
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const SubscriptionScreen(),
            );

          default:
            return null;
        }
      },
      home: const LeichilSplashScreen(),
    );
  }
}

class LeichilSplashScreen extends StatefulWidget {
  const LeichilSplashScreen({super.key});

  @override
  State<LeichilSplashScreen> createState() => _LeichilSplashScreenState();
}

class _LeichilSplashScreenState extends State<LeichilSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoMove;
  late final Animation<double> _glowOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<double> _taglineOpacity;

  bool _leaving = false;

  static const Color _background = Color(0xFF0B1118);
  static const Color _cyan = Color(0xFF19A9D3);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );

    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.22, curve: Curves.easeOutCubic),
    );

    _logoScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _logoMove = Tween<double>(begin: 12, end: -28).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.78, curve: Curves.easeInOutCubic),
      ),
    );

    _glowOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    );

    _textOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.85, curve: Curves.easeOutCubic),
    );

    _taglineOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.72, 1.0, curve: Curves.easeOutCubic),
    );

    _startSplash();
  }

  // Future<void> _startSplash() async {
  //   await _controller.forward();

  //   await Future.delayed(const Duration(milliseconds: 650));

  //   if (!mounted) return;

  //   setState(() => _leaving = true);

  //   await Future.delayed(const Duration(milliseconds: 300));

  //   if (!mounted) return;

  //   Navigator.of(context).pushReplacement(
  //     PageRouteBuilder(
  //       transitionDuration: const Duration(milliseconds: 450),
  //       pageBuilder: (_, animation, secondaryAnimation) => const LoginScreen(),
  //       transitionsBuilder: (_, animation, secondaryAnimation, child) {
  //         return FadeTransition(
  //           opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
  //           child: child,
  //         );
  //       },
  //     ),
  //   );
  // }

  Future<void> _startSplash() async {
  await _controller.forward();

  await Future.delayed(const Duration(milliseconds: 650));

  if (!mounted) return;

  setState(() => _leaving = true);

  await Future.delayed(const Duration(milliseconds: 300));

  if (!mounted) return;

  // Restore the previous login session.
  bool isLoggedIn = false;

  try {
    isLoggedIn = await AuthStorage.isLoggedIn();
  } catch (e) {
    debugPrint('SESSION RESTORE ERROR: $e');
  }

  if (!mounted) return;

  Navigator.of(context).pushReplacement(
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (_, animation, secondaryAnimation) {
        return isLoggedIn
            ? const MainShell()
            : const LoginScreen();
      },
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: child,
        );
      },
    ),
  );
}

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _leaving ? 0 : 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            final scale = (width / 1920).clamp(0.65, 1.15).toDouble();

            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background cinematic glow.
                    Positioned(
                      left: width * 0.5 - 250 * scale,
                      top: height * 0.5 - 200 * scale,
                      width: 500 * scale,
                      height: 400 * scale,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: _glowOpacity.value,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _cyan.withValues(alpha: 0.20),
                                  blurRadius: 120 * scale,
                                  spreadRadius: 25 * scale,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Main logo.
                    Positioned(
                      top: height * 0.5 - 180 * scale + _logoMove.value * scale,
                      left: width * 0.5 - 145 * scale,
                      width: 290 * scale,
                      height: 230 * scale,
                      child: Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Image.asset(
                            'assets/images/leichil_logo.webp',
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) {
                              return const Icon(
                                Icons.live_tv_rounded,
                                color: Colors.white,
                                size: 120,
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    // Animated brand name.
                    Positioned(
                      top: height * 0.5 + 35 * scale,
                      left: 0,
                      right: 0,
                      child: Opacity(
                        opacity: _textOpacity.value,
                        child: Center(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'LEICHIL',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 48 * scale,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 5 * scale,
                                  ),
                                ),
                                TextSpan(
                                  text: ' TV',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 48 * scale,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 5 * scale,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Tagline.
                    Positioned(
                      top: height * 0.5 + 105 * scale,
                      left: 0,
                      right: 0,
                      child: Opacity(
                        opacity: _taglineOpacity.value,
                        child: Text(
                          'STORIES THAT STAY WITH YOU',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 13 * scale,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 4 * scale,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
