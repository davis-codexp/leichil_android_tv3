import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/navigation/tv_focus_style.dart';
import '../../widgets/navigation/tv_focus_wrapper.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';
import '../view_all/view_all_screen.dart';

class _ShellNavigatorObserver extends NavigatorObserver {
  final VoidCallback onReturnedToHome;

  _ShellNavigatorObserver({required this.onReturnedToHome});

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);

    if (previousRoute?.settings.name == '/') {
      onReturnedToHome();
    }
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const Color _background = Colors.black;
  static const Color _accent = Color(0xFF36C8D5);
  static const double _sidebarWidth = 96;

  static const List<String> _labels = [
    'Home',
    'Movies',
    'Series',
    'Search',
    'Profile',
  ];

  static const List<IconData> _icons = [
    Icons.home_rounded,
    Icons.movie_outlined,
    Icons.live_tv_rounded,
    Icons.search_rounded,
    Icons.person_outline_rounded,
  ];

  final FocusNode _pageEntryFocus = FocusNode(debugLabel: 'ShellPageEntry');

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  final FocusNode _homeEntryFocus = FocusNode(debugLabel: 'ShellHomeEntry');

  late final List<FocusNode> _menuFocusNodes = List.generate(
    _labels.length,
    (index) => FocusNode(debugLabel: 'ShellMenu$index'),
  );

  late final _ShellNavigatorObserver _navigatorObserver =
      _ShellNavigatorObserver(
        onReturnedToHome: () {
          if (!mounted) return;

          setState(() => _selectedIndex = 0);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _homeEntryFocus.requestFocus();
            }
          });
        },
      );

  int _selectedIndex = 0;

  bool _showingExitDialog = false;

  @override
  void dispose() {
    _pageEntryFocus.dispose();
    _homeEntryFocus.dispose();

    for (final node in _menuFocusNodes) {
      node.dispose();
    }

    super.dispose();
  }

  void _focusSelectedMenu() {
    _menuFocusNodes[_selectedIndex].requestFocus();
  }

  // void _selectSection(int index) {
  //   if (index < 0 || index >= _labels.length) return;

  //   setState(() => _selectedIndex = index);

  void _selectSection(int index) {
  if (index < 0 || index >= _labels.length) return;

  // Clear focus from the previous page before switching sections.
  FocusManager.instance.primaryFocus?.unfocus();

  setState(() => _selectedIndex = index);

    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;

    if (index == 0) {
      navigator.popUntil((route) => route.isFirst);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _homeEntryFocus.requestFocus();
        }
      });

      return;
    }

    final routeName = switch (index) {
      1 => '/movies',
      2 => '/series',
      3 => '/search',
      4 => '/profile',
      _ => '/',
    };

    navigator.pushNamedAndRemoveUntil(routeName, (route) => route.isFirst);
  }

  // void _handleBack() {
  //   if (_showingExitDialog) return;

  //   final rootNavigator = Navigator.of(context, rootNavigator: true);

  //   if (rootNavigator.canPop()) {
  //     rootNavigator.pop();
  //     return;
  //   }

  //   // 2. Then close routes inside MainShell's nested Navigator.
  //   //    This handles DetailScreen and other pushed pages.
  //   final navigator = _navigatorKey.currentState;

  //   if (navigator == null) return;

  //   if (navigator.canPop()) {
  //     navigator.pop();
  //     return;
  //   }

  //   // 3. Return to Home from another main section.
  //   if (_selectedIndex != 0) {
  //     _selectSection(0);
  //     return;
  //   }

  //   // 4. Show exit confirmation only when already on Home.
  //   _showExitConfirmation();
  // }

  void _handleBack() {
  if (_showingExitDialog) return;

  final navigator = _navigatorKey.currentState;

  // Always pop the previous page first.
  if (navigator != null && navigator.canPop()) {
    navigator.pop();
    return;
  }

  // Exit only when the actual current page is Home.
  if (_selectedIndex == 0) {
    _showExitConfirmation();
  }
}

  Future<void> _showExitConfirmation() async {
    if (_showingExitDialog || !mounted) return;

    _showingExitDialog = true;

    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF171717),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text(
            'Exit Leichil TV?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            'Are you sure you want to exit the app?',
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(
                'CANCEL',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text(
                'EXIT',
                style: TextStyle(color: _accent, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    _showingExitDialog = false;

    if (!mounted) return;

    if (shouldExit == true) {
      SystemNavigator.pop();
    } else {
      _homeEntryFocus.requestFocus();
    }
  }

  // ------------------------------------------------------------
  // SIDEBAR NAVIGATION
  // ------------------------------------------------------------

  KeyEventResult _handleMenuKeys(int index, KeyEvent event) {
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
      if (index > 0) {
        _menuFocusNodes[index - 1].requestFocus();
      }

      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowDown) {
      if (index < _menuFocusNodes.length - 1) {
        _menuFocusNodes[index + 1].requestFocus();
      }

      return KeyEventResult.handled;
    }

    // // if (key == LogicalKeyboardKey.arrowRight) {
    // //   if (index == 0) {
    // //     _homeEntryFocus.requestFocus();
    // //   } else {
    // //     _pageEntryFocus.requestFocus();
    // //   }

    // //   return KeyEventResult.handled;
    // }

    if (key == LogicalKeyboardKey.arrowRight) {
      // Use the currently displayed page, not the focused sidebar item.
      if (_selectedIndex == 0) {
        _homeEntryFocus.requestFocus();
      } else {
        _pageEntryFocus.requestFocus();
      }

      return KeyEventResult.handled;
    }

    return KeyEventResult.handled;
  }

  Widget _buildSidebar() {
    return Container(
      width: _sidebarWidth,
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 18),
      decoration: BoxDecoration(
        color: _background.withOpacity(0.96),
        border: Border(
          right: BorderSide(color: Colors.white.withOpacity(0.06), width: 1),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            margin: const EdgeInsets.only(bottom: 28),
            child: Image.asset(
              'assets/images/leichil_logo.webp',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
          ),
          ...List.generate(_labels.length, (index) {
            final selected = _selectedIndex == index;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TvFocusWrapper(
                focusNode: _menuFocusNodes[index],
                autofocus: index == 0,
                style: TvFocusStyle.menu,
                focusBorderRadius: 16,
                onKeyEvent: (_, event) => _handleMenuKeys(index, event),
                onPressed: () => _selectSection(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  width: 72,
                  height: 66,
                  decoration: BoxDecoration(
                    color: selected ? _accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _icons[index],
                        size: 23,
                        color: selected
                            ? const Color(0xFF061114)
                            : Colors.white70,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _labels[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selected
                              ? const Color(0xFF061114)
                              : Colors.white.withOpacity(0.84),
                          fontSize: 9,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // ROUTES
  // ------------------------------------------------------------

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    late final Widget page;

    switch (settings.name) {
      case '/movies':
        page = ViewAllScreen(
          title: 'Movies',
          contentType: 'MOVIE',
          onFocusSidebar: _focusSelectedMenu,
          entryFocusNode: _pageEntryFocus,
        );
        break;

      case '/series':
        page = ViewAllScreen(
          title: 'Series',
          contentType: 'SERIES',
          onFocusSidebar: _focusSelectedMenu,
          entryFocusNode: _pageEntryFocus,
        );
        break;

      case '/search':
        page = SearchScreen(
          onFocusSidebar: _focusSelectedMenu,
          entryFocusNode: _pageEntryFocus,
        );
        break;

      case '/profile':
        page = ProfileScreen(
          onFocusSidebar: _focusSelectedMenu,
          entryFocusNode: _pageEntryFocus,
        );
        break;

      case '/':
      default:
        page = HomeScreen(
          onFocusSidebar: _focusSelectedMenu,
          entryFocusNode: _homeEntryFocus,
        );
        break;
    }

    return MaterialPageRoute<dynamic>(builder: (_) => page, settings: settings);
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        _handleBack();
      },
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          top: false,
          bottom: false,
          child: Row(
            children: [
              _buildSidebar(),

              Expanded(
                child: Focus(
                  onKeyEvent: (node, event) {
                    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
                      return KeyEventResult.ignored;
                    }

                    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                      _focusSelectedMenu();
                      return KeyEventResult.handled;
                    }

                    return KeyEventResult.ignored;
                  },
                  child: Navigator(
                    key: _navigatorKey,
                    observers: [_navigatorObserver],
                    initialRoute: '/',
                    onGenerateRoute: _onGenerateRoute,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
