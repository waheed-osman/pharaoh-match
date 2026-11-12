import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// مشهد لعنة الفراعنة: تظهر المومياء من العتمة وتتقدم نحو اللاعب حتى تملأ الشاشة،
/// ثم تظهر لوحة الخسارة. يُعرض عند نفاد الحركات.
class MummyOverlay extends StatefulWidget {
  final VoidCallback onRetry;
  final VoidCallback onMenu;

  const MummyOverlay({super.key, required this.onRetry, required this.onMenu});

  @override
  State<MummyOverlay> createState() => _MummyOverlayState();
}

class _MummyOverlayState extends State<MummyOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _panel = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3600));
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _panel = true);
      }
    });
    HapticFeedback.mediumImpact();
    _c.forward();
    Future.delayed(const Duration(milliseconds: 3100), () {
      if (mounted) HapticFeedback.heavyImpact();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final v = _c.value;
        final dim = Curves.easeOut.transform((v / 0.2).clamp(0.0, 1.0).toDouble());
        final approach = Curves.easeInCubic.transform(((v - 0.12) / 0.78).clamp(0.0, 1.0).toDouble());
        final scale = 0.12 + approach * 1.0;
        final bob = math.sin(v * math.pi * 14);
        final t = ((v - 0.86) / 0.14).clamp(0.0, 1.0).toDouble();
        final flash = math.sin(t * math.pi) * 0.55;
        final shake = v > 0.86 ? math.sin(v * 220) * 10 * (1 - t) : 0.0;
        final glow = 0.3 + 0.7 * approach;

        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: Color.fromRGBO(5, 3, 12, 0.9 * dim)),
            Center(
              child: Transform.translate(
                offset: Offset(shake, bob * 5 - size.height * 0.08 * (1 - approach)),
                child: Transform.scale(
                  scale: scale,
                  child: SizedBox(
                    width: size.width * 0.9,
                    height: size.height * 0.62,
                    child: CustomPaint(painter: MummyPainter(glow: glow, sway: bob)),
                  ),
                ),
              ),
            ),
            IgnorePointer(child: ColoredBox(color: Colors.red.withOpacity(flash))),
            IgnorePointer(
              ignoring: !_panel,
              child: AnimatedOpacity(
                opacity: _panel ? 1 : 0,
                duration: const Duration(milliseconds: 450),
                child: _panelWidget(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _panelWidget() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
        decoration: BoxDecoration(
          color: const Color(0xEE1A0F05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Pal.gold, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'لعنة الفراعنة!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Pal.goldLight),
            ),
            const SizedBox(height: 10),
            const Text(
              'نفدت حركاتك، فاستيقظت المومياء وأنهت الجولة.\nجرّب مرة أخرى وأنقذ كنوز المعبد!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, height: 1.5, color: Pal.sand),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                FilledButton(onPressed: widget.onRetry, child: const Text('حاول مجدداً')),
                OutlinedButton(onPressed: widget.onMenu, child: const Text('القائمة')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// رسم المومياء بالكود: لفائف ضمادات، عينان متوهجتان، وذراعان ممدودتان نحو اللاعب.
class MummyPainter extends CustomPainter {
  final double glow; // 0..1 شدة توهج العينين
  final double sway; // -1..1 تأرجح الذراعين

  const MummyPainter({required this.glow, required this.sway});

  static const _wrap = Color(0xFFD8C79B);
  static const _wrapDark = Color(0xFF8F7C52);
  static const _wrapLight = Color(0xFFEBDDB8);
  static const _hole = Color(0xFF120A05);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.97), width: w * 0.7, height: h * 0.06),
      Paint()..color = Colors.black.withOpacity(0.5),
    );

    final armShift = sway * 0.03 * h;
    _arm(canvas, Offset(w * 0.30, h * 0.50), Offset(w * 0.07, h * 0.68 + armShift), w);
    _arm(canvas, Offset(w * 0.70, h * 0.50), Offset(w * 0.93, h * 0.68 - armShift), w);

    final torso = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.27, h * 0.42, w * 0.46, h * 0.52),
      topLeft: Radius.circular(w * 0.16),
      topRight: Radius.circular(w * 0.16),
      bottomLeft: Radius.circular(w * 0.05),
      bottomRight: Radius.circular(w * 0.05),
    );
    canvas.drawRRect(torso, Paint()..color = _wrap);
    canvas.save();
    canvas.clipRRect(torso);
    _bands(canvas, torso.outerRect, 13, 1.0);
    canvas.restore();
    canvas.drawRRect(torso, _outline(w * 0.008));

    final headRect = Rect.fromCenter(center: Offset(w * 0.5, h * 0.255), width: w * 0.36, height: h * 0.40);
    final head = Path()..addOval(headRect);
    canvas.drawPath(head, Paint()..color = _wrap);
    canvas.save();
    canvas.clipPath(head);
    _bands(canvas, headRect, 11, -1.0);
    canvas.restore();
    canvas.drawPath(head, _outline(w * 0.008));

    final gap = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.355, h * 0.215, w * 0.29, h * 0.08),
      Radius.circular(h * 0.03),
    );
    canvas.drawRRect(gap, Paint()..color = _hole);
    for (final x in const [0.43, 0.57]) {
      final center = Offset(w * x, h * 0.255);
      canvas.drawCircle(
        center,
        w * 0.04,
        Paint()
          ..color = const Color(0xFF7CFF6B).withOpacity(0.35 + 0.55 * glow)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.02 * glow + 0.5),
      );
      canvas.drawCircle(center, w * 0.022, Paint()..color = Color.lerp(const Color(0xFF3F8F36), const Color(0xFFEFFFB0), glow)!);
    }

    final mouth = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.44, h * 0.34, w * 0.12, h * 0.022),
      Radius.circular(h * 0.01),
    );
    canvas.drawRRect(mouth, Paint()..color = _hole);
    for (var i = 0; i < 5; i++) {
      final x = w * (0.455 + i * 0.022);
      canvas.drawLine(Offset(x, h * 0.335), Offset(x, h * 0.367), _strokeLine(w * 0.004, _wrapLight));
    }

    final tail1 = Path()
      ..moveTo(w * 0.64, h * 0.20)
      ..quadraticBezierTo(w * 0.82, h * 0.28, w * 0.74, h * 0.42);
    canvas.drawPath(tail1, _strokeLine(w * 0.022, _wrapLight));
    final tail2 = Path()
      ..moveTo(w * 0.38, h * 0.88)
      ..quadraticBezierTo(w * 0.30, h * 0.95, w * 0.34, h * 1.0);
    canvas.drawPath(tail2, _strokeLine(w * 0.02, _wrapLight));
  }

  Paint _outline(double width) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..color = Pal.ink;

  Paint _strokeLine(double width, Color color) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = width
    ..color = color;

  void _bands(Canvas canvas, Rect r, int count, double dir) {
    final gap = r.height / count;
    for (var i = 0; i < count; i++) {
      final y = r.top + i * gap;
      final jitter = ((i * 37) % 11) / 11 - 0.5;
      final slope = gap * (0.9 + jitter) * dir;
      canvas.drawLine(
        Offset(r.left - 10, y - slope),
        Offset(r.right + 10, y + slope),
        _strokeLine(gap * 0.38, i.isEven ? _wrapDark.withOpacity(0.55) : _wrapLight.withOpacity(0.6)),
      );
    }
  }

  void _arm(Canvas canvas, Offset from, Offset to, double w) {
    canvas.drawLine(from, to, _strokeLine(w * 0.115, Pal.ink));
    canvas.drawLine(from, to, _strokeLine(w * 0.10, _wrap));
    for (var i = 1; i < 5; i++) {
      final p = Offset.lerp(from, to, i / 5.2)!;
      final d = to - from;
      final n = Offset(-d.dy, d.dx) / d.distance;
      canvas.drawLine(p - n * (w * 0.05), p + n * (w * 0.05), _strokeLine(w * 0.012, _wrapDark));
    }
    canvas.drawCircle(to, w * 0.065, Paint()..color = _wrap);
    canvas.drawCircle(to, w * 0.065, _outline(w * 0.008));
    final dir = (to - from) / (to - from).distance;
    for (final a in const [-0.5, 0.0, 0.5]) {
      final cs = math.cos(a);
      final sn = math.sin(a);
      final fd = Offset(dir.dx * cs - dir.dy * sn, dir.dx * sn + dir.dy * cs);
      canvas.drawLine(to, to + fd * (w * 0.10), _strokeLine(w * 0.022, _wrap));
    }
  }

  @override
  bool shouldRepaint(MummyPainter old) => old.glow != glow || old.sway != sway;
}
