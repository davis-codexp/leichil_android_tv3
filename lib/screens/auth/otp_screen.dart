import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../services/auth_storage.dart';
import '../../widgets/common/connection_error_screen.dart';
import '../shell/main_shell.dart';

class OtpScreen extends StatefulWidget {
  final String mobile;

  const OtpScreen({super.key, required this.mobile});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();

  final FocusNode _otpFocus = FocusNode();

  final FocusNode _verifyFocus = FocusNode();

  final FocusNode _resendFocus = FocusNode();
  final List<FocusNode> _keypadFocusNodes = List.generate(
    12,
    (index) => FocusNode(debugLabel: 'OtpKeypad${index + 1}'),
  );

  Timer? _resendTimer;

  bool _loading = false;

  bool _resending = false;

  int _remainingSeconds = 30;

  ConnectionErrorType? _connectionErrorType;

  String? _validationMessage;

  String? _resendMessage;

  static const Color _background = Color(0xFF000000);

  static const Color _panel = Color(0xFF101114);

  static const Color _accent = Color(0xFF36C8D5);

  static const Color _muted = Color(0xFF969BA5);

  void _restoreVerifyFocus() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;

    if (_verifyFocus.canRequestFocus) {
      _verifyFocus.requestFocus();
    }
  });
}

  @override
  void initState() {
    super.initState();

    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _keypadFocusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();

    _otpController.dispose();

    _otpFocus.dispose();

    _verifyFocus.dispose();

    _resendFocus.dispose();
    for (final node in _keypadFocusNodes) {
      node.dispose();
    }

    super.dispose();
  }

  String get _formattedTime {
  final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
  final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');

  return '$minutes:$seconds';
}

  void _startResendTimer() {
  _resendTimer?.cancel();

  setState(() {
    _remainingSeconds = 30;
  });

  _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
    if (!mounted) {
      timer.cancel();
      return;
    }

    if (_remainingSeconds > 0) {
      setState(() {
        _remainingSeconds--;
      });
    } else {
      timer.cancel();
    }
  });
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

    // setState(() {
    //   _connectionErrorType = type;

    //   _validationMessage = null;

    //   _resendMessage = null;
    // });

    setState(() {
  _loading = true;
  _validationMessage = null;
  _resendMessage = null;
});

