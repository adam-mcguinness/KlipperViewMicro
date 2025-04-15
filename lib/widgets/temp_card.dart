import 'package:flutter/material.dart';

class TempCard extends StatelessWidget {
  final double currentTemp;
  final double targetTemp;
  final IconData icon;

  const TempCard({
    super.key,
    required this.currentTemp,
    required this.targetTemp,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Icon(
              color: Colors.white,
              icon
            ),
          ),
          const SizedBox(width: 12),
          // Temperature text
          Column(
            children: [
              Text(
                '${currentTemp.toStringAsFixed(1)}°C / ${targetTemp.toStringAsFixed(0)}°C',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}