import 'package:flutter/material.dart';

import '../theme.dart';

/// خلفية ليل الصحراء: شمس خافتة وأهرامات وإفريز ذهبي على الحافتين.
class EgyptBackground extends StatelessWidget {
  final Widget child;
  const EgyptBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Pal.night, Pal.night2, Color(0xFF3A2A12)],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: RepaintBoundary(child: CustomPaint(painter: _DesertPainter())),
          ),
          child,
        ],
      ),
    );
  }
}

class _DesertPainter extends CustomPainter {
  const _DesertPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawCircle(Offset(w * 0.82, h * 0.14), w * 0.12, Paint()..color = Pal.gold.withOpacity(0.16));
    canvas.drawCircle(Offset(w * 0.82, h * 0.14), w * 0.07, Paint()..color = Pal.goldLight.withOpacity(0.18));

    final pyr = Paint()..color = Colors.black.withOpacity(0.28);
    for (final t in const [
      [0.02, 0.50, 0.84],
      [0.30, 0.66, 0.90],
      [0.60, 0.98, 0.86],
    ]) {
      final path = Path()
        ..moveTo(w * t[0], h)
        ..lineTo(w * t[1], h)
        ..lineTo(w * (t[0] + t[1]) / 2, h * t[2])
        ..close();
      canvas.drawPath(path, pyr);
    }

    final band = Paint()..color = Pal.gold.withOpacity(0.55);
    const fh = 12.0;
    final tw = fh * 1.3;
    final n = (w / tw).ceil();
    for (var i = 0; i < n; i++) {
      final x = i * tw;
      canvas.drawPath(
        Path()
          ..moveTo(x, 0)
          ..lineTo(x + tw / 2, fh)
          ..lineTo(x + tw, 0)
          ..close(),
        band,
      );
      canvas.drawPath(
        Path()
          ..moveTo(x, h)
          ..lineTo(x + tw / 2, h - fh)
          ..lineTo(x + tw, h)
          ..close(),
        band,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