_restoreVerifyFocus();
  }

  void _showValidationMessage(String message) {
    if (!mounted) return;

    setState(() {
      _validationMessage = message;
    });
  }

  Future<void> _resendOtp() async {
    if (_resending || _loading || _remainingSeconds > 0) {
      return;
    }

    setState(() {
      _resending = true;

      _validationMessage = null;

      _resendMessage = null;
    });

    try {
      final response = await ApiService.post('/api/v1/auth/otp', {
        'mobile': widget.mobile,
      });

      if (!mounted) return;

      final statusCode = response.statusCode;

      final data = response.data;

      if (statusCode == 200 && data is Map && data['success'] == true) {
        setState(() {
          _resending = false;

          _connectionErrorType = null;

          _resendMessage = 'A new OTP has been sent.';
        });

        _startResendTimer();

        return;
      }

      String message = 'Unable to resend OTP. Please try again.';

      if (data is Map && data['message'] != null) {
        message = data['message'].toString();
      }

      setState(() {
        _resending = false;

        _resendMessage = message;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _resending = false;
      });

      _showConnectionError(
        _isNetworkError(error)
            ? ConnectionErrorType.noInternet
            : ConnectionErrorType.serverDown,
      );
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();

    if (_loading || _resending) return;

    if (!RegExp(r'^[0-9]{4}$').hasMatch(otp)) {
      _showValidationMessage('Please enter the 4-digit OTP.');

      _otpFocus.requestFocus();

      return;
    }

    setState(() {
      _loading = true;

      _validationMessage = null;

      _resendMessage = null;
    });

    try {
      final otpNumber = int.tryParse(otp);

      if (otpNumber == null) {
        setState(() {
          _loading = false;

          _connectionErrorType = null;

          _restoreVerifyFocus();

          _validationMessage = 'Invalid OTP.';
        });

        return;
      }

      final response = await ApiService.post('/api/v1/auth/otp/verify', {
        'mobile': widget.mobile,

        'otp': otpNumber,
      });

      if (!mounted) return;

      final statusCode = response.statusCode;

      final data = response.data;

      if (statusCode == 200 && data is Map && data['success'] == true) {
        final result = data['result'];

        if (result is Map && result['token'] != null) {
          try {
            final userId = result['id']?.toString() ?? '';
            final userName = result['fullName']?.toString().trim() ?? '';
            final userMobile =
                result['mobile']?.toString().trim() ?? widget.mobile;
            final authToken = result['token']?.toString() ?? '';

            if (userId.isEmpty || authToken.isEmpty) {
              if (!mounted) return;

              setState(() {
                _loading = false;
                _connectionErrorType = null;
                _validationMessage =
                    'Login response is missing the user ID or token.';
              });

              return;
            }

            await AuthStorage.saveData(
              id: userId,
              name: userName,
              mobile: userMobile,
              token: authToken,
            );
          } catch (error) {
            // debugPrint('AUTH STORAGE ERROR: $error');

            if (!mounted) return;

            setState(() {
              _loading = false;
              _connectionErrorType = ConnectionErrorType.general;
              _validationMessage = null;
            });

            return;
          }

          if (!mounted) return;

          setState(() {
            _loading = false;

            _connectionErrorType = null;
          });

          Navigator.pushAndRemoveUntil(
            context,

            MaterialPageRoute(builder: (_) => const MainShell()),

            (route) => false,
          );

          return;
        }

        setState(() {
          _loading = false;

          _connectionErrorType = null;

          _validationMessage =
              'Login succeeded, but no token was returned. Please try again.';
        });

        return;
      }

      String message = 'Unable to verify OTP. Please try again.';

      if (data is Map && data['message'] != null) {
        message = data['message'].toString();
      }

      setState(() {
        _loading = false;

        _connectionErrorType = null;

        _validationMessage = message;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showConnectionError(
        _isNetworkError(error)
            ? ConnectionErrorType.noInternet
            : ConnectionErrorType.serverDown,
      );
    }
  }



  void _addOtpDigit(String digit) {
    if (_otpController.text.length >= 4 || _loading || _resending) return;
    setState(() {
      _otpController.text += digit;
      _otpController.selection = TextSelection.collapsed(
        offset: _otpController.text.length,
      );
      _validationMessage = null;
    });
  }

  void _deleteOtpDigit() {
    if (_otpController.text.isEmpty || _loading || _resending) return;
    setState(() {
      _otpController.text = _otpController.text.substring(
        0,
        _otpController.text.length - 1,
      );
      _otpController.selection = TextSelection.collapsed(
        offset: _otpController.text.length,
      );
      _validationMessage = null;
    });
  }

  void _clearOtp() {
    if (_loading || _resending) return;
    setState(() {
      _otpController.clear();
      _validationMessage = null;
    });
  }

  KeyEventResult _handleKeypadKey(FocusNode node, KeyEvent event) {

    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final index = _keypadFocusNodes.indexWhere((item) => item.hasFocus);
    if (index < 0) return KeyEventResult.ignored;

    final key = event.logicalKey;
    int? next;

    if (key == LogicalKeyboardKey.arrowUp) {
      if (index >= 3) {
        next = index - 3;
      } else {
        _otpFocus.requestFocus();
        return KeyEventResult.handled;
      }
    } else if (key == LogicalKeyboardKey.arrowDown) {
      if (index <= 8) {
        next = index + 3;
      } else {
        _verifyFocus.requestFocus();
        return KeyEventResult.handled;
      }
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      if (index % 3 == 0) {
        _verifyFocus.requestFocus();
        return KeyEventResult.handled;
      }
      next = index - 1;
    } else if (key == LogicalKeyboardKey.arrowRight) {
      if (index % 3 == 2) return KeyEventResult.handled;
      next = index + 1;
    } else {
      return KeyEventResult.ignored;
    }

    if (next != null && next >= 0 && next < _keypadFocusNodes.length) {
      _keypadFocusNodes[next].requestFocus();
    }
    return KeyEventResult.handled;
  }


  KeyEventResult _handleFormKey(FocusNode node, KeyEvent event) {
  if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
    return KeyEventResult.ignored;
  }

  final key = event.logicalKey;

  if (key == LogicalKeyboardKey.arrowDown && _otpFocus.hasFocus) {
    _verifyFocus.requestFocus();
    return KeyEventResult.handled;
  }

  if (key == LogicalKeyboardKey.arrowUp && _verifyFocus.hasFocus) {
    _otpFocus.requestFocus();
    return KeyEventResult.handled;
  }

  if (_verifyFocus.hasFocus &&
      (key == LogicalKeyboardKey.arrowDown ||
          key == LogicalKeyboardKey.arrowLeft ||
          key == LogicalKeyboardKey.arrowRight)) {
    return KeyEventResult.handled;
  }

  if (key == LogicalKeyboardKey.arrowRight && _otpFocus.hasFocus) {
    _keypadFocusNodes[0].requestFocus();
    return KeyEventResult.handled;
  }

  return KeyEventResult.ignored;
}

  Widget _buildKeypadButton({
    required String label,
    required FocusNode focusNode,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    return SizedBox(
      height: 76,
      child: ElevatedButton(
        focusNode: focusNode,
        onPressed: (_loading || _resending) ? null : onPressed,
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

  Widget _buildOtpKeypad() {
    const digits = ['1','2','3','4','5','6','7','8','9'];
    return Container(
      width: 350,
      padding: const EdgeInsets.all(24),
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
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.12,
              children: [
                for (var i = 0; i < digits.length; i++)
                  _buildKeypadButton(
                    label: digits[i],
                    focusNode: _keypadFocusNodes[i],
                    onPressed: () => _addOtpDigit(digits[i]),
                  ),
                _buildKeypadButton(
                  label: '⌫',
                  focusNode: _keypadFocusNodes[9],
                  onPressed: _deleteOtpDigit,
                ),
                _buildKeypadButton(
                  label: '0',
                  focusNode: _keypadFocusNodes[10],
                  onPressed: () => _addOtpDigit('0'),
                ),
                _buildKeypadButton(
                  label: 'C',
                  focusNode: _keypadFocusNodes[11],
                  onPressed: _clearOtp,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'BACKSPACE       CLEAR',
            style: TextStyle(color: _muted, fontSize: 10, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        const Text(
          'VERIFICATION CODE',

          style: TextStyle(
            color: _muted,

            fontSize: 12,

            fontWeight: FontWeight.w700,

            letterSpacing: 1.8,
          ),
        ),

        const SizedBox(height: 12),

        Focus(
          onKeyEvent: _handleFormKey,
          child: TextField(
          controller: _otpController,
          focusNode: _otpFocus,
          readOnly: true,
          showCursor: false,
          keyboardType: TextInputType.number,

          textInputAction: TextInputAction.done,

          maxLength: 4,

          inputFormatters: [FilteringTextInputFormatter.digitsOnly],

          onTap: () => _otpFocus.requestFocus(),

          onChanged: (_) {
            if (_validationMessage != null) {
              setState(() {
                _validationMessage = null;
              });
            }
          },

          onSubmitted: (_) => _verifyOtp(),

          textAlign: TextAlign.center,

          style: const TextStyle(
            color: Colors.white,

            fontSize: 29,

            fontWeight: FontWeight.w700,

            letterSpacing: 14,
          ),

          decoration: InputDecoration(
            counterText: '',

            hintText: '••••',

            hintStyle: const TextStyle(
              color: Color(0xFF565B64),

              fontSize: 28,

              letterSpacing: 12,
            ),

            filled: true,

            fillColor: const Color(0xFF08090B),

            contentPadding: const EdgeInsets.symmetric(
              vertical: 22,

              horizontal: 16,
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),

              borderSide: const BorderSide(color: Color(0xFF292C32)),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),

              borderSide: BorderSide(
                color: _validationMessage != null
                    ? Colors.redAccent
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

          _buildMessage(
            _validationMessage!,

            Colors.redAccent,

            Icons.error_outline_rounded,
          ),
        ],
      ],
    );
  }

  Widget _buildMessage(String message, Color color, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Icon(icon, color: color, size: 17),

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

  Widget _buildResendSection() {
    final canResend = _remainingSeconds == 0 && !_resending && !_loading;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            const Text(
              'Didn’t receive the code? ',

              style: TextStyle(color: _muted, fontSize: 13),
            ),

            if (_remainingSeconds > 0)
              Text(
                'Resend in $_formattedTime',

                style: const TextStyle(
                  color: _accent,

                  fontSize: 13,

                  fontWeight: FontWeight.w700,

                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              )
            else
              TextButton(
                focusNode: _resendFocus,

                onPressed: canResend ? _resendOtp : null,

                style: TextButton.styleFrom(
                  foregroundColor: _accent,

                  disabledForegroundColor: _muted,

                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,

                    vertical: 4,
                  ),

                  minimumSize: Size.zero,

                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),

                child: _resending
                    ? const SizedBox(
                        width: 16,

                        height: 16,

                        child: CircularProgressIndicator(
                          strokeWidth: 2,

                          color: _accent,
                        ),
                      )
                    : const Text(
                        'Resend OTP',

                        style: TextStyle(
                          fontSize: 13,

                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
          ],
        ),

        if (_resendMessage != null) ...[
          const SizedBox(height: 10),

          _buildMessage(
            _resendMessage!,

            _resendMessage!.contains('sent') ? _accent : Colors.orangeAccent,

            _resendMessage!.contains('sent')
                ? Icons.check_circle_outline_rounded
                : Icons.info_outline_rounded,
          ),
        ],
      ],
    );
  }

  // Widget _buildVerifyButton() {
  //   return Focus(
  //     onKeyEvent: _handleFormKey,
  //     child: SizedBox(
  //     width: double.infinity,

  //     height: 58,

  //     child: ElevatedButton(
  //       focusNode: _verifyFocus,

  //       onPressed: (_loading || _resending) ? null : _verifyOtp,

  //       style: ElevatedButton.styleFrom(
  //         backgroundColor: _accent,

  //         foregroundColor: const Color(0xFF001416),

  //         disabledBackgroundColor: _accent.withValues(alpha: 0.5),

  //         disabledForegroundColor: const Color(0xFF001416),

  //         elevation: 0,

  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(16),
  //         ),
  //       ),

  //       child: _loading
  //           ? const SizedBox(
  //               height: 23,

  //               width: 23,

  //               child: CircularProgressIndicator(
  //                 strokeWidth: 2.4,

  //                 color: Color(0xFF001416),
  //               ),
  //             )
  //           : const Row(
  //               mainAxisAlignment: MainAxisAlignment.center,

  //               children: [
  //                 Text(
  //                   'VERIFY & CONTINUE',

  //                   style: TextStyle(
  //                     fontSize: 14,

  //                     fontWeight: FontWeight.w800,

  //                     letterSpacing: 1.2,
  //                   ),
  //                 ),

  //                 SizedBox(width: 10),

  //                 Icon(Icons.arrow_forward_rounded, size: 20),
  //               ],
  //             ),
  //     ),
  //     ),
  //   );
  // }

  Widget _buildVerifyButton() {
  return Focus(
    onKeyEvent: _handleFormKey,
    child: SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        focusNode: _verifyFocus,

        // Keep enabled so it retains focus while loading.
        // _verifyOtp() already prevents duplicate requests.
        onPressed: _verifyOtp,

        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
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
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),

        child: _loading
            ? const SizedBox(
                height: 23,
                width: 23,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Color(0xFF0755B0),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'VERIFY & CONTINUE',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
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

  Widget _buildOtpForm(
    BoxConstraints constraints, {
    required bool keyboardVisible,
  }) {
    final compact = constraints.maxHeight < 650;

    return Center(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1150),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  padding: EdgeInsets.all(compact ? 20 : 30),
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
                      _buildBrandCompact(),
                      SizedBox(height: compact ? 12 : 20),
                      Text(
                        'One last step.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 24 : 30,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.7,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Enter the 4-digit code sent to',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _muted,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.phone_iphone_rounded,
                            color: _accent,
                            size: 17,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '+91 ${widget.mobile}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: compact ? 14 : 22),
                      _buildOtpField(),
                      SizedBox(height: compact ? 12 : 18),
                      _buildVerifyButton(),
                      SizedBox(height: compact ? 10 : 16),
                      _buildResendSection(),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton.icon(
                          onPressed: (_loading || _resending)
                              ? null
                              : () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded, size: 17),
                          label: const Text(
                            'Change mobile number',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: _muted,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 48),
              Expanded(
                flex: 4,
                child: Center(child: _buildOtpKeypad()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandCompact() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/leichil_logo.webp',
          height: 36,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 5),
        Image.asset(
          'assets/images/leichil_logo_text.webp',
          height: 18,
          fit: BoxFit.contain,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      resizeToAvoidBottomInset: true,
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

                    isRetrying: _loading || _resending,

                    onReload: _resending ? _resendOtp : _verifyOtp,
                  );
                }

                return _buildOtpForm(
                  constraints,
                  keyboardVisible: false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}