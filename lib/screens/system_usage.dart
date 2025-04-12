import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:klipper_view_micro/providers/printer_state_provider.dart';
import 'package:klipper_view_micro/utils/swipe_wrapper.dart';
import 'package:klipper_view_micro/widgets/resource_widget.dart';

class SystemUsage extends StatelessWidget {
  const SystemUsage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SwipeWrapper(
        disableSwipeDown: false,
        child: Consumer<PrinterStateProvider>(
          builder: (context, provider, child) {
            final state = provider.state;

            // Show a loading indicator if disconnected
            if (!state.isConnected) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Not connected to printer',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => provider.reconnect(),
                      child: const Text('Connect'),
                    ),
                  ],
                ),
              );
            }

            final resourceUsage = state.resourceUsage;

            return Container(
              color: Colors.grey.shade900,
              padding: const EdgeInsets.all(5),
              child: GridView.count(
                physics: const ClampingScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1,
                crossAxisSpacing: 5,
                mainAxisSpacing: 5,
                children: [
                  // CPU Usage
                  ResourceWidget(
                    usage: resourceUsage.cpuUsage,
                    title: 'CPU',
                    icon: Icons.computer,
                    maxValue: 100.0,
                    unit: '%',
                    progressColors: const [Colors.blue, Colors.orange, Colors.red],
                  ),

                  // RAM Usage
                  ResourceWidget(
                    usage: resourceUsage.memoryUsed / resourceUsage.memoryTotal * 100,
                    title: 'RAM',
                    icon: Icons.memory,
                    maxValue: resourceUsage.memoryTotal / 1024 / 1024, // MB → GB
                    unit: 'GB',
                    progressColors: const [Colors.blue, Colors.orange, Colors.red],
                  ),

                  // Network Usage
                  ResourceWidget(
                    usage: resourceUsage.rxBytes / 1024 / 1024, // bytes → MB
                    title: 'Network',
                    icon: Icons.network_check,
                    maxValue: resourceUsage.bandwidth.toDouble(),
                    unit: 'MB/s',
                    progressColors: const [Colors.blue, Colors.orange, Colors.red],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}