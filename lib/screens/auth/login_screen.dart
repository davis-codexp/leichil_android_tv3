import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../widgets/common/connection_error_screen.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _mobileController = TextEditingController();

  final FocusNode _mobileFocus = FocusNode(debugLabel: 'MobileNumber');
  final FocusNode _buttonFocus = FocusNode(debugLabel: 'ContinueButton');
  final List<FocusNode> _keypadFocusNodes = List.generate(
    12,
    (index) => FocusNode(debugLabel: 'Keypad${index + 1}'),
  );

  bool _loading = false;

  ConnectionErrorType? _connectionErrorType;
  String? _validationMessage;
  String? _requestMessage;

  static const Color _background = Color(0xFF000000);
  static const Color _panel = Color(0xFF101114);
  static const Color _accent = Color(0xFF36C8D5);
  static const Color _muted = Color(0xFF969BA5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _keypadFocusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _mobileFocus.dispose();
    _buttonFocus.dispose();
    for (final node in _keypadFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  bool _isNetworkError(Object error) {
    if (error is SocketException || error is TimeoutException) {
      return true;
    }

    final message = error.toString().toLowerCase();

    return message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('network is unreachable') ||
        message.contains('connection refused') ||
        message.contains('connection reset') ||
        message.contains('connection timed out') ||
        message.contains('timed out') ||
        message.contains('no internet') ||
        message.contains('handshakeexception') ||
        message.contains('clientexception');
  }

  void _showConnectionError(ConnectionErrorType type) {
    if (!mounted) return;

    setState(() {
      _connectionErrorType = type;
      _requestMessage = null;
      _validationMessage = null;
    });
  }

  void _addDigit(String digit) {
    if (_loading || _mobileController.text.length >= 10) return;

    setState(() {
      _mobileController.text += digit;
      _mobileController.selection = TextSelection.collapsed(
        offset: _mobileController.text.length,
      );
      _validationMessage = null;
      _requestMessage = null;
      _connectionErrorType = null;
    });
  }

  void _deleteDigit() {
    if (_loading || _mobileController.text.isEmpty) return;

    setState(() {
      _mobileController.text = _mobileController.text.substring(
        0,
        _mobileController.text.length - 1,
      );
      _mobileController.selection = TextSelection.collapsed(
        offset: _mobileController.text.length,
      );
      _validationMessage = null;
      _requestMessage = null;
    });
  }

  void _clearNumber() {
    if (_loading) return;

    setState(() {
      _mobileController.clear();
      _validationMessage = null;
      _requestMessage = null;
    });
  }

  KeyEventResult _handleKeypadKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final currentIndex = _keypadFocusNodes.indexWhere(
      (focusNode) => focusNode.hasFocus,
    );

    if (currentIndex < 0) return KeyEventResult.ignored;

    final key = event.logicalKey;
    int? nextIndex;

    if (key == LogicalKeyboardKey.arrowUp) {
      if (currentIndex >= 3) {
        nextIndex = currentIndex - 3;
      } else {
        _mobileFocus.requestFocus();
        return KeyEventResult.handled;
      }
    } else if (key == LogicalKeyboardKey.arrowDown) {
      if (currentIndex <= 8) {
        nextIndex = currentIndex + 3;
      } else {
        _buttonFocus.requestFocus();
        return KeyEventResult.handled;
      }
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      if (currentIndex % 3 == 0) {
        _buttonFocus.requestFocus();
        return KeyEventResult.handled;
      }
      nextIndex = currentIndex - 1;
    } else if (key == LogicalKeyboardKey.arrowRight) {
      if (currentIndex % 3 == 2) {
        return KeyEventResult.handled;
      }
      nextIndex = currentIndex + 1;
    } else {
      return KeyEventResult.ignored;
    }

    if (nextIndex != null && nextIndex >= 0 && nextIndex < 12) {
      _keypadFocusNodes[nextIndex].requestFocus();
    }

    return KeyEventResult.handled;
  }

  KeyEventResult _handleFormKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
        (_mobileFocus.hasFocus || _buttonFocus.hasFocus)) {
      _keypadFocusNodes[0].requestFocus();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown &&
        _mobileFocus.hasFocus) {
      _buttonFocus.requestFocus();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp &&
        _buttonFocus.hasFocus) {
      _mobileFocus.requestFocus();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Future<void> _getOtp() async {
    final mobile = _mobileController.text.trim();

    if (_loading) return;

    if (!RegExp(r'^[0-9]{10}$').hasMatch(mobile)) {
      setState(() {
        _validationMessage = 'Please enter a valid 10-digit mobile number.';
        _requestMessage = null;
        _connectionErrorType = null;
      });

      _mobileFocus.requestFocus();
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _validationMessage = null;
      _requestMessage = null;
    });

    try {
      final response = await ApiService.post('/api/v1/auth/otp', {
        'mobile': mobile,
      });

      if (!mounted) return;

      final statusCode = response.statusCode;
      final data = response.data;

      if (statusCode == 200 && data is Map && data['success'] == true) {
        setState(() {
          _loading = false;
          _connectionErrorType = null;
        });

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OtpScreen(mobile: mobile)),
        );

        return;
      }

      String message = 'Unable to send OTP. Please try again.';

      if (data is Map && data['message'] != null) {
        message = data['message'].toString();
      }

      setState(() {
        _loading = false;
        _connectionErrorType = null;
        _requestMessage = message;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      if (_isNetworkError(error)) {
        _showConnectionError(ConnectionErrorType.noInternet);
      } else {
        _showConnectionError(ConnectionErrorType.serverDown);
      }
    }
  }

  Widget _buildBrand({required bool compact}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/leichil_logo.webp',
          height: compact ? 38 : 58,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 8),
        Image.asset(
          'assets/images/leichil_logo_text.webp',
          height: compact ? 20 : 27,
          fit: BoxFit.contain,
        ),
      ],
    );
  }

  Widget _buildInlineMessage(String message, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: TextStyle(color: color, fontSize: 13, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField() {
    final hasError = _validationMessage != null || _requestMessage != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MOBILE NUMBER',
          style: TextStyle(
            color: _muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 10),
        Focus(
          onKeyEvent: _handleFormKey,
          child: TextField(
            controller: _mobileController,
            focusNode: _mobileFocus,
            readOnly: true,
            showCursor: false,
            keyboardType: TextInputType.none,
            maxLength: 10,
            autofocus: false,
            onTap: () => _mobileFocus.requestFocus(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: 'Enter your mobile number',
              hintStyle: const TextStyle(
                color: Color(0xFF666A73),
                fontSize: 16,
                letterSpacing: 0,
              ),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 16, right: 12),
                child: Icon(
                  Icons.phone_iphone_rounded,
                  color: _accent,
                  size: 23,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 54,
                minHeight: 54,
              ),
              filled: true,
              fillColor: const Color(0xFF08090B),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF292C32)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: hasError
                      ? Colors.redAccent.withValues(alpha: 0.8)
                      : const Color(0xFF292C32),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _accent, width: 1.8),
              ),
            ),
          ),
        ),
        if (_validationMessage != null) ...[
          const SizedBox(height: 8),
          _buildInlineMessage(
            _validationMessage!,
            Icons.info_outline_rounded,
            Colors.orangeAccent,
          ),
        ],
        if (_requestMessage != null) ...[
          const SizedBox(height: 8),
          _buildInlineMessage(
            _requestMessage!,
            Icons.error_outline_rounded,
            Colors.redAccent,
          ),
        ],
      ],
    );
  }

  Widget _buildOtpButton() {
    return Focus(
      onKeyEvent: _handleFormKey,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          focusNode: _buttonFocus,
          onPressed: _loading ? null : _getOtp,
          // style: ElevatedButton.styleFrom(
          //   backgroundColor: _accent,
          //   foregroundColor: const Color(0xFF001416),
          //   disabledBackgroundColor: _accent.withValues(alpha: 0.55),
          //   disabledForegroundColor: const Color(0xFF001416),
          //   elevation: 0,
          //   shape: RoundedRectangleBorder(
          //     borderRadius: BorderRadius.circular(16),
          //   ),
          // ),

          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return _accent.withValues(alpha: 0.55);
              }
              if (states.contains(WidgetState.focused)) {
                return Colors.white;
              }
              return _accent;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.focused)) {
                return const Color(0xFF0755B0);
              }
              return const Color(0xFF001416);
            }),
            elevation: const WidgetStatePropertyAll(0),
            padding: const WidgetStatePropertyAll(EdgeInsets.zero),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          child: _loading
              ? const SizedBox(
                  width: 23,
                  height: 23,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Color(0xFF001416),
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'CONTINUE',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(width: 10),
                    Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildKeypadButton({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    FocusNode? focusNode,
  }) {
    return SizedBox(
      height: 68,
      child: ElevatedButton(
        focusNode: focusNode,
        onPressed: _loading ? null : onPressed,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) return _accent;
            return const Color(0xFF191C21);
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return const Color(0xFF001416);
            }
            return Colors.white;
          }),
          elevation: const WidgetStatePropertyAll(0),
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFF30343B)),
            ),
          ),
        ),
        child: icon != null
            ? Icon(icon, size: 25)
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Widget _buildNumpad() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 350),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF24262C)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'NUMPAD',
            style: TextStyle(
              color: _muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 18),
          Focus(
            onKeyEvent: _handleKeypadKey,
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.18,
              children: [
                for (final digit in const [
                  '1',
                  '2',
                  '3',
                  '4',
                  '5',
                  '6',
                  '7',
                  '8',
                  '9',
                ])
                  _buildKeypadButton(
                    label: digit,
                    focusNode:
                        _keypadFocusNodes[const [
                          '1',
                          '2',
                          '3',
                          '4',
                          '5',
                          '6',
                          '7',
                          '8',
                          '9',
                        ].indexOf(digit)],
                    onPressed: () => _addDigit(digit),
                  ),
                _buildKeypadButton(
                  label: '⌫',
                  focusNode: _keypadFocusNodes[9],
                  icon: Icons.backspace_outlined,
                  onPressed: _deleteDigit,
                ),
                _buildKeypadButton(
                  label: '0',
                  focusNode: _keypadFocusNodes[10],
                  onPressed: () => _addDigit('0'),
                ),
                _buildKeypadButton(
                  label: 'C',
                  focusNode: _keypadFocusNodes[11],
                  icon: Icons.close_rounded,
                  onPressed: _clearNumber,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'BACKSPACE                         CLEAR',
            style: TextStyle(color: _muted, fontSize: 9, letterSpacing: 0.8),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm({required double availableHeight}) {
    final compact = availableHeight < 650;

    return Center(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1150),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // LEFT SIDE: LOGIN FORM
              Expanded(
                flex: 5,
                child: Container(
                  padding: EdgeInsets.all(compact ? 22 : 32),
                  decoration: BoxDecoration(
                    color: _panel,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFF24262C)),
                    boxShadow: [
                      BoxShadow(
                        color: _accent.withValues(alpha: 0.035),
                        blurRadius: 50,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildBrand(compact: compact),
                      SizedBox(height: compact ? 14 : 28),
                      Text(
                        'Welcome back.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 25 : 31,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sign in to continue watching on Leichil TV.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _muted,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: compact ? 18 : 28),
                      _buildTextField(),
                      SizedBox(height: compact ? 14 : 22),
                      _buildOtpButton(),
                      const SizedBox(height: 14),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            color: _muted,
                            size: 15,
                          ),
                          SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              'We’ll send a one-time code to your phone.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _muted,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: compact ? 24 : 42),
              // RIGHT SIDE: NUMERIC KEYPAD
              Expanded(flex: 4, child: Center(child: _buildNumpad())),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned(
            top: -180,
            right: -140,
            child: IgnorePointer(
              child: Container(
                width: 420,
                height: 420,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _accent.withValues(alpha: 0.09),
                      _accent.withValues(alpha: 0.025),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (_connectionErrorType != null) {
                  return ConnectionErrorScreen(
                    type: _connectionErrorType!,
                    isRetrying: _loading,
                    onReload: _getOtp,
                  );
                }

                return _buildLoginForm(availableHeight: constraints.maxHeight);
              },
            ),
          ),
        ],
      ),
    );
  }
}
