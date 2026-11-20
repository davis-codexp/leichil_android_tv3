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
  final VoidCallback? onFaq; // Retained for compatibility; FAQ menu is removed.
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
  bool _isLoggingOut = false;

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

  void _showCompanyInfo() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: _surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: _cyan.withValues(alpha: 0.25)),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(30, 26, 30, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Company Contact Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 24),
                _buildContactDetail(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: 'contact@ironbladelabs.com',
                ),
                const SizedBox(height: 20),
                _buildContactDetail(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: '8787432885',
                ),
                const SizedBox(height: 20),
                _buildContactDetail(
                  icon: Icons.chat_outlined,
                  label: 'WhatsApp',
                  value: '8787432885',
                ),
                const SizedBox(height: 26),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    autofocus: true,
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        color: _cyan,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    if (_isLoggingOut) return;

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _surface,
        title: const Text(
          'Logout',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to sign out of your LeichilTV account?',
          style: TextStyle(color: _muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: _muted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Logout',
              style: TextStyle(color: _red),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await _performLogout();
    }
  }

Future<void> _performLogout() async {
  setState(() {
    _isLoggingOut = true;
  });

  try {
    // Clear the locally stored authentication session.
    await AuthStorage.clearSession();

    if (!mounted) return;

    // Let the parent screen navigate to LoginScreen.
    if (widget.onLogout != null) {
      widget.onLogout!.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged out successfully'),
        ),
      );
    }
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logout failed: $e'),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        _isLoggingOut = false;
      });
    }
  }
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
                                icon: Icons.apartment_rounded,
                                title: 'Company Information',
                                subtitle:
                                    'About LeichilTV and contact details',
                                iconColor: const Color(0xFFDAE7FF),
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
                                onPressed: widget.onCompanyInfo ??
                                    _showCompanyInfo,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact & Support',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Iron Blade Labs',
            style: TextStyle(
              color: _muted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          _buildContactDetail(
            icon: Icons.email_outlined,
            label: 'Email',
            value: 'contact@ironbladelabs.com',
          ),
          const SizedBox(height: 15),
          _buildContactDetail(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: '8787432885',
          ),
          const SizedBox(height: 15),
          _buildContactDetail(
            icon: Icons.chat_outlined,
            label: 'WhatsApp',
            value: '8787432885',
          ),
        ],
      ),
    );
  }

  Widget _buildContactDetail({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _cyan, size: 20),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              SelectableText(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
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
      onPressed: _confirmLogout,
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
        child: Row(
          children: [
            if (_isLoggingOut)
              SizedBox(
                width: 29,
                height: 29,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: _red,
                ),
              )
            else
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
