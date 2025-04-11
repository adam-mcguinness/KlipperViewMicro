import 'package:flutter/material.dart';
import 'package:klipper_view_micro/models/printer_data.dart';
import 'package:klipper_view_micro/utils/swipe_wrapper.dart';
import 'package:klipper_view_micro/widgets/print_status_row.dart';
import 'package:klipper_view_micro/widgets/temp_card.dart';

import '../api/klipper_api.dart';

class StatusScreen extends StatefulWidget {
  final String title;

  const StatusScreen({
    super.key,
    this.title = 'Printer Status',
  });

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SwipeWrapper(
        disableSwipeDown: true,
        child: StreamBuilder<PrintStatus>(
          stream: KlipperApi().printStatus,
          builder: (context, snapshot) {
            // 🛠️ Connection is loading
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // ⚠️ No data received yet
            if (!snapshot.hasData) {
              return const Center(child: Text('Waiting for print status...'));
            }

            final status = snapshot.data!;

            // ❌ Don't use this anymore: if (!snapshot.hasData) { return Spinner; }

            final isPrinting = status.state == 'printing';
            final isPaused = status.state == 'paused';
            final progress = status.progress;
            final filename = status.filename;
            final printTime = status.printTime;
            final remainingTime = status.printTimeLeft;
            return CustomPaint(
              painter: ProgressBorderPainter(progress),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TempCard(
                            title: 'Hotend Temps',
                            currentTemp: 80,
                            targetTemp: 300,
                            icon: Icons.whatshot,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TempCard(
                            title: 'Bed Temps',
                            currentTemp: 100,
                            targetTemp: 80,
                            icon: Icons.bed,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isPrinting || isPaused)
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    filename,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              const Expanded(
                                child: Center(
                                  child: Text(
                                    'Thumbnail\nPlaceholder',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (isPrinting || isPaused)
                      PrintStatsRow(
                        progressPercentage: progress,
                        printTimeElapsed: printTime,
                        printTimeRemaining: remainingTime,
                      )
                    else
                      const SizedBox(height: 10),
                    SizedBox(
                      height: 50,
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: null,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black, width: 2),
                                  color: isPrinting || isPaused ? Colors.white : Colors.grey.shade300,
                                ),
                                child: Center(
                                  child: Text(
                                    isPaused ? 'Resume' : 'Pause',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isPrinting || isPaused ? Colors.black : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: null,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black, width: 2),
                                  color: isPrinting || isPaused ? Colors.white : Colors.grey.shade300,
                                ),
                                child: Center(
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isPrinting || isPaused ? Colors.black : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }


  // Widget to display when disconnected from printer
  Widget _buildDisconnectedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Disconnected from printer',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connection state:',
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: null,
            child: const Text('Reconnect'),
          ),
        ],
      ),
    );
  }
}

// Custom painter for the progress border
class ProgressBorderPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0

  ProgressBorderPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Calculate the length of each side
    final double topWidth = size.width;
    final double sideHeight = size.height;
    final double bottomWidth = size.width;

    // Calculate the total perimeter length
    final double totalLength = 2 * (topWidth + sideHeight);

    // Calculate how far to draw based on progress
    final double drawLength = totalLength * progress;

    // Drawing parameters
    final Paint paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final path = Path();

    // Start from top-left
    path.moveTo(0, 0);

    // Draw top edge
    if (drawLength < topWidth) {
      path.lineTo(drawLength, 0);
    } else {
      path.lineTo(topWidth, 0);

      // Draw right edge
      if (drawLength < topWidth + sideHeight) {
        path.lineTo(topWidth, drawLength - topWidth);
      } else {
        path.lineTo(topWidth, sideHeight);

        // Draw bottom edge
        if (drawLength < topWidth + sideHeight + bottomWidth) {
          path.lineTo(topWidth - (drawLength - topWidth - sideHeight), sideHeight);
        } else {
          path.lineTo(0, sideHeight);

          // Draw left edge
          final double leftRemaining = drawLength - topWidth - sideHeight - bottomWidth;
          path.lineTo(0, sideHeight - leftRemaining);
        }
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ProgressBorderPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}