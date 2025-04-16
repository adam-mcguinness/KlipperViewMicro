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
              builder: (context, progressSnapshot)
        {
          final progress = progressSnapshot.data ?? 0.0;
          return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;
                final perimeter = 2 * (width + height);

                // Calculate segment lengths as fractions of total perimeter
                final topSegmentLength = width / perimeter;
                final rightSegmentLength = height / perimeter;
                final bottomSegmentLength = width / perimeter;
                final leftSegmentLength = height / perimeter;

                // Calculate progress for each segment
                final topProgress = _calculateSegmentProgress(
                    progress, 0, topSegmentLength);
                final rightProgress = _calculateSegmentProgress(
                    progress, topSegmentLength, rightSegmentLength);
                final bottomProgress = _calculateSegmentProgress(
                    progress, topSegmentLength + rightSegmentLength,
                    bottomSegmentLength);
                final leftProgress = _calculateSegmentProgress(
                    progress,
                    topSegmentLength + rightSegmentLength + bottomSegmentLength,
                    leftSegmentLength);

                return Stack(
                  children: [
                    Padding(
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
                          ]
                      ),
                    ),

                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Row(
                        children: [
                          // Left half (filled last, 75-100%)
                          Expanded(
                            child: Transform.scale(
                              scaleX: -1, // Flip direction
                              child: LinearProgressIndicator(
                                value: leftProgress > 0 ? 1.0 : 0.0,
                                minHeight: 4.0,
                                backgroundColor: Colors.blue.withAlpha(100),
                              ),
                            ),
                          ),
                          // Right half (filled first, 0-25%)
                          Expanded(
                            child: LinearProgressIndicator(
                              value: topProgress,
                              minHeight: 4.0,
                              backgroundColor: Colors.blue.withAlpha(100),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right progress bar (25-50%)
                    Positioned(
                      top: 4,
                      right: 0,
                      bottom: 4,
                      child: RotatedBox(
                        quarterTurns: 1,
                        child: LinearProgressIndicator(
                          value: rightProgress,
                          minHeight: 4.0,
                          backgroundColor: Colors.blue.withAlpha(100),
                        ),
                      ),
                    ),

                    // Bottom progress bar (50-75%)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Transform.scale(
                        scaleX: -1, // Flip direction
                        child: LinearProgressIndicator(
                          value: bottomProgress,
                          minHeight: 4.0,
                          backgroundColor: Colors.blue.withAlpha(100),
                        ),
                      ),
                    ),

                    // Left progress bar (75-100%)
                    Positioned(
                      top: 4,
                      left: 0,
                      bottom: 4,
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: LinearProgressIndicator(
                          value: leftProgress,
                          minHeight: 4.0,
                          backgroundColor: Colors.blue.withAlpha(100),
                        ),
                      ),
                    ),
                  ],
                );
              }
          );
        }
  )
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

  double _calculateSegmentProgress(double overallProgress, double segmentStart, double segmentLength) {
    // If progress hasn't reached this segment yet
    if (overallProgress < segmentStart)
      return 0.0;

    // If progress has passed this segment completely
    if (overallProgress >= segmentStart + segmentLength)
      return 1.0;

    // Progress is partially in this segment
    return (overallProgress - segmentStart) / segmentLength;
  }
}