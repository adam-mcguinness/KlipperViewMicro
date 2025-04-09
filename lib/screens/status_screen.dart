import 'package:flutter/material.dart';
import 'package:klipper_view_micro/utils/swipe_wrapper.dart';

class StatusScreen extends StatelessWidget {
  final String title;
  final String message;

  const StatusScreen({
    super.key,
    this.title = 'Status Page',
    this.message = 'This is a simple status page',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SwipeWrapper(
        disableSwipeDown: true,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 24,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}