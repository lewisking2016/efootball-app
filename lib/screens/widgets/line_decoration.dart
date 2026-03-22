import 'package:flutter/material.dart';

class LineDecorationPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double spacing;

  LineDecorationPainter({
    required this.color,
    this.strokeWidth = 20.0,
    this.spacing = 40.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Draw diagonal lines from top-right towards bottom-left
    // to match the EPL branding pattern
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i + size.height, 0),
        Offset(i, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LineDecoration extends StatelessWidget {
  final Widget child;
  final Color? color;
  final double opacity;

  const LineDecoration({
    super.key,
    required this.child,
    this.color,
    this.opacity = 0.1,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRect(
            child: CustomPaint(
              painter: LineDecorationPainter(
                color: (color ?? Colors.white).withValues(alpha: opacity),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
