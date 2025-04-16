import 'package:flutter/material.dart';
import 'package:klipper_view_micro/widgets/start_stop_buttons.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:klipper_view_micro/services/printer_service.dart';
import 'package:klipper_view_micro/utils/swipe_wrapper.dart';
import 'package:klipper_view_micro/widgets/print_status_row.dart';
import 'package:klipper_view_micro/widgets/temp_card.dart';
import 'package:rxdart/rxdart.dart';

import '../models/printer_data.dart';

class StatusScreen extends StatelessWidget {
  const StatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final printerService = PrinterService();

    return Scaffold(
      body: SwipeWrapper(
        disableSwipeDown: true,
        child: StreamBuilder<double>(
              stream: printerService.progressStream,
              builder: (context, progressSnapshot) {
                final progress = progressSnapshot.data ?? 0.0;

                return CustomPaint(
                  painter: ProgressBorderPainter(progress),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            // Extruder temperature card with streams
                            Expanded(
                              child: _buildExtruderTempCard(printerService),
                            ),
                            const SizedBox(width: 8),
                            // Heater bed temperature card with streams
                            Expanded(
                              child: _buildBedTempCard(printerService),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                        // Thumbnail section
                        Expanded(
                          child: _buildThumbnailSection(printerService),
                        ),
                        // Print stats row with all necessary streams
                        _buildPrintStatsRow(printerService),
                        // Buttons
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 16, right: 16, top: 8.0, bottom: 16.0),
                          child: StartStopButtons(),
                        ),
                      ],
                    ),
                  ),
                );
              },
        ),
      )
    );
  }

  // Build the extruder temperature card with streams
  Widget _buildExtruderTempCard(PrinterService printerService) {
    return StreamBuilder<double>(
      stream: printerService.extruderTemperatureStream,
      builder: (context, tempSnapshot) {
        return StreamBuilder<double>(
          stream: printerService.extruderTargetStream,
          builder: (context, targetSnapshot) {
            final currentTemp = tempSnapshot.data ?? 0.0;
            final targetTemp = targetSnapshot.data ?? 0.0;

            return TempCard(
              currentTemp: currentTemp,
              targetTemp: targetTemp,
              icon: MdiIcons.printer3DNozzleHeat,
            );
          },
        );
      },
    );
  }

  // Build the bed temperature card with streams
  Widget _buildBedTempCard(PrinterService printerService) {
    return StreamBuilder<double>(
      stream: printerService.bedTemperatureStream,
      builder: (context, tempSnapshot) {
        return StreamBuilder<double>(
          stream: printerService.bedTargetStream,
          builder: (context, targetSnapshot) {
            final currentTemp = tempSnapshot.data ?? 0.0;
            final targetTemp = targetSnapshot.data ?? 0.0;

            return TempCard(
              currentTemp: currentTemp,
              targetTemp: targetTemp,
              icon: MdiIcons.radiator,
            );
          },
        );
      },
    );
  }

  // Build the thumbnail section with filename from print stats
  Widget _buildThumbnailSection(PrinterService printerService) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Only show filename if printing or paused
            StreamBuilder<bool>(
              stream: Rx.combineLatest2(
                printerService.isPrintingStream,
                printerService.isPausedStream,
                    (isPrinting, isPaused) => isPrinting || isPaused,
              ),
              builder: (context, snapshot) {
                final shouldShowFilename = snapshot.data ?? false;

                if (!shouldShowFilename) {
                  return const SizedBox.shrink();
                }

                return StreamBuilder<String?>(
                  stream: printerService.fileNameStream,
                  builder: (context, snapshot) {
                    final filename = snapshot.data ?? 'No file';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        filename,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                );
              },
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
    );
  }

  // Build the print stats row with progress, elapsed and remaining time
  Widget _buildPrintStatsRow(PrinterService printerService) {
    return StreamBuilder<double>(
      stream: printerService.progressStream,
      builder: (context, progressSnapshot) {
        return StreamBuilder<PrintStats>(
          stream: printerService.printStatsStream,
          builder: (context, statsSnapshot) {
            return StreamBuilder<double>(
              stream: printerService.remainingTimeStream,
              builder: (context, remainingSnapshot) {
                final progress = progressSnapshot.data ?? 0.0;
                final totalDuration = statsSnapshot.data?.totalDuration ?? 0.0;
                final remainingTime = remainingSnapshot.data ?? 0.0;

                return PrintStatsRow(
                  progressPercentage: progress * 100,
                  printTimeElapsed: totalDuration,
                  printTimeRemaining: remainingTime,
                );
              },
            );
          },
        );
      },
    );
  }

  // Build the disconnected state UI
  Widget _buildDisconnectedState(BuildContext context, PrinterService printerService) {
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
            'Connection state: ${printerService.isConnected ? 'Connected' : 'Disconnected'}',
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              printerService.reconnect();
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