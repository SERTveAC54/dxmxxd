import 'package:flutter/material.dart';

/// Dikey DMX Slider - Dimmer, Zoom, Focus vb. için
class DMXSlider extends StatelessWidget {
  final String label;
  final double value; // 0.0 - 1.0
  final Function(double) onChanged;
  final Color activeColor;
  final bool showValue;
  
  const DMXSlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.activeColor = const Color(0xFF00D9FF),
    this.showValue = true,
  });

  @override
  Widget build(BuildContext context) {
    final dmxValue = (value * 255).round();
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Değer göstergesi
        if (showValue)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: activeColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: activeColor.withOpacity(0.5)),
            ),
            child: Text(
              dmxValue.toString(),
              style: TextStyle(
                color: activeColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        
        const SizedBox(height: 8),
        
        // Slider
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 40,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 12,
                ),
                overlayShape: const RoundSliderOverlayShape(
                  overlayRadius: 20,
                ),
                activeTrackColor: activeColor,
                inactiveTrackColor: const Color(0xFF1A1F3A),
                thumbColor: activeColor,
                overlayColor: activeColor.withOpacity(0.2),
              ),
              child: Slider(
                value: value,
                onChanged: onChanged,
                min: 0.0,
                max: 1.0,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Label
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
