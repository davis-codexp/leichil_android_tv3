import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../services/auth_storage.dart';
import '../../widgets/navigation/tv_focus_style.dart';
import '../../widgets/navigation/tv_focus_wrapper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.onBack,
    this.onLogout,
    this.onFaq,
    this.onCompanyInfo,
    this.userName = 'LeichilTV User',
    this.phoneNumber = '',
    this.isSubscriptionActive = false,
    this.subscriptionExpiry = '',
      this.onFocusSidebar,
  this.entryFocusNode,
  });

  final VoidCallback? onBack;
  final VoidCallback? onLogout;
  final VoidCallback? onFaq;
  final VoidCallback? onCompanyInfo;

  final String userName;
  final String phoneNumber;
  final bool isSubscriptionActive;
  final String subscriptionExpiry;
  final VoidCallback? onFocusSidebar;
  final FocusNode? entryFocusNode;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String userName;
  late String phoneNumber;
  late bool isSubscriptionActive;
  late String subscriptionExpiry;
  bool _isLoadingProfile = true;
  bool _isLoadingSubscription = true;
  String? _profileError;
  String? _subscriptionError;

  @override
  void initState() {
    super.initState();
    userName = widget.userName;
    phoneNumber = widget.phoneNumber;
    isSubscriptionActive = widget.isSubscriptionActive;
    subscriptionExpiry = widget.subscriptionExpiry;
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    await Future.wait([
      _loadSavedProfile(),
      _loadSubscription(),
    ]);
  }

  Future<void> _loadSavedProfile() async {
    try {
      final name = await AuthStorage.getName();
      final mobile = await AuthStorage.getMobile();
      if (!mounted) return;

      setState(() {
        userName = (name != null && name.trim().isNotEmpty)
            ? name.trim()
            : widget.userName;
        phoneNumber = (mobile != null && mobile.trim().isNotEmpty)
            ? mobile.trim()
            : widget.phoneNumber;
        _isLoadingProfile = false;
        _profileError = null;
      });
    } catch (error) {
      debugPrint('PROFILE STORAGE ERROR: $error');
      if (!mounted) return;
      setState(() {
        _isLoadingProfile = false;
        _profileError = 'Unable to load account information.';
      });
    }
  }

  Future<void> _loadSubscription() async {
    try {
      final response = await ApiService.get(
        '/api/v1/app/subscriptions/verify',
      );
      if (!mounted) return;

      final data = response.data;
      if (response.isSuccess && data is Map && data['success'] == true) {
        setState(() {
          isSubscriptionActive = true;
          _isLoadingSubscription = false;
          _subscriptionError = null;
        });
      } else if (response.isSuccess &&
          data is Map &&
          data['success'] == false) {
        setState(() {
          isSubscriptionActive = false;
          subscriptionExpiry = '';
          _isLoadingSubscription = false;
          _subscriptionError = null;
        });
      } else {
        setState(() {
          _isLoadingSubscription = false;
          _subscriptionError = data is Map
              ? (data['message']?.toString() ??
                  'Unable to verify subscription.')
              : 'Unable to verify subscription.';
        });
      }
    } catch (error) {
      debugPrint('SUBSCRIPTION VERIFY ERROR: $error');
      if (!mounted) return;
      setState(() {
        _isLoadingSubscription = false;
        _subscriptionError = 'Unable to verify subscription.';
      });
    }
  }

  static const Color _background = Color(0xFF050D1B);
  static const Color _surface = Color(0xFF131D2D);
  static const Color _cyan = Color(0xFF00CFFF);
  static const Color _muted = Color(0xFFA9B8CC);
  static const Color _green = Color(0xFF27E58B);
  static const Color _red = Color(0xFFFF5369);

  // void _goBack(BuildContext context) {
  //   if (widget.onBack != null) {
  //     widget.onBack!();
  //   } else if (Navigator.of(context).canPop()) {
  //     Navigator.of(context).pop();
  //   }
  // }

  void _showInfo(BuildContext context, String title, String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _surface,
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          message,
          style: const TextStyle(color: _muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: _cyan),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.4,
            colors: [
              Color(0xFF10284B),
              _background,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 850;
              final pagePadding = compact ? 22.0 : 42.0;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  pagePadding,
                  20,
                  pagePadding,
                  28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        // TvFocusWrapper(
                        //   style: TvFocusStyle.button,
                        //   onPressed: () => _goBack(context),
                        //   child: const Padding(
                        //     padding: EdgeInsets.all(10),
                        //     child: Icon(
                        //       Icons.arrow_back_rounded,
                        //       color: Colors.white,
                        //       size: 28,
                        //     ),
                        //   ),
                        // ),
                        // const SizedBox(width: 12),
                        const Text(
                          'Leichil',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'TV',
                          style: TextStyle(
                            color: _cyan,
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Container(
                          height: 26,
                          width: 1,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 18,
                          ),
                          color: Colors.white24,
                        ),
                        const Text(
                          'Profile',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Main profile layout
                    Flex(
                      direction:
                          compact ? Axis.vertical : Axis.horizontal,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LEFT: User and subscription
                        Expanded(
                          flex: compact ? 0 : 5,
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              _buildUserCard(compact),

                              const SizedBox(height: 20),

                              _buildSubscriptionCard(),

                              const SizedBox(height: 24),

                              _buildCompanySummary(),
                            ],
                          ),
                        ),

                        SizedBox(
                          width: compact ? 0 : 34,
                          height: compact ? 24 : 0,
                        ),

                        // RIGHT: Action menu
                        Expanded(
                          flex: compact ? 0 : 7,
                          child: Column(
                            children: [
                              _buildMenuItem(
                                context: context,
                                icon: Icons.help_outline_rounded,
                                title: 'FAQ',
                                subtitle:
                                    'Find answers to common questions',
                                iconColor: const Color(0xFF63B8FF),
                                focusNode: widget.entryFocusNode,
                                autofocus: widget.entryFocusNode == null,
                                onKeyEvent: (_, event) {
                                  if ((event is KeyDownEvent ||
                                          event is KeyRepeatEvent) &&
                                      event.logicalKey ==
                                          LogicalKeyboardKey.arrowLeft) {
                                    widget.onFocusSidebar?.call();
                                    return KeyEventResult.handled;
                                  }
                                  return KeyEventResult.ignored;
                                },
                                onPressed: widget.onFaq ??
                                    () => _showInfo(
                                          context,
                                          'FAQ',
                                          'FAQ content will be connected '
                                              'here.',
                                        ),
                              ),

                              const SizedBox(height: 14),

                              _buildMenuItem(
                                context: context,
                                icon: Icons.apartment_rounded,
                                title: 'Company Information',
                                subtitle:
                                    'About LeichilTV and contact details',
                                iconColor: const Color(0xFFDAE7FF),
                                onKeyEvent: (_, event) {
                                  if ((event is KeyDownEvent ||
                                          event is KeyRepeatEvent) &&
                                      event.logicalKey ==
                                          LogicalKeyboardKey.arrowLeft) {
                                    widget.onFocusSidebar?.call();
                                    return KeyEventResult.handled;
                                  }
                                  return KeyEventResult.ignored;
                                },
                                onPressed: widget.onCompanyInfo ??
                                    () => _showInfo(
                                          context,
                                          'About LeichilTV',
                                          'LeichilTV is your regional '
                                              'streaming platform for '
                                              'movies, series and more.',
                                        ),
                              ),

                              const SizedBox(height: 18),

                              _buildLogoutButton(
                                context,
                                onKeyEvent: (_, event) {
                                  if ((event is KeyDownEvent ||
                                          event is KeyRepeatEvent) &&
                                      event.logicalKey ==
                                          LogicalKeyboardKey.arrowLeft) {
                                    widget.onFocusSidebar?.call();
                                    return KeyEventResult.handled;
                                  }
                                  return KeyEventResult.ignored;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(bool compact) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 22 : 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF142D51),
            Color(0xFF101827),
            Color(0xFF151328),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: compact ? 94 : 118,
              height: compact ? 94 : 118,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    _cyan,
                    Color(0xFF8255FF),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _cyan.withValues(alpha: 0.15),
                    blurRadius: 25,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(3),
              child: const CircleAvatar(
                backgroundColor: Color(0xFF142442),
                child: Icon(
                  Icons.person_rounded,
                  size: 66,
                  color: Color(0xFFDCE7FF),
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          Center(
            child: Text(
              _isLoadingProfile ? 'Loading profile...' : userName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 23 : 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          if (_profileError != null) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                _profileError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ),
          ],

          if (phoneNumber.trim().isNotEmpty) ...[
            const SizedBox(height: 9),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.phone_android_rounded,
                    color: _muted,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      phoneNumber,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),

          const Center(
            child: Text(
              'YOUR LEICHILTV ACCOUNT',
              style: TextStyle(
                color: _muted,
                fontSize: 11,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    final statusColor = isSubscriptionActive ? _green : _red;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isSubscriptionActive
            ? const Color(0xFF08251F)
            : const Color(0xFF2B1720),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor.withValues(alpha: 0.12),
            ),
            child: Icon(
              Icons.workspace_premium_rounded,
              color: statusColor,
              size: 32,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Subscription',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isLoadingSubscription)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _cyan,
                          ),
                        )
                      else
                        Icon(
                          isSubscriptionActive
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: statusColor,
                          size: 15,
                        ),
                      const SizedBox(width: 6),
                      Text(
                        _isLoadingSubscription
                            ? 'CHECKING'
                            : isSubscriptionActive
                                ? 'ACTIVE'
                                : 'NOT ACTIVE',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),

                if (_subscriptionError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _subscriptionError!,
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                ],

                if (isSubscriptionActive &&
                    subscriptionExpiry.trim().isNotEmpty) ...[
                  const SizedBox(height: 9),
                  Text(
                    'Valid until $subscriptionExpiry',
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanySummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About LeichilTV',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Your destination for regional movies, series '
            'and entertainment.',
            style: TextStyle(
              color: _muted,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          SizedBox(height: 15),
          Row(
            children: [
              Icon(
                Icons.live_tv_rounded,
                color: _cyan,
                size: 19,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Movies • Series • Regional content',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onPressed,
    bool autofocus = false,
    FocusNode? focusNode,
    // KeyEventCallback? onKeyEvent,
    FocusOnKeyEventCallback? onKeyEvent,
  }) {
    return TvFocusWrapper(
      focusNode: focusNode,
      onKeyEvent: onKeyEvent,
      style: TvFocusStyle.button,
      autofocus: autofocus,
      onPressed: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 22,
        ),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 30,
              ),
            ),

            const SizedBox(width: 20),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFB9D4F5),
              size: 30,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(
    BuildContext context, {
    // KeyEventCallback? onKeyEvent,
    FocusOnKeyEventCallback? onKeyEvent,
  }) {
    return TvFocusWrapper(
      style: TvFocusStyle.button,
      onKeyEvent: onKeyEvent,
      onPressed: widget.onLogout ??
          () => _showInfo(
                context,
                'Logout',
                'Connect your existing logout callback to sign out.',
              ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 20,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF2B1720),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: _red.withValues(alpha: 0.4),
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.logout_rounded,
              color: _red,
              size: 29,
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Logout',
                    style: TextStyle(
                      color: Color(0xFFFFA6B1),
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Sign out of your LeichilTV account',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFFFA6B1),
              size: 30,
            ),
          ],
        ),
      ),
    );
  }
}
