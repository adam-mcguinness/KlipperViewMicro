import 'package:flutter/material.dart';
import 'package:klipper_view_micro/widgets/start_stop_buttons.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:klipper_view_micro/providers/printer_state_provider.dart';
import 'package:klipper_view_micro/utils/swipe_wrapper.dart';
import 'package:klipper_view_micro/widgets/print_status_row.dart';
import 'package:klipper_view_micro/widgets/temp_card.dart';

class StatusScreen extends StatelessWidget {
  const StatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SwipeWrapper(
        disableSwipeDown: true,
        child: Consumer<PrinterStateProvider>(
          builder: (context, provider, child) {
            final state = provider.state;

            // Show disconnected state if not connected
            if (!state.isConnected) {
              return _buildDisconnectedState(context, provider);
            }

            return CustomPaint(
              painter: ProgressBorderPainter(state.progress),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TempCard(
                            currentTemp: state.extruder.currentTemperature,
                            targetTemp: state.extruder.targetTemperature,
                            icon: MdiIcons.printer3DNozzleHeat,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TempCard(
                            currentTemp: state.heaterBed.currentTemperature,
                            targetTemp: state.heaterBed.targetTemperature,
                            icon: MdiIcons.radiator,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TempCard(
                            currentTemp: state.heaterBed.currentTemperature,
                            targetTemp: state.heaterBed.targetTemperature,
                            icon: MdiIcons.thermostatBox,
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (state.isPrinting || state.isPaused)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Text(
                                    state.filename,
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
                    PrintStatsRow(
                        progressPercentage: state.progress * 100,
                        printTimeElapsed: state.printStats.totalDuration,
                        printTimeRemaining: state.remainingTime,
                      ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 8.0, bottom: 16.0),
                      child: StartStopButtons(),
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

  Widget _buildDisconnectedState(BuildContext context, PrinterStateProvider provider) {
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
            'Connection state: ${provider.state.isConnected ? 'Connected' : 'Disconnected'}',
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              provider.reconnect();
            },
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