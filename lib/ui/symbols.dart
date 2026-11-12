import 'package:flutter/material.dart';

import '../theme.dart';

/// أسماء الرموز بحسب رقم النوع (0 إلى 5).
const List<String> kSymbolNames = [
  'الجعران',
  'مفتاح الحياة',
  'عين حورس',
  'المسلة',
  'زهرة اللوتس',
  'الهرم',
];

/// يرسم بلاطة الرمز كاملة بالكود (بدون صور) فتبقى اللعبة خفيفة وسريعة التحميل.
class SymbolPainter extends CustomPainter {
  final int kind;
  final bool glow;

  const SymbolPainter(this.kind, {this.glow = false});

  static const _light = [
    Color(0xFF2BB5A5),
    Color(0xFFD0583F),
    Color(0xFF3F74D0),
    Color(0xFFC08A22),
    Color(0xFF9560AD),
    Color(0xFF79A456),
  ];
  static const _dark = [
    Color(0xFF0E6B63),
    Color(0xFF8E2F1E),
    Color(0xFF1B3F86),
    Color(0xFF7A4E0E),
    Color(0xFF5B3170),
    Color(0xFF3F5E2B),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final rect = Rect.fromLTWH(0, 0, s, s);
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(s * 0.22));
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_light[kind], _dark[kind]],
        ).createShader(rect),
    );
    canvas.drawRRect(
      rr.deflate(s * 0.025),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = glow ? s * 0.07 : s * 0.035
        ..color = glow ? Pal.goldLight : Pal.gold.withOpacity(0.75),
    );
    canvas.save();
    canvas.translate(s * 0.15, s * 0.15);
    final u = s * 0.7;
    switch (kind) {
      case 0:
        _scarab(canvas, u);
        break;
      case 1:
        _ankh(canvas, u);
        break;
      case 2:
        _eye(canvas, u);
        break;
      case 3:
        _obelisk(canvas, u);
        break;
      case 4:
        _lotus(canvas, u);
        break;
      default:
        _pyramid(canvas, u);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(SymbolPainter old) => old.kind != kind || old.glow != glow;
}

typedef _Draw = void Function(Paint p);

Paint _strokePaint(double w, Color color) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round
  ..strokeWidth = w
  ..color = color;

/// خطوط سميكة بحدّ داكن: يُرسم الحدّ لكل الأجزاء أولاً ثم التعبئة فوقها.
void _glyph(double u, double w, Color fill, List<_Draw> parts) {
  for (final d in parts) {
    d(_strokePaint(w + u * 0.05, Pal.ink));
  }
  for (final d in parts) {
    d(_strokePaint(w, fill));
  }
}

void _shape(Canvas c, Path path, Color fill, double u) {
  c.drawPath(path, Paint()..color = fill);
  c.drawPath(path, _strokePaint(u * 0.03, Pal.ink));
}

double _mx(double x, double m) => 0.5 + (x - 0.5) * m;

void _scarab(Canvas c, double u) {
  const legs = [
    [0.27, 0.44, 0.07, 0.34],
    [0.25, 0.58, 0.05, 0.60],
    [0.28, 0.72, 0.09, 0.86],
  ];
  final parts = <_Draw>[];
  for (final l in legs) {
    for (final m in const [1.0, -1.0]) {
      final a = Offset(_mx(l[0], m) * u, l[1] * u);
      final b = Offset(_mx(l[2], m) * u, l[3] * u);
      parts.add((p) => c.drawLine(a, b, p));
    }
  }
  _glyph(u, u * 0.05, Pal.goldLight, parts);

  final body = Rect.fromCenter(center: Offset(0.5 * u, 0.6 * u), width: 0.52 * u, height: 0.6 * u);
  c.drawOval(body, Paint()..color = Pal.sand);
  c.drawOval(body, _strokePaint(u * 0.03, Pal.ink));
  final head = Rect.fromCenter(center: Offset(0.5 * u, 0.25 * u), width: 0.28 * u, height: 0.17 * u);
  c.drawOval(head, Paint()..color = Pal.goldLight);
  c.drawOval(head, _strokePaint(u * 0.03, Pal.ink));

  final split = Path()
    ..moveTo(0.5 * u, 0.33 * u)
    ..lineTo(0.5 * u, 0.9 * u);
  c.drawPath(split, _strokePaint(u * 0.025, Pal.ink));
  for (final m in const [1.0, -1.0]) {
    final wing = Path()
      ..moveTo(0.5 * u, 0.36 * u)
      ..quadraticBezierTo(_mx(0.30, m) * u, 0.50 * u, _mx(0.34, m) * u, 0.80 * u);
    c.drawPath(wing, _strokePaint(u * 0.022, Pal.ink));
  }
  c.drawCircle(Offset(0.5 * u, 0.07 * u), 0.065 * u, Paint()..color = Pal.sand);
  c.drawCircle(Offset(0.5 * u, 0.07 * u), 0.065 * u, _strokePaint(u * 0.025, Pal.ink));
}

void _ankh(Canvas c, double u) {
  final loop = Rect.fromCenter(center: Offset(0.5 * u, 0.30 * u), width: 0.34 * u, height: 0.42 * u);
  _glyph(u, u * 0.11, Pal.goldLight, [
    (p) => c.drawOval(loop, p),
    (p) => c.drawLine(Offset(0.5 * u, 0.50 * u), Offset(0.5 * u, 0.94 * u), p),
    (p) => c.drawLine(Offset(0.22 * u, 0.60 * u), Offset(0.78 * u, 0.60 * u), p),
  ]);
}

void _eye(Canvas c, double u) {
  final almond = Path()
    ..moveTo(0.04 * u, 0.48 * u)
    ..quadraticBezierTo(0.5 * u, 0.10 * u, 0.96 * u, 0.48 * u)
    ..quadraticBezierTo(0.5 * u, 0.86 * u, 0.04 * u, 0.48 * u)
    ..close();
  _shape(c, almond, Pal.sand, u);
  c.drawCircle(Offset(0.5 * u, 0.47 * u), 0.15 * u, Paint()..color = const Color(0xFF1B3F86));
  c.drawCircle(Offset(0.5 * u, 0.47 * u), 0.07 * u, Paint()..color = Pal.ink);
  c.drawCircle(Offset(0.46 * u, 0.43 * u), 0.025 * u, Paint()..color = Pal.sand);

  final brow = Path()
    ..moveTo(0.06 * u, 0.33 * u)
    ..quadraticBezierTo(0.5 * u, -0.02 * u, 0.94 * u, 0.33 * u);
  final tail1 = Path()
    ..moveTo(0.40 * u, 0.64 * u)
    ..lineTo(0.35 * u, 0.86 * u);
  final tail2 = Path()
    ..moveTo(0.60 * u, 0.66 * u)
    ..lineTo(0.64 * u, 0.78 * u)
    ..quadraticBezierTo(0.72 * u, 0.95 * u, 0.88 * u, 0.84 * u);
  _glyph(u, u * 0.06, Pal.goldLight, [
    (p) => c.drawPath(brow, p),
    (p) => c.drawPath(tail1, p),
    (p) => c.drawPath(tail2, p),
  ]);
}

void _obelisk(Canvas c, double u) {
  final shaft = Path()
    ..moveTo(0.40 * u, 0.22 * u)
    ..lineTo(0.60 * u, 0.22 * u)
    ..lineTo(0.66 * u, 0.82 * u)
    ..lineTo(0.34 * u, 0.82 * u)
    ..close();
  _shape(c, shaft, Pal.sand, u);
  final shade = Path()
    ..moveTo(0.5 * u, 0.22 * u)
    ..lineTo(0.60 * u, 0.22 * u)
    ..lineTo(0.66 * u, 0.82 * u)
    ..lineTo(0.5 * u, 0.82 * u)
    ..close();
  c.drawPath(shade, Paint()..color = Colors.black.withOpacity(0.14));
  final tip = Path()
    ..moveTo(0.40 * u, 0.22 * u)
    ..lineTo(0.60 * u, 0.22 * u)
    ..lineTo(0.5 * u, 0.05 * u)
    ..close();
  _shape(c, tip, Pal.goldLight, u);
  for (final y in const [0.36, 0.48, 0.60, 0.72]) {
    c.drawLine(Offset(0.44 * u, y * u), Offset(0.56 * u, y * u), _strokePaint(u * 0.022, Pal.ink));
  }
  final base = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0.24 * u, 0.82 * u, 0.52 * u, 0.09 * u), Radius.circular(u * 0.02)));
  _shape(c, base, Pal.goldLight, u);
}

void _lotus(Canvas c, double u) {
  for (final m in const [1.0, -1.0]) {
    final petal = Path()
      ..moveTo(0.5 * u, 0.82 * u)
      ..quadraticBezierTo(_mx(0.08, m) * u, 0.74 * u, _mx(0.10, m) * u, 0.30 * u)
      ..quadraticBezierTo(_mx(0.40, m) * u, 0.44 * u, 0.5 * u, 0.82 * u)
      ..close();
    _shape(c, petal, Pal.goldLight, u);
  }
  final center = Path()
    ..moveTo(0.5 * u, 0.08 * u)
    ..quadraticBezierTo(0.70 * u, 0.46 * u, 0.5 * u, 0.84 * u)
    ..quadraticBezierTo(0.30 * u, 0.46 * u, 0.5 * u, 0.08 * u)
    ..close();
  _shape(c, center, Pal.sand, u);
  final water = Path()
    ..moveTo(0.14 * u, 0.92 * u)
    ..quadraticBezierTo(0.5 * u, 1.0 * u, 0.86 * u, 0.92 * u);
  c.drawPath(water, _strokePaint(u * 0.04, Pal.sand));
}

void _pyramid(Canvas c, double u) {
  final tri = Path()
    ..moveTo(0.5 * u, 0.12 * u)
    ..lineTo(0.94 * u, 0.82 * u)
    ..lineTo(0.06 * u, 0.82 * u)
    ..close();
  _shape(c, tri, Pal.sand, u);
  final shade = Path()
    ..moveTo(0.5 * u, 0.12 * u)
    ..lineTo(0.94 * u, 0.82 * u)
    ..lineTo(0.5 * u, 0.82 * u)
    ..close();
  c.drawPath(shade, Paint()..color = Colors.black.withOpacity(0.16));
  for (final y in const [0.36, 0.52, 0.68]) {
    final hw = (y - 0.12) / 0.70 * 0.44;
    c.drawLine(Offset((0.5 - hw) * u, y * u), Offset((0.5 + hw) * u, y * u), _strokePaint(u * 0.018, Pal.ink.withOpacity(0.7)));
  }
  c.drawCircle(Offset(0.82 * u, 0.16 * u), 0.085 * u, Paint()..color = Pal.goldLight);
  c.drawCircle(Offset(0.82 * u, 0.16 * u), 0.085 * u, _strokePaint(u * 0.025, Pal.ink));
}
