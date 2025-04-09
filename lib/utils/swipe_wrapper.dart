import 'package:flutter/material.dart';
import 'package:klipper_view_micro/widgets/nav_drawer_buttons.dart';
import '../screens/status_screen.dart';

class SwipeWrapper extends StatelessWidget {
  final Widget child;
  final bool disableSwipeDown; // Disable swipe down if true
  final bool showIndicator;
  final Color pillColor;
  final Color backgroundColor;
  final double swipeDetectionHeight; // Height of the detection area

  const SwipeWrapper({
    super.key,
    required this.child,
    required this.disableSwipeDown,
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

        // Bottom pill indicator
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
                NavDrawer.show(context);
              }
            },
            // Transparent container for detection area
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),

        // Invisible swipe detection area at the top (new)
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: swipeDetectionHeight,
          child: GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity! > 500) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => StatusScreen()),
                      (route) => false, // This will remove all routes from the stack
                );
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