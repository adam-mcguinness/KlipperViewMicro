import 'package:flutter/material.dart';

class SwipeUpWrapper extends StatelessWidget {
  final Widget child;
  final bool showIndicator;
  final Color pillColor;
  final Color backgroundColor;
  final double swipeDetectionHeight; // Height of the detection area

  const SwipeUpWrapper({
    super.key,
    required this.child,
    this.showIndicator = true,
    this.pillColor = Colors.white,
    this.backgroundColor = Colors.transparent,
    this.swipeDetectionHeight = 60.0, // Default detection area height
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content
        child,

        // Optional pill indicator positioned at the bottom
        if (showIndicator)
          Positioned(
            left: 0,
            right: 0,
            bottom: -2, // 2 pixels below the bottom
            child: Container(
              height: 30,
              color: backgroundColor,
              padding: const EdgeInsets.only(bottom: 10),
              child: Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: pillColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),

        // Invisible swipe detection area at the bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: swipeDetectionHeight,
          child: GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity! < -500) {
                Navigator.of(context).pop();
              }
            },
            // Transparent container for detection area
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }
}