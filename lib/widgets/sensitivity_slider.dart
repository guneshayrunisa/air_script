import 'package:flutter/material.dart';

class SensitivitySliderSheet extends StatefulWidget {
  final Color bgColor;
  final Color softAccent;
  final double sensitivity;
  final ValueChanged<double> onChanged;

  const SensitivitySliderSheet({
    super.key,
    required this.bgColor,
    required this.softAccent,
    required this.sensitivity,
    required this.onChanged,
  });

  @override
  State<SensitivitySliderSheet> createState() => _SensitivitySliderSheetState();
}

class _SensitivitySliderSheetState extends State<SensitivitySliderSheet> {
  late double _localSensitivity;

  @override
  void initState() {
    super.initState();
    _localSensitivity = widget.sensitivity;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                "Motion Sensitivity",
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                _localSensitivity.toInt().toString(),
                style: TextStyle(
                  color: widget.softAccent,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Slider(
                value: _localSensitivity,
                min: 200,
                max: 1500,
                activeColor: const Color(0xFF64748B),
                inactiveColor: const Color(0xFFE2E8F0),
                onChanged: (value) {
                  setState(() {
                    _localSensitivity = value;
                  });

                  widget.onChanged(value);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
