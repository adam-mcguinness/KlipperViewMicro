import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:klipper_view_micro/services/printer_service.dart';
import 'package:rxdart/rxdart.dart';

class StartStopButtons extends StatelessWidget {
  const StartStopButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final printerService = PrinterService();

    // Combine both streams to efficiently determine button states
    return StreamBuilder<List<bool>>(
      stream: Rx.combineLatest2<bool, bool, List<bool>>(
        printerService.isPrintingStream,
        printerService.isPausedStream,
            (isPrinting, isPaused) => [isPrinting, isPaused],
      ),
      builder: (context, snapshot) {
        final data = snapshot.data ?? [false, false];
        final isPrinting = data[0];
        final isPaused = data[1];

        final isActive = isPrinting || isPaused;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FilledButton.tonal(
              onPressed: isActive
                  ? () {
                if (isPaused) {
                  printerService.resumePrint();
                } else if (isPrinting) {
                  printerService.pausePrint();
                }
              }
                  : null,
              child: Text(
                isPaused ? 'Resume' : 'Pause',
              ),
            ),
            FilledButton.tonal(
              onPressed: isActive
                  ? () => _showCancelDialog(context, printerService)
                  : null,
              child: const Text('Stop'),
            ),
          ],
        );
      },
    );
  }

  void _showCancelDialog(BuildContext context, PrinterService printerService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Print'),
        content: const Text('Are you sure you want to cancel the current print?'),
        actions: [
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          FilledButton.tonal(
            onPressed: () {
              Navigator.of(context).pop();
              printerService.cancelPrint().catchError((e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to cancel print: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              });
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }
}