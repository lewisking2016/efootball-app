import 'package:flutter/material.dart';

class LineDecoration extends StatelessWidget {
  final Color color;
  final double opacity;
  final double spacing;
  final double thickness;

  const LineDecoration({
    super.key,
    this.color = Colors.white,
    this.opacity = 0.1,
    this.spacing = 30.0,
    this.thickness = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LinePainter(
        color: color.withValues(alpha: opacity),
        spacing: spacing,
        thickness: thickness,
      ),
      size: Size.infinite,
    );
  }
}

class _LinePainter extends CustomPainter {
  final Color color;
  final double spacing;
  final double thickness;

  _LinePainter({
    required this.color,
    required this.spacing,
    required this.thickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke;

    // Draw diagonal lines from top-left area to bottom-right area
    // Across the width, with spacing
    for (double i = -size.height; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
