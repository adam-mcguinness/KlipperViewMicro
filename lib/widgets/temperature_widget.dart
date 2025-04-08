import 'package:flutter/material.dart';
import '../utils/constants.dart';

class TemperatureWidget extends StatelessWidget {
  final String title;
  final double? current;
  final double? target;
  final bool isLoading;

  const TemperatureWidget({
    Key? key,
    required this.title,
    this.current,
    this.target,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.labelStyle,
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              if (isLoading)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.textColor,
                  ),
                )
              else
                Text(
                  current != null ? '${current!.toStringAsFixed(1)}°C' : '--°C',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: current != null && target != null && (current! >= target! - 2)
                        ? Colors.green
                        : AppTheme.textColor,
                  ),
                ),
              const Spacer(),
              Text(
                target != null && target! > 0 ? '/${target!.toStringAsFixed(0)}°C' : '',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textColorSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}