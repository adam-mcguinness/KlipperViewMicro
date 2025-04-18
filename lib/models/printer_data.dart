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
    // Handle different possible structures in JSON-RPC responses
    Map<String, dynamic>? cpuData;
    Map<String, dynamic>? memoryData;
    Map<String, dynamic>? network;

    // Check if this is the toolhead data or system stats
    if (json.containsKey('system_cpu_usage')) {
      cpuData = json['system_cpu_usage'];
      memoryData = json['system_memory'];
      network = json['network']?['wlan0'];
    } else {
      // This might be toolhead data
      cpuData = {'cpu': json['velocity'] ?? 0.0};
      memoryData = {
        'total': 0,
        'available': 0,
        'used': 0,
      };
      network = {
        'rx_packets': 0,
        'tx_packets': 0,
        'bandwidth': 0,
      };
    }

    return ResourceUsage(
      cpuUsage: cpuData?['cpu']?.toDouble() ?? 0.0,
      memoryTotal: memoryData?['total']?.toInt() ?? 0,
      memoryAvailable: memoryData?['available']?.toInt() ?? 0,
      memoryUsed: memoryData?['used']?.toInt() ?? 0,
      rxBytes: network?['rx_packets']?.toInt() ?? 0,
      txBytes: network?['tx_packets']?.toInt() ?? 0,
      bandwidth: network?['bandwidth']?.toInt() ?? 0,
    );
  }

  // Static method to create an empty instance
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

class PrintStats{
  final String? fileName;
  final double totalDuration;
  final double printDuration;
  final String state;

  PrintStats({
    this.fileName,
    this.totalDuration = 0.0,
    this.printDuration = 0.0,
    this.state = '',
  });

  factory PrintStats.fromJson(Map<String, dynamic> json) {
    return PrintStats(
      fileName: json['file_name'] as String?,
      totalDuration: (json['total_duration'] as num?)?.toDouble() ?? 0.0,
      printDuration: (json['print_duration'] as num?)?.toDouble() ?? 0.0,
      state: json['state'] as String? ?? '',
    );
  }

  // Create an empty print stats
  static PrintStats empty() {
    return PrintStats(
      fileName: null,
      totalDuration: 0.0,
      printDuration: 0.0,
      state: '',
    );
  }
}

class VirtualSdCard{
  final String? filePath;
  final double progress;
  final bool isActive;

  VirtualSdCard({
    this.filePath,
    this.progress = 0.0,
    this.isActive = false,
  });

  factory VirtualSdCard.fromJson(Map<String, dynamic> json) {
    return VirtualSdCard(
      filePath: json['file_path'] as String?,
      progress: json['progress'] ?? 0.0,
      isActive: json['is_active'] as bool? ?? false,
    );
  }
}

class HeaterBed{
  final double currentTemperature;
  final double targetTemperature;
  final String state;

  HeaterBed({
    required this.currentTemperature,
    required this.targetTemperature,
    required this.state,
  });

  factory HeaterBed.fromJson(Map<String, dynamic> json) {
    // Handle different possible field names in JSON-RPC responses
    return HeaterBed(
      currentTemperature: json['temperature']?? 0.0,
      targetTemperature: json['target']?? 0.0,
      state: json['state'] as String? ?? '',
    );
  }

  // Create an empty heater bed status
  static HeaterBed empty() {
    return HeaterBed(
      currentTemperature: 0.0,
      targetTemperature: 0.0,
      state: '',
    );
  }
}

class Extruder {
  final double currentTemperature;
  final double targetTemperature;
  final String state;

  Extruder({
    required this.currentTemperature,
    required this.targetTemperature,
    required this.state,
  });

  factory Extruder.fromJson(Map<String, dynamic> json) {
    // Similar to HeaterBed - handle different possible field names
    return Extruder(
      currentTemperature: json['temperature']?? 0.0,
      targetTemperature: json['target']?? 0.0,
      state: json['state'] as String? ?? '',
    );
  }

  // Create an empty extruder status
  static Extruder empty() {
    return Extruder(
      currentTemperature: 0.0,
      targetTemperature: 0.0,
      state: '',
    );
  }
}

class PrintFile {
  final String path;
  final int size;
  final String filename;

  PrintFile({
    required this.path,
    required this.size,
    required this.filename,
  });

  factory PrintFile.fromJson(Map<String, dynamic> json) {
    final path = json['path'] ?? '';
    return PrintFile(
      path: path,
      size: json['size'] ?? 0,
      filename: json['filename'] ?? path.split('/').last,
    );
  }
}