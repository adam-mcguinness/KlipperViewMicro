import 'package:flutter/material.dart';
import 'package:klipper_view_micro/api/klipper_api.dart';
import 'package:klipper_view_micro/models/printer_data.dart';
import 'package:klipper_view_micro/utils/swipe_wrapper.dart';
import 'package:klipper_view_micro/widgets/resource_widget.dart';

class SystemUsage extends StatefulWidget {
  const SystemUsage({super.key});

  @override
  State<SystemUsage> createState() => _SystemUsageState();
}

class _SystemUsageState extends State<SystemUsage> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ResourceUsage>(
      stream: KlipperApi().resourceUsage,
      builder: (context, snapshot) {
        final resourceUsage = snapshot.data;

        return Scaffold(
          backgroundColor: Colors.white,
          body: SwipeWrapper(
            disableSwipeDown: false,
            child: Container(
              color: Colors.grey.shade900,
              padding: const EdgeInsets.all(5),
              child: resourceUsage == null
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.count(
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
            ),
          ),
        );
      },
    );
  }
}
