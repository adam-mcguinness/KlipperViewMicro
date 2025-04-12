import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:klipper_view_micro/providers/printer_state_provider.dart';
import 'package:provider/provider.dart';


class StartStopButtons extends StatelessWidget {
  const StartStopButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PrinterStateProvider>(
      builder: (context, provider, child) {
        final state = provider.state;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FilledButton.tonal(
                  onPressed: () {
                    if (state.isPaused) {
                      provider.resumePrint();
                    } else if (state.isPrinting) {
                      provider.pausePrint();
                    }
                  },
                  child: Text(
                    state.isPaused ? 'Resume' : 'Pause',
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () {
                    if (state.isPrinting || state.isPaused) {
                      _showCancelDialog(context, provider);
                    }
                  },
                  child: const Text('Stop'),
                ),
              ],
        );
      },
    );
  }
}

void _showCancelDialog(BuildContext context, PrinterStateProvider provider) {
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
            provider.cancelPrint().catchError((e) {
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