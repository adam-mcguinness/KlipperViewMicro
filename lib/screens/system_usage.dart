import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:klipper_view_micro/services/printer_service.dart';
import 'package:klipper_view_micro/utils/swipe_wrapper.dart';
import 'package:klipper_view_micro/widgets/resource_widget.dart';

class SystemUsage extends StatelessWidget {
  const SystemUsage({super.key});

  @override
  Widget build(BuildContext context) {
    final printerService = PrinterService();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SwipeWrapper(
        disableSwipeDown: false,
        child: Container(
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
                  StreamBuilder<double>(
                    stream: printerService.cpuUsageStream,
                    builder: (context, snapshot) {
                      final cpuUsage = snapshot.data ?? 0.0;
                      return ResourceWidget(
                        usage: cpuUsage,
                        title: 'CPU',
                        icon: Icons.computer,
                        maxValue: 100.0,
                        unit: '%',
                        progressColors: const [Colors.blue, Colors.orange, Colors.red],
                      );
                    }
                  ),

                  // RAM Usage
                  StreamBuilder<int>(
                    stream: printerService.memoryUsageStream,
                    builder: (context, snapshot) {
                      final memoryUsed = snapshot.data ?? 0.0;
                      final memoryTotal = printerService.totalMemory;
                      return ResourceWidget(
                        usage: memoryUsed /  memoryTotal * 100,
                        title: 'RAM',
                        icon: Icons.memory,
                        maxValue: memoryTotal / 1024 / 1024, // MB → GB
                        unit: 'GB',
                        progressColors: const [Colors.blue, Colors.orange, Colors.red],
                      );
                    }
                  ),
                ],
              ),
            ),
        )
    );
  }
}