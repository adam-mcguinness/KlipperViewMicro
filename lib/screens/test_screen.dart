import 'package:flutter/material.dart';
import 'package:klipper_view_micro/widgets/resource_widget.dart';

import '../api/klipper_api.dart';
import '../models/printer_data.dart';

class TestScreen extends StatefulWidget {
  final KlipperApi api;

  const TestScreen({
    Key? key, required this.api,
  }) : super(key: key);
  @override
  _TestScreenState createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  ResourceUsage? _resourceUsage;

  @override
  void initState() {
    super.initState();
    widget.api.resourceUsageStream.listen((resourceUsage) {
      setState(() {
        _resourceUsage = resourceUsage;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        color: Colors.grey.shade900,
        padding: const EdgeInsets.all(5),
        child: _resourceUsage == null
            ? Center(child: CircularProgressIndicator())
            : GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1,
          crossAxisSpacing: 5,
          mainAxisSpacing: 5,
          children: [
            // Cpu
            ResourceWidget(
              usage: _resourceUsage!.cpuUsage,
              title: 'CPU',
              icon: Icons.computer,
              maxValue: 100.0,
              unit: '%',
              progressColors: const [Colors.blue, Colors.orange, Colors.red],
            ),

            // Ram
            ResourceWidget(
              usage: _resourceUsage!.memoryUsed.toDouble()/
                  _resourceUsage!.memoryTotal.toDouble() * 100,
              title: 'Ram',
              icon: Icons.memory,
              maxValue: _resourceUsage!.memoryTotal.toDouble()/1024/1024,
              unit: 'GB',
              progressColors: const [Colors.blue, Colors.orange, Colors.red],
            ),
            // Network
            ResourceWidget(
              usage: _resourceUsage!.rxBytes.toDouble()/1024/1024,
              title: 'Network',
              icon: Icons.network_check,
              maxValue: _resourceUsage!.bandwidth.toDouble(),
              unit: 'MB/s',
              progressColors: const [Colors.blue, Colors.orange, Colors.red],
            ),

          ],
        ),
      ),
    );
  }
}