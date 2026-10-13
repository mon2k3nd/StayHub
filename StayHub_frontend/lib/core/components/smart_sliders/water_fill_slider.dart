import 'package:flutter/cupertino.dart';
import '../glass_container.dart';

class WaterFillSlider extends StatefulWidget {
  final double initialValue;
  final double maxValue;
  final ValueChanged<double> onChanged;

  const WaterFillSlider({
    super.key,
    required this.initialValue,
    required this.maxValue,
    required this.onChanged,
  });

  @override
  State<WaterFillSlider> createState() => _WaterFillSliderState();
}

class _WaterFillSliderState extends State<WaterFillSlider> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _value -= details.delta.dy / 2;
          if (_value < 0) _value = 0;
          if (_value > widget.maxValue) _value = widget.maxValue;
        });
        widget.onChanged(_value);
      },
      child: GlassContainer(
        padding: EdgeInsets.zero,
        child: Container(
          width: 100,
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: CupertinoColors.systemGrey6.withValues(alpha: 0.3),
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Nước dâng
              FractionallySizedBox(
                heightFactor: _value / widget.maxValue,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [
                        CupertinoColors.activeBlue,
                        CupertinoColors.systemTeal,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
              ),
              // Chỉ số nước
              Positioned(
                bottom: 20,
                child: Text(
                  '${_value.toInt()} m³',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.white,
                    shadows: [
                      Shadow(color: CupertinoColors.black, blurRadius: 4),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
