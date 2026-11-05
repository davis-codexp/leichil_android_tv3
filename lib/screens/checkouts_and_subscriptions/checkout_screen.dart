import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key, required this.title, this.posterUrl,
    this.moviePrice = 69, this.subscriptionPrice = 49,
    this.subscriptionDiscount = 49, this.onPay, this.onBack});

  final String title;
  final String? posterUrl;
  final int moviePrice, subscriptionPrice, subscriptionDiscount;
  final VoidCallback? onPay, onBack;
  int get total => moviePrice + subscriptionPrice - subscriptionDiscount;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0B1118),
    body: SafeArea(child: LayoutBuilder(builder: (context, c) {
      final s = (c.maxWidth / 1920).clamp(.7, 1.15);
      return Stack(children: [
        const _Glow(),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 76 * s, vertical: 32 * s),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _Back(scale: s, onPressed: onBack ?? () => Navigator.of(context).maybePop()),
              const Spacer(),
              const _Brand(),
              const Spacer(),
              Container(padding: EdgeInsets.symmetric(horizontal: 13 * s, vertical: 9 * s),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8 * s),
                  border: Border.all(color: Colors.green.withValues(alpha: .25))),
                child: Row(children: [
                  Icon(Icons.lock, color: Colors.green.shade300, size: 15 * s),
                  SizedBox(width: 7 * s),
                  Text('SECURE CHECKOUT', style: TextStyle(color: Colors.green.shade300,
                    fontSize: 11 * s, fontWeight: FontWeight.w900, letterSpacing: .8)),
                ])),
            ]),
            SizedBox(height: 30 * s),
            Text('Checkout', style: TextStyle(color: Colors.white,
              fontSize: 42 * s, fontWeight: FontWeight.w900)),
            SizedBox(height: 8 * s),
            Text('Review your purchase and complete your payment.',
              style: TextStyle(color: Colors.white60, fontSize: 18 * s)),
            const Spacer(),
            Row(children: [
              Expanded(flex: 6, child: _MovieCard(title: title, posterUrl: posterUrl, scale: s)),
              SizedBox(width: 30 * s),
              Expanded(flex: 5, child: _Summary(scale: s, movie: moviePrice,
                subscription: subscriptionPrice, discount: subscriptionDiscount,
                total: total, onPay: onPay)),
            ]),
            const Spacer(),
            Center(child: Text('Your payment is securely processed.',
              style: TextStyle(color: Colors.white38, fontSize: 12 * s))),
          ]),
        ),
      ]);
    })),
  );
}

class _Brand extends StatelessWidget {
  const _Brand();
  @override
  Widget build(BuildContext context) => const Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.play_circle_fill_rounded, color: Color(0xFF19A9D3), size: 29),
    SizedBox(width: 9),
    Text('LEICHIL', style: TextStyle(color: Colors.white, fontSize: 19,
      fontWeight: FontWeight.w900, letterSpacing: 1.3)),
    Text(' TV', style: TextStyle(color: Colors.white70, fontSize: 19,
      fontWeight: FontWeight.w300, letterSpacing: 1.3)),
  ]);
}

class _Back extends StatefulWidget {
  const _Back({required this.scale, required this.onPressed});
  final double scale;
  final VoidCallback onPressed;
  @override
  State<_Back> createState() => _BackState();
}
class _BackState extends State<_Back> {
  bool focused = false;
  @override
  Widget build(BuildContext context) => Focus(
    autofocus: true, onFocusChange: (v) => setState(() => focused = v),
    onKeyEvent: (_, e) {
      if (e is KeyDownEvent && (e.logicalKey == LogicalKeyboardKey.select ||
          e.logicalKey == LogicalKeyboardKey.enter ||
          e.logicalKey == LogicalKeyboardKey.gameButtonA)) {
        widget.onPressed(); return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    },
    child: GestureDetector(onTap: widget.onPressed,
      child: AnimatedContainer(duration: const Duration(milliseconds: 130),
        padding: EdgeInsets.all(12 * widget.scale),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(9 * widget.scale),
          border: Border.all(color: focused ? const Color(0xFF19A9D3) : Colors.white12,
            width: focused ? 2.5 : 1)),
        child: Icon(Icons.arrow_back, color: Colors.white, size: 23 * widget.scale))),
  );
}

class _MovieCard extends StatelessWidget {
  const _MovieCard({required this.title, required this.posterUrl, required this.scale});
  final String title;
  final String? posterUrl;
  final double scale;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(22 * scale),
    decoration: BoxDecoration(color: const Color(0xFF111C27),
      borderRadius: BorderRadius.circular(17 * scale),
      border: Border.all(color: Colors.white.withValues(alpha: .1)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .22),
        blurRadius: 24 * scale, offset: Offset(0, 12 * scale))]),
    child: Row(children: [
      _Poster(url: posterUrl, scale: scale),
      SizedBox(width: 24 * scale),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 5 * scale),
            decoration: BoxDecoration(color: const Color(0xFF19A9D3).withValues(alpha: .13),
              borderRadius: BorderRadius.circular(5 * scale)),
            child: Text('MOVIE', style: TextStyle(color: const Color(0xFF19A9D3),
              fontSize: 10 * scale, fontWeight: FontWeight.w900, letterSpacing: 1))),
          SizedBox(height: 13 * scale),
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white, fontSize: 27 * scale,
              fontWeight: FontWeight.w900, height: 1.15)),
          SizedBox(height: 12 * scale),
          Row(children: [
            Icon(Icons.play_circle_outline, color: Colors.white54, size: 18 * scale),
            SizedBox(width: 8 * scale),
            Expanded(child: Text('Instant access after payment.\n'
              '1 Month Basic Subscription Added.',
              style: TextStyle(color: Colors.white60, fontSize: 14 * scale, height: 1.45))),
          ]),
        ])),
    ]),
  );
}

