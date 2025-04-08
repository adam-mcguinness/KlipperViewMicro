import 'dart:async';

import 'package:flutter/material.dart';
import 'package:klipper_view_micro/utils/swipe_up_home.dart';
import 'package:klipper_view_micro/widgets/resource_widget.dart';
import '../models/printer_data.dart';
import '../services/api_services.dart';

class SystemUsage extends StatefulWidget {
  const SystemUsage({super.key});

  @override
  _SystemUsageState createState() => _SystemUsageState();
}

class _SystemUsageState extends State<SystemUsage> {
  ResourceUsage? _resourceUsage;
  StreamSubscription? _subscription; // Store subscription to cancel later

  @override
  void initState() {
    super.initState();
    // Store the subscription
    _subscription = ApiService().api.resourceUsageStream.listen((resourceUsage) {
      // Check if widget is still mounted before calling setState
      if (mounted) {
        setState(() {
          _resourceUsage = resourceUsage;
        });
      }
    });
  }

  @override
  void dispose() {
    // Cancel subscription when widget is disposed
    _subscription?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Wrap the body with GestureDetector to detect swipe up
      body: SwipeUpWrapper(
        child: Container(
            color: Colors.grey.shade900,
            padding: const EdgeInsets.all(5),
            child: _resourceUsage == null
                ? Center(child: CircularProgressIndicator())
                : GridView.count(
              // Set physics to prevent the GridView from interfering with the swipe gesture
              physics: const ClampingScrollPhysics(),
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
      ),
      );
  }
}