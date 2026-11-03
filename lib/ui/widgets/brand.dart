import 'package:flutter/material.dart';

/// vandarna mark: city skyline with a location pin (light = filled, dark = outlined).
class LogoPainter extends CustomPainter {
  LogoPainter({required this.body, required this.pin, required this.hole, this.outline = false});
  final Color body, pin, hole;
  final bool outline;

  // [x, top, width] in 0..1 units; every block sits on the baseline.
  static const _blocks = <List<double>>[
    [0.00, 0.80, 0.12],
    [0.10, 0.62, 0.10],
    [0.19, 0.50, 0.16],
    [0.33, 0.28, 0.14],
    [0.45, 0.42, 0.13],
    [0.57, 0.56, 0.12],
    [0.67, 0.50, 0.12],
    [0.77, 0.62, 0.10],
    [0.86, 0.72, 0.14],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final fill = Paint()..color = body;
    if (outline) {
      fill.style = PaintingStyle.stroke;
      fill.strokeWidth = w * 0.014;
      fill.strokeJoin = StrokeJoin.round;
    }
    final holePaint = Paint()..color = hole;
    final base = h * 0.98;
    for (final b in _blocks) {
      final rect = RRect.fromLTRBR(b[0] * w, b[1] * h, (b[0] + b[2]) * w, base, Radius.circular(w * 0.008));
      canvas.drawRRect(rect, fill);
      if (b[2] >= 0.10) {
        var i = 0;
        while (true) {
          final y = b[1] * h + h * 0.05 + i * h * 0.075;
          if (y > base - h * 0.06) break;
          for (final col in const [0.22, 0.58]) {
            final x = (b[0] + b[2] * col) * w;
            canvas.drawRect(Rect.fromLTWH(x, y, w * 0.025, h * 0.03), outline ? fill : holePaint);
          }
          i++;
        }
      }
    }
    // pin
    final pr = w * 0.085;
    final pc = Offset(w * 0.52, pr);
    final path = Path()..addOval(Rect.fromCircle(center: pc, radius: pr));
    path.moveTo(pc.dx - pr * 0.88, pc.dy + pr * 0.5);
    path.lineTo(pc.dx, pc.dy + pr * 3.0);
    path.lineTo(pc.dx + pr * 0.88, pc.dy + pr * 0.5);
    path.close();
    canvas.drawPath(path, Paint()..color = pin);
    canvas.drawCircle(pc, pr * 0.38, holePaint);
  }

  @override
  bool shouldRepaint(LogoPainter old) => old.body != body || old.pin != pin || old.hole != hole || old.outline != outline;
}

/// Soft skyline silhouette for the welcome screen.
class CityPainter extends CustomPainter {
  CityPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    double ground(double x) => h * (0.70 - 0.22 * (x / w));
    final fill = Paint()..color = color;
    final hill = Path()
      ..moveTo(0, h * 0.78)
      ..cubicTo(w * 0.2, h * 0.58, w * 0.4, h * 0.78, w * 0.6, h * 0.62)
      ..cubicTo(w * 0.8, h * 0.48, w * 0.9, h * 0.5, w, h * 0.42)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(hill, Paint()..color = color.withValues(alpha: 0.55));
    const n = 26;
    for (var i = 0; i < n; i++) {
      final x = i * w / n;
      final bh = h * (0.07 + 0.11 * ((i * 7) % 5) / 5);
      final bw = w / n * 0.78;
      canvas.drawRect(Rect.fromLTWH(x, ground(x) - bh + h * 0.08, bw, bh), fill);
    }
    // TV tower
    final tx = w * 0.88;
    canvas.drawRect(Rect.fromLTWH(tx, h * 0.02, w * 0.008, ground(tx) - h * 0.02 + h * 0.08), fill);
    canvas.drawOval(Rect.fromCenter(center: Offset(tx + w * 0.004, h * 0.2), width: w * 0.03, height: h * 0.05), fill);
    // sea
    canvas.drawRect(Rect.fromLTWH(0, h * 0.86, w, h * 0.14), Paint()..color = color.withValues(alpha: 0.3));
  }

  @override
  bool shouldRepaint(CityPainter old) => old.color != color;
}
