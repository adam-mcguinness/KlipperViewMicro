class ResourceUsage {
  final double cpuUsage;
  final int memoryTotal;
  final int memoryAvailable;
  final int memoryUsed;
  final int rxBytes;
  final int txBytes;
  final int bandwidth;

  ResourceUsage({
    required this.cpuUsage,
    required this.memoryTotal,
    required this.memoryAvailable,
    required this.memoryUsed,
    required this.rxBytes,
    required this.txBytes,
    required this.bandwidth,
  });

  factory ResourceUsage.fromJson(Map<String, dynamic> json) {
    // Safely access nested values with null checks
    final cpuData = json['system_cpu_usage'] as Map<String, dynamic>?;
    final memoryData = json['system_memory'] as Map<String, dynamic>?;
    final network = json['network']['wlan0'] as Map<String, dynamic>?;

    return ResourceUsage(
      cpuUsage: cpuData?['cpu']?.toDouble() ?? 0.0,
      memoryTotal: memoryData?['total']?.toInt() ?? 0,
      memoryAvailable: memoryData?['available']?.toInt() ?? 0,
      memoryUsed: memoryData?['used']?.toInt() ?? 0, // Fixed: changed from 'available' to 'used'
      rxBytes: network?['rx_packets']?.toInt() ?? 0,
      txBytes: network?['tx_packets']?.toInt() ?? 0,
      bandwidth: network?['bandwidth']?.toInt() ?? 0,
    );
  }

  // Add a static method to create an empty instance
  static ResourceUsage empty() {
    return ResourceUsage(
      cpuUsage: 0.0,
      memoryTotal: 0,
      memoryAvailable: 0,
      memoryUsed: 0,
      rxBytes: 0,
      txBytes: 0,
      bandwidth: 0,
    );
  }
}

class PrintStatus {
  final String state;
  final String filename;
  final int progress;
  final int estimatedTimeLeft;
  final int printTime;
  final int printTimeLeft;

  PrintStatus({
    required this.state,
    required this.filename,
    required this.progress,
    required this.estimatedTimeLeft,
    required this.printTime,
    required this.printTimeLeft,
  });

  factory PrintStatus.fromJson(Map<String, dynamic> json) {
    return PrintStatus(
      state: json['state'] as String? ?? '',
      filename: json['filename'] as String? ?? '',
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      estimatedTimeLeft: (json['estimated_time_left'] as num?)?.toInt() ?? 0,
      printTime: (json['print_time'] as num?)?.toInt() ?? 0,
      printTimeLeft: (json['print_time_left'] as num?)?.toInt() ?? 0,
    );
  }
}