import 'package:flutter/cupertino.dart';
import 'dart:math' as math;
import '../glass_container.dart';

class EnergyDial extends StatefulWidget {
  final double initialValue;
  final double maxValue;
  final ValueChanged<double> onChanged;

  const EnergyDial({
    super.key,
    required this.initialValue,
    required this.maxValue,
    required this.onChanged,
  });

  @override
  State<EnergyDial> createState() => _EnergyDialState();
}

class _EnergyDialState extends State<EnergyDial> {
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
          // Xoay quanh tâm (đơn giản hóa bằng cách dùng dy)
          _value -= details.delta.dy;
          if (_value < 0) _value = 0;
          if (_value > widget.maxValue) _value = widget.maxValue;
        });
        widget.onChanged(_value);
      },
      child: GlassContainer(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Vòng xoay ngoài
              Transform.rotate(
                angle: (_value / widget.maxValue) * 2 * math.pi,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const SweepGradient(
                      colors: [
                        CupertinoColors.systemYellow,
                        CupertinoColors.systemOrange,
                        CupertinoColors.systemYellow,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.systemYellow.withValues(
                          alpha: 0.5,
                        ),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
              ),
              // Tâm hiển thị số
              Container(
                width: 140,
                height: 140,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: CupertinoColors.black,
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      CupertinoIcons.bolt_fill,
                      color: CupertinoColors.systemYellow,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_value.toInt()}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.white,
                      ),
                    ),
                    const Text(
                      'kWh',
                      style: TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
