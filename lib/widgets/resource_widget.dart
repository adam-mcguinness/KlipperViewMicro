import 'package:flutter/material.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';

class ResourceWidget extends StatelessWidget {
  // Required parameters
  final double usage; // 0 to 100 (percentage)
  final String title;
  final IconData icon;

  // Optional parameters for customization
  final double maxValue; // Max resource value (e.g., total RAM in GB, max CPU freq in GHz)
  final String unit; // Unit of measurement (e.g., "GB", "GHz", "MB/s")
  final List<Color> progressColors; // Custom gradient colors for the circular slider
  final Color trackColor; // Color of the background track
  final double fontSize; // Base font size that can be adjusted
  final double circleSize; // Size of the circular slider

  const ResourceWidget({
    super.key,
    required this.usage,
    required this.title,
    required this.icon,
    this.maxValue = 100.0,
    this.unit = '',
    this.progressColors = const [Colors.green, Colors.orange, Colors.red],
    this.trackColor = const Color(0xFF424242), // gray shade 800
    this.fontSize = 1.0, // scaling factor
    this.circleSize = 250.0,
  });

  // Returns appropriate color based on usage level with fixed thresholds
  Color _getColorForUsage(double usage) {
    if (usage < 60.0) {
      return progressColors.isNotEmpty ? progressColors.first : Colors.green;
    } else if (usage < 80.0) {
      return progressColors.length > 1 ? progressColors[1] : Colors.orange;
    } else {
      return progressColors.length > 2 ? progressColors[2] : Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color usageColor = _getColorForUsage(usage);
    final double currentValue = (usage / 100) * maxValue;

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main content
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Circular slider
                    SleekCircularSlider(
                      appearance: CircularSliderAppearance(
                        customWidths: CustomSliderWidths(
                          trackWidth: 20,
                          progressBarWidth: 20,
                          shadowWidth: 0,
                        ),
                        customColors: CustomSliderColors(
                          trackColor: trackColor,
                          progressBarColors: [
                            progressColors.first,
                            usageColor,
                          ],
                          shadowColor: Colors.transparent,
                          shadowMaxOpacity: 0,
                        ),
                        startAngle: 150,
                        angleRange: 240,
                        size: circleSize,
                        animationEnabled: true,
                      ),
                      min: 0,
                      max: 100,
                      initialValue: usage,
                      innerWidget: (double value) {
                        return const SizedBox.shrink();
                      },
                    ),

                    // Center display
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${usage.toInt()}%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 50 * fontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    // Resource details at bottom
                    Positioned(
                      bottom: 0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            color: usageColor,
                            size: 30 * fontSize,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            unit.isNotEmpty
                                ? '${currentValue.toStringAsFixed(1)} / ${maxValue.toStringAsFixed(1)} $unit'
                                : '${currentValue.toStringAsFixed(1)} / ${maxValue.toStringAsFixed(1)}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30 * fontSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}