import 'package:flutter/material.dart';
import 'dart:math' as math;

/// XY Pad - Pan/Tilt kontrolü için profesyonel joystick
class XYPad extends StatefulWidget {
  final Function(double x, double y) onChanged;
  final double initialX;
  final double initialY;
  final Color activeColor;
  
  const XYPad({
    super.key,
    required this.onChanged,
    this.initialX = 0.5,
    this.initialY = 0.5,
    this.activeColor = const Color(0xFF00D9FF),
  });

  @override
  State<XYPad> createState() => _XYPadState();
}

class _XYPadState extends State<XYPad> {
  late double _x;
  late double _y;
  
  @override
  void initState() {
    super.initState();
    _x = widget.initialX;
    _y = widget.initialY;
  }
  
  void _updatePosition(Offset localPosition, Size size) {
    setState(() {
      _x = (localPosition.dx / size.width).clamp(0.0, 1.0);
      _y = (localPosition.dy / size.height).clamp(0.0, 1.0);
    });
    widget.onChanged(_x, _y);
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        _updatePosition(details.localPosition, context.size!);
      },
      onPanUpdate: (details) {
        _updatePosition(details.localPosition, context.size!);
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F3A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.activeColor.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: CustomPaint(
          painter: _XYPadPainter(
            x: _x,
            y: _y,
            activeColor: widget.activeColor,
          ),
          child: Container(),
        ),
      ),
    );
  }
}

class _XYPadPainter extends CustomPainter {
  final double x;
  final double y;
  final Color activeColor;
  
  _XYPadPainter({
    required this.x,
    required this.y,
    required this.activeColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Grid çizgileri
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;
    
    // Dikey çizgiler
    for (int i = 1; i < 4; i++) {
      final x = size.width * (i / 4);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }
    
    // Yatay çizgiler
    for (int i = 1; i < 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
    
    // Merkez çarpı işareti
    final centerPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 2;
    
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    canvas.drawLine(
      Offset(centerX - 10, centerY),
      Offset(centerX + 10, centerY),
      centerPaint,
    );
    canvas.drawLine(
      Offset(centerX, centerY - 10),
      Offset(centerX, centerY + 10),
      centerPaint,
    );
    
    // Joystick pozisyonu
    final posX = size.width * x;
    final posY = size.height * y;
    
    // Glow efekti
    final glowPaint = Paint()
      ..color = activeColor.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    
    canvas.drawCircle(Offset(posX, posY), 25, glowPaint);
    
    // Ana joystick
    final thumbPaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(posX, posY), 15, thumbPaint);
    
    // İç halka
    final innerPaint = Paint()
      ..color = const Color(0xFF0A0E27)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(posX, posY), 8, innerPaint);
    
    // Çarpı işareti
    final crossPaint = Paint()
      ..color = activeColor
      ..strokeWidth = 2;
    
    canvas.drawLine(
      Offset(posX - 5, posY),
      Offset(posX + 5, posY),
      crossPaint,
    );
    canvas.drawLine(
      Offset(posX, posY - 5),
      Offset(posX, posY + 5),
      crossPaint,
    );
  }
  
  @override
  bool shouldRepaint(_XYPadPainter oldDelegate) {
    return oldDelegate.x != x || oldDelegate.y != y;
  }
}
