import 'dart:async';

import 'package:flutter/material.dart';
import 'package:klipper_view_micro/models/printer_data.dart';
import 'package:klipper_view_micro/services/api_services.dart';
import 'package:klipper_view_micro/utils/swipe_wrapper.dart';
import 'package:klipper_view_micro/widgets/print_status_row.dart';
import 'package:klipper_view_micro/widgets/temp_card.dart';

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
  PrintStatus? _printStatus;
  HeaterBed? _heaterBedStatus;
  Extruder? _extruderStatus;
  String _connectionState = "disconnected";

  // Extracted variables for easy use in UI
  double progress = 0.0;
  String filename = '';
  int printTime = 0;
  int remainingTime = 0;
  double hotendCurrent = 0.0;
  double hotendTarget = 0.0;
  double bedCurrent = 0.0;
  double bedTarget = 0.0;
  bool isPrinting = false;
  bool isPaused = false;
  bool isConnected = false;

  StreamSubscription? _printStatusSubscription;
  StreamSubscription? _bedStatusSubscription;
  StreamSubscription? _extruderStatusSubscription;
  StreamSubscription? _stateStreamSubscription;

  @override
  void initState() {
    super.initState();

    // Check initial connection state
    isConnected = ApiService().isConnected;
    _connectionState = ApiService().currentState;

    // Subscribe to print status updates
    _printStatusSubscription = ApiService().api.printStatusStream.listen((printStatus) {
      if (mounted) {
        setState(() {
          _printStatus = printStatus;

          // Extract all needed values in one place
          progress = printStatus.progress;
          filename = printStatus.filename;
          printTime = printStatus.printTime;
          remainingTime = printStatus.printTimeLeft;
          isPrinting = printStatus.state == 'printing';
          isPaused = printStatus.state == 'paused';
        });
      }
    });

    // Subscribe to bed status updates
    _bedStatusSubscription = ApiService().api.heaterBedStream.listen((bedStatus) {
      if (mounted) {
        setState(() {
          _heaterBedStatus = bedStatus;
          // Extract bed temperature values
          bedCurrent = bedStatus.currentTemperature;
          bedTarget = bedStatus.targetTemperature;
        });
      }
    });

    // Subscribe to extruder status updates
    _extruderStatusSubscription = ApiService().api.extruderStream.listen((extruderStatus) {
      if (mounted) {
        setState(() {
          _extruderStatus = extruderStatus;
          // Extract hotend temperature values
          hotendCurrent = extruderStatus.currentTemperature;
          hotendTarget = extruderStatus.targetTemperature;
        });
      }
    });

    // Subscribe to connection state updates
    _stateStreamSubscription = ApiService().api.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _connectionState = state;
          isConnected = state == "connected";

          // If we're disconnected, try to reconnect
          if (!isConnected) {
            _attemptReconnect();
          }
        });
      }
    });

    // Initial data fetch if connection is available
    if (isConnected) {
      _fetchInitialData();
    } else {
      _attemptReconnect();
    }
  }

  // Attempt to reconnect to the printer
  Future<void> _attemptReconnect() async {
    final success = await ApiService().reconnect();
    if (success && mounted) {
      setState(() {
        isConnected = true;
        _connectionState = "connected";
      });
      // Fetch initial data after reconnection
      _fetchInitialData();
    }
  }

  // Fetch initial data after connection is established
  Future<void> _fetchInitialData() async {
    try {
      final tempData = await ApiService().api.fetchTemperatureData();
      if (tempData.isNotEmpty && mounted) {
        // Update UI with initial data if available
        if (tempData['heater_bed'] != null) {
          final bedStatus = HeaterBed.fromJson(tempData['heater_bed']);
          setState(() {
            _heaterBedStatus = bedStatus;
            bedCurrent = bedStatus.currentTemperature;
            bedTarget = bedStatus.targetTemperature;
          });
        }

        if (tempData['extruder'] != null) {
          final extruderStatus = Extruder.fromJson(tempData['extruder']);
          setState(() {
            _extruderStatus = extruderStatus;
            hotendCurrent = extruderStatus.currentTemperature;
            hotendTarget = extruderStatus.targetTemperature;
          });
        }

        if (tempData['print_stats'] != null) {
          final printStatus = PrintStatus.fromJson(tempData['print_stats']);
          setState(() {
            _printStatus = printStatus;
            progress = printStatus.progress;
            filename = printStatus.filename;
            printTime = printStatus.printTime;
            remainingTime = printStatus.printTimeLeft;
            isPrinting = printStatus.state == 'printing';
            isPaused = printStatus.state == 'paused';
          });
        }
      }
    } catch (e) {
      print('Error fetching initial data: $e');
    }
  }

  @override
  void dispose() {
    _printStatusSubscription?.cancel();
    _bedStatusSubscription?.cancel();
    _extruderStatusSubscription?.cancel();
    _stateStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _pauseResumePrint() async {
    if (isPrinting) {
      final success = await ApiService().api.pausePrint();
      // State will be updated through the stream
    } else if (isPaused) {
      final success = await ApiService().api.resumePrint();
      // State will be updated through the stream
    }
  }

  Future<void> _cancelPrint() async {
    final success = await ApiService().api.cancelPrint();
    // State will be updated through the stream
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SwipeWrapper(
        disableSwipeDown: true,
        child: !isConnected
            ? _buildDisconnectedState()
            : _printStatus == null
            ? const Center(child: CircularProgressIndicator())
            : CustomPaint(
          painter: ProgressBorderPainter(progress),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top row with temperature cards
                Row(
                  children: [
                    // Hotend temperature card
                    Expanded(
                      child: TempCard(
                        title: 'Hotend Temps',
                        currentTemp: hotendCurrent,
                        targetTemp: hotendTarget,
                        icon: Icons.whatshot,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Bed temperature card
                    Expanded(
                      child: TempCard(
                        title: 'Bed Temps',
                        currentTemp: bedCurrent,
                        targetTemp: bedTarget,
                        icon: Icons.bed,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Thumbnail placeholder (central area)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Job info if printing
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

                // Print statistics (below thumbnail and above buttons)
                if (isPrinting || isPaused)
                  PrintStatsRow(
                      progressPercentage: progress,
                      printTimeElapsed: printTime,
                      printTimeRemaining: remainingTime
                  )
                else
                  const SizedBox(height: 10),

                // Bottom row with control buttons
                SizedBox(
                  height: 50, // Reduced height
                  child: Row(
                    children: [
                      // Pause/Resume button
                      Expanded(
                        child: GestureDetector(
                          onTap: isPrinting || isPaused
                              ? _pauseResumePrint
                              : null,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black, width: 2),
                              color: isPrinting || isPaused
                                  ? Colors.white
                                  : Colors.grey.shade300,
                            ),
                            child: Center(
                              child: Text(
                                isPaused ? 'Resume' : 'Pause',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isPrinting || isPaused
                                      ? Colors.black
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Cancel button
                      Expanded(
                        child: GestureDetector(
                          onTap: isPrinting || isPaused ? () {
                            showDialog(
                              context: context,
                              builder: (context) =>
                                  AlertDialog(
                                    title: const Text('Cancel Print'),
                                    content: const Text(
                                        'Are you sure you want to cancel the current print job?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('No'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _cancelPrint();
                                        },
                                        child: const Text('Yes'),
                                      ),
                                    ],
                                  ),
                            );
                          } : null,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black, width: 2),
                              color: isPrinting || isPaused
                                  ? Colors.white
                                  : Colors.grey.shade300,
                            ),
                            child: Center(
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isPrinting || isPaused
                                      ? Colors.black
                                      : Colors.grey,
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
            'Connection state: $_connectionState',
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _attemptReconnect,
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