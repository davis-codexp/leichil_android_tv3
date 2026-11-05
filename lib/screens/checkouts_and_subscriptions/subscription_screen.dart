import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key, this.onSubscribe, this.onBack});

  final VoidCallback? onSubscribe;
  final VoidCallback? onBack;

  static const _bg = Color(0xFF0B1118);
  static const _cyan = Color(0xFF19A9D3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, c) {
          final s = (c.maxWidth / 1920).clamp(.7, 1.15);
          return Stack(children: [
            const _Glow(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 76 * s, vertical: 32 * s),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  _FocusAction(
                    autofocus: true, scale: s,
                    onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.arrow_back, size: 22 * s),
                      SizedBox(width: 8 * s),
                      Text('BACK', style: TextStyle(fontSize: 13 * s)),
                    ]),
                  ),
                  const Spacer(),
                  const _Brand(),
                ]),
                SizedBox(height: 28 * s),
                Text('Subscription', style: TextStyle(
                  color: Colors.white, fontSize: 42 * s, fontWeight: FontWeight.w900)),
                SizedBox(height: 8 * s),
                Text('Get unlimited access to movies and series on Leichil TV.',
                  style: TextStyle(color: Colors.white60, fontSize: 18 * s)),
                const Spacer(),
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Expanded(flex: 5, child: Padding(
                    padding: EdgeInsets.only(right: 44 * s),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Why subscribe to Leichil TV?', style: TextStyle(
                        color: Colors.white, fontSize: 24 * s, fontWeight: FontWeight.w800)),
                      SizedBox(height: 26 * s),
                      _Benefit(Icons.movie_creation_outlined, 'Unlimited Movies',
                        'Watch unlimited movies anytime, except Premium Content.', s),
                      SizedBox(height: 20 * s),
                      _Benefit(Icons.card_giftcard_rounded, 'Special Offer',
                        'Buy any Premium Content and enjoy 1 month Basic Subscription absolutely FREE!', s),
                      SizedBox(height: 20 * s),
                      _Benefit(Icons.block_rounded, 'Ad-free viewing',
                        'Enjoy Leichil TV content without annoying ad interruptions.', s),
                      SizedBox(height: 20 * s),
                      _Benefit(Icons.hd_rounded, 'HD Streaming',
                        'Enjoy crystal-clear streaming quality.', s),
                    ]),
                  )),
                  Expanded(flex: 4, child: _Offer(scale: s, onSubscribe: onSubscribe)),
                ]),
                const Spacer(),
                Center(child: Text('Press Back to return to the selected movie or show.',
                  style: TextStyle(color: Colors.white38, fontSize: 12 * s))),
              ]),
            ),
          ]);
        }),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();
  @override
  Widget build(BuildContext context) => const Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.play_circle_fill_rounded, color: Color(0xFF19A9D3), size: 30),
    SizedBox(width: 9),
    Text('LEICHIL', style: TextStyle(color: Colors.white, fontSize: 19,
      fontWeight: FontWeight.w900, letterSpacing: 1.3)),
    Text(' TV', style: TextStyle(color: Colors.white70, fontSize: 19,
      fontWeight: FontWeight.w300, letterSpacing: 1.3)),
  ]);
}

class _Benefit extends StatelessWidget {
  const _Benefit(this.icon, this.title, this.subtitle, this.scale);
  final IconData icon;
  final String title, subtitle;
  final double scale;
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 52 * scale, height: 52 * scale,
      decoration: BoxDecoration(color: const Color(0xFF19A9D3).withValues(alpha: .12),
        borderRadius: BorderRadius.circular(12 * scale)),
      child: Icon(icon, color: const Color(0xFF19A9D3), size: 25 * scale)),
    SizedBox(width: 16 * scale),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: Colors.white, fontSize: 18 * scale,
        fontWeight: FontWeight.w800)),
      SizedBox(height: 4 * scale),
      Text(subtitle, style: TextStyle(color: Colors.white60, fontSize: 13 * scale, height: 1.35)),
    ])),
  ]);
}