class _Poster extends StatelessWidget {
  const _Poster({required this.url, required this.scale});
  final String? url;
  final double scale;
  @override
  Widget build(BuildContext context) {
    final u = url?.trim() ?? '';
    return Container(width: 150 * scale, height: 218 * scale,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12 * scale),
        border: Border.all(color: Colors.white24)),
      child: ClipRRect(borderRadius: BorderRadius.circular(11 * scale),
        child: u.isEmpty
          ? Container(color: const Color(0xFF1B2935),
              child: Icon(Icons.movie_outlined, color: Colors.white38, size: 48 * scale))
          : Image.network(u, fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(color: const Color(0xFF1B2935),
                child: Icon(Icons.movie_outlined, color: Colors.white38, size: 48 * scale)))));
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.scale, required this.movie, required this.subscription,
    required this.discount, required this.total, this.onPay});
  final double scale;
  final int movie, subscription, discount, total;
  final VoidCallback? onPay;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(27 * scale),
    decoration: BoxDecoration(color: const Color(0xFF111C27),
      borderRadius: BorderRadius.circular(17 * scale),
      border: Border.all(color: Colors.white.withValues(alpha: .1))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.receipt_long, color: Colors.white70, size: 21 * scale),
        SizedBox(width: 10 * scale),
        Text('Order Summary', style: TextStyle(color: Colors.white,
          fontSize: 21 * scale, fontWeight: FontWeight.w900)),
      ]),
      SizedBox(height: 26 * scale),
      _PriceRow('Movie purchase', '₹$movie', scale),
      SizedBox(height: 18 * scale),
      _PriceRow('1 Month Basic Subscription', '₹$subscription', scale),
      SizedBox(height: 18 * scale),
      _PriceRow('Subscription discount', '-₹$discount', scale, green: true),
      Padding(padding: EdgeInsets.symmetric(vertical: 22 * scale),
        child: const Divider(color: Color(0x24FFFFFF), height: 1)),
      Row(children: [
        Expanded(child: Text('TOTAL PAYABLE', style: TextStyle(color: Colors.white,
          fontSize: 17 * scale, fontWeight: FontWeight.w900))),
        Text('₹$total', style: TextStyle(color: const Color(0xFF19A9D3),
          fontSize: 35 * scale, fontWeight: FontWeight.w900)),
      ]),
      SizedBox(height: 26 * scale),
      _PayButton(scale: scale, total: total, onPressed: onPay),
    ]),
  );
}

class _PriceRow extends StatelessWidget {
  const _PriceRow(this.label, this.amount, this.scale, {this.green = false});
  final String label, amount;
  final double scale;
  final bool green;
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(label, style: TextStyle(color: Colors.white60, fontSize: 14 * scale))),
    Text(amount, style: TextStyle(color: green ? Colors.green.shade300 : Colors.white,
      fontSize: 15 * scale, fontWeight: FontWeight.w800)),
  ]);
}

class _PayButton extends StatefulWidget {
  const _PayButton({required this.scale, required this.total, this.onPressed});
  final double scale;
  final int total;
  final VoidCallback? onPressed;
  @override
  State<_PayButton> createState() => _PayButtonState();
}
class _PayButtonState extends State<_PayButton> {
  bool focused = false;
  @override
  Widget build(BuildContext context) => Focus(
    onFocusChange: (v) => setState(() => focused = v),
    onKeyEvent: (_, e) {
      if (e is KeyDownEvent && (e.logicalKey == LogicalKeyboardKey.select ||
          e.logicalKey == LogicalKeyboardKey.enter ||
          e.logicalKey == LogicalKeyboardKey.gameButtonA)) {
        widget.onPressed?.call(); return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    },
    child: GestureDetector(onTap: widget.onPressed,
      child: AnimatedContainer(duration: const Duration(milliseconds: 140),
        width: double.infinity, height: 62 * widget.scale,
        decoration: BoxDecoration(color: const Color(0xFF19A9D3),
          borderRadius: BorderRadius.circular(10 * widget.scale),
          border: Border.all(color: focused ? Colors.white : Colors.transparent,
            width: focused ? 2.5 : 0),
          boxShadow: [BoxShadow(color: const Color(0xFF19A9D3)
            .withValues(alpha: focused ? .35 : .18), blurRadius: focused ? 25 : 15)]),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.lock, color: const Color(0xFF06202A), size: 19 * widget.scale),
          SizedBox(width: 10 * widget.scale),
          Text('PROCEED TO PAY ₹${widget.total}', style: TextStyle(
            color: const Color(0xFF06202A), fontSize: 15 * widget.scale,
            fontWeight: FontWeight.w900, letterSpacing: .5)),
          SizedBox(width: 9 * widget.scale),
          Icon(Icons.arrow_forward, color: const Color(0xFF06202A), size: 20 * widget.scale),
        ]))),
  );
}

class _Glow extends StatelessWidget {
  const _Glow();
  @override
  Widget build(BuildContext context) => const IgnorePointer(child: Stack(children: [
    Positioned(top: -180, right: -140, child: _Orb()),
    Positioned(bottom: -250, left: -180, child: _Orb()),
  ]));
}
class _Orb extends StatelessWidget {
  const _Orb();
  @override
  Widget build(BuildContext context) => Container(width: 540, height: 540,
    decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [
      const Color(0xFF19A9D3).withValues(alpha: .13),
      const Color(0xFF19A9D3).withValues(alpha: 0),
    ])));
}
