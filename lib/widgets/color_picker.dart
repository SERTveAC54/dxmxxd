import 'package:flutter/material.dart';
import 'dart:math' as math;

/// RGB/RGBW Color Picker - LED boyama için
class DMXColorPicker extends StatefulWidget {
  final Function(Color) onColorChanged;
  final Color initialColor;
  
  const DMXColorPicker({
    super.key,
    required this.onColorChanged,
    this.initialColor = Colors.white,
  });

  @override
  State<DMXColorPicker> createState() => _DMXColorPickerState();
}

class _DMXColorPickerState extends State<DMXColorPicker> {
  late Color _selectedColor;
  
  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }
  
  void _updateColor(Offset localPosition, Size size) {
    final dx = localPosition.dx.clamp(0.0, size.width);
    final dy = localPosition.dy.clamp(0.0, size.height);
    
    final hue = (dx / size.width) * 360;
    final saturation = 1.0;
    final value = 1.0 - (dy / size.height);
    
    setState(() {
      _selectedColor = HSVColor.fromAHSV(1.0, hue, saturation, value).toColor();
    });
    
    widget.onColorChanged(_selectedColor);
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Renk paleti
        Expanded(
          child: GestureDetector(
            onPanStart: (details) {
              _updateColor(details.localPosition, context.size!);
            },
            onPanUpdate: (details) {
              _updateColor(details.localPosition, context.size!);
            },
            onTapDown: (details) {
              _updateColor(details.localPosition, context.size!);
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF00D9FF).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CustomPaint(
                  painter: _ColorPickerPainter(),
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Seçili renk göstergesi
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: _selectedColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _selectedColor.withOpacity(0.5),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // RGB değerleri
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ColorValueChip('R', _selectedColor.red, Colors.red),
            _ColorValueChip('G', _selectedColor.green, Colors.green),
            _ColorValueChip('B', _selectedColor.blue, Colors.blue),
          ],
        ),
      ],
    );
  }
}

class _ColorPickerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Hue gradient (yatay)
    final hueRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final hueGradient = LinearGradient(
      colors: [
        const HSVColor.fromAHSV(1.0, 0, 1.0, 1.0).toColor(),
        const HSVColor.fromAHSV(1.0, 60, 1.0, 1.0).toColor(),
        const HSVColor.fromAHSV(1.0, 120, 1.0, 1.0).toColor(),
        const HSVColor.fromAHSV(1.0, 180, 1.0, 1.0).toColor(),
        const HSVColor.fromAHSV(1.0, 240, 1.0, 1.0).toColor(),
        const HSVColor.fromAHSV(1.0, 300, 1.0, 1.0).toColor(),
        const HSVColor.fromAHSV(1.0, 360, 1.0, 1.0).toColor(),
      ],
    );
    
    canvas.drawRect(
      hueRect,
      Paint()..shader = hueGradient.createShader(hueRect),
    );
    
    // Value gradient (dikey - siyaha doğru)
    final valueRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final valueGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.transparent,
        Colors.black,
      ],
    );
    
    canvas.drawRect(
      valueRect,
      Paint()..shader = valueGradient.createShader(valueRect),
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ColorValueChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  
  const _ColorValueChip(this.label, this.value, this.color);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