class _Offer extends StatelessWidget {
  const _Offer({required this.scale, this.onSubscribe});
  final double scale;
  final VoidCallback? onSubscribe;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(32 * scale),
    decoration: BoxDecoration(
      color: const Color(0xFF111C27),
      borderRadius: BorderRadius.circular(18 * scale),
      border: Border.all(color: const Color(0xFF19A9D3).withValues(alpha: .65), width: 1.5),
      boxShadow: [BoxShadow(color: const Color(0xFF19A9D3).withValues(alpha: .13),
        blurRadius: 34 * scale, spreadRadius: 2 * scale)],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.workspace_premium_rounded, color: const Color(0xFF19A9D3), size: 34 * scale),
        SizedBox(width: 13 * scale),
        Expanded(child: Text('Leichil TV Subscription', style: TextStyle(
          color: Colors.white, fontSize: 21 * scale, fontWeight: FontWeight.w800))),
      ]),
      SizedBox(height: 24 * scale),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('₹49', style: TextStyle(color: Colors.white, fontSize: 64 * scale,
          fontWeight: FontWeight.w900, height: 1)),
        Padding(padding: EdgeInsets.only(left: 10 * scale, bottom: 8 * scale),
          child: Text('/ month', style: TextStyle(color: Colors.white70, fontSize: 20 * scale))),
      ]),
      SizedBox(height: 28 * scale),
      SizedBox(width: double.infinity, height: 62 * scale,
        child: _FocusAction(scale: scale, filled: true, onPressed: onSubscribe,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.play_arrow_rounded, size: 24 * scale),
            SizedBox(width: 8 * scale),
            Text('SUBSCRIBE NOW', style: TextStyle(fontSize: 17 * scale,
              fontWeight: FontWeight.w900, letterSpacing: .8)),
          ]))),
    ]),
  );
}

class _FocusAction extends StatefulWidget {
  const _FocusAction({required this.child, required this.scale, this.onPressed,
    this.autofocus = false, this.filled = false});
  final Widget child;
  final double scale;
  final VoidCallback? onPressed;
  final bool autofocus, filled;
  @override
  State<_FocusAction> createState() => _FocusActionState();
}

class _FocusActionState extends State<_FocusAction> {
  bool focused = false;
  @override
  Widget build(BuildContext context) => Focus(
    autofocus: widget.autofocus,
    onFocusChange: (v) => setState(() => focused = v),
    onKeyEvent: (_, e) {
      if (e is KeyDownEvent && (e.logicalKey == LogicalKeyboardKey.select ||
          e.logicalKey == LogicalKeyboardKey.enter ||
          e.logicalKey == LogicalKeyboardKey.gameButtonA)) {
        widget.onPressed?.call();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    },
    child: GestureDetector(
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: EdgeInsets.symmetric(horizontal: 18 * widget.scale, vertical: 12 * widget.scale),
        decoration: BoxDecoration(
          color: widget.filled ? const Color(0xFF19A9D3) : Colors.white.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(9 * widget.scale),
          border: Border.all(color: focused ? Colors.white : Colors.white24,
            width: focused ? 2.5 : 1),
          boxShadow: focused ? [BoxShadow(
            color: const Color(0xFF19A9D3).withValues(alpha: .3), blurRadius: 20)] : null,
        ),
        child: DefaultTextStyle(
          style: TextStyle(color: widget.filled ? const Color(0xFF06202A) : Colors.white,
            fontWeight: FontWeight.w800),
          child: IconTheme(
            data: IconThemeData(color: widget.filled ? const Color(0xFF06202A) : Colors.white),
            child: widget.child)),
      ),
    ),
  );
}

class _Glow extends StatelessWidget {
  const _Glow();
  @override
  Widget build(BuildContext context) => const IgnorePointer(child: Stack(children: [
    Positioned(top: -180, right: -140, child: _GlowOrb(size: 520)),
    Positioned(bottom: -250, left: -180, child: _GlowOrb(size: 560)),
  ]));
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size});
  final double size;
  @override
  Widget build(BuildContext context) => Container(width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [
      const Color(0xFF19A9D3).withValues(alpha: .13),
      const Color(0xFF19A9D3).withValues(alpha: 0),
    ])));
}
