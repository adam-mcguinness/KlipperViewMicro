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

class PrintStatus {
  // Primary print state information
  final String state;
  final String filename;
  final double progress;

  // Time information
  final int totalDuration;     // From print_stats.total_duration
  final int printTimeLeft;     // Calculated or from estimates
  final int estimatedTimeLeft; // From estimates

  // File information
  final String? filePath;      // From virtual_sdcard.file_path
  final int filePosition;      // From virtual_sdcard.file_position
  final bool isActive;         // From virtual_sdcard.is_active

  PrintStatus({
    required this.state,
    required this.filename,
    required this.progress,
    this.totalDuration = 0,
    this.printTimeLeft = 0,
    this.estimatedTimeLeft = 0,
    this.filePath,
    this.filePosition = 0,
    this.isActive = false,
  });

  // Create an empty print status
  static PrintStatus empty() {
    return PrintStatus(
      state: 'standby',
      filename: '',
      progress: 0.0,
    );
  }

  // Factory constructor to create from combined data
  factory PrintStatus.fromStatusData(Map<String, dynamic> statusData, [PrintStatus? current]) {
    // Start with current status or empty
    final currentStatus = current ?? PrintStatus.empty();

    // Initialize with current values
    String state = currentStatus.state;
    String filename = currentStatus.filename;
    double progress = currentStatus.progress;
    int totalDuration = currentStatus.totalDuration;
    int printTimeLeft = currentStatus.printTimeLeft;
    int estimatedTimeLeft = currentStatus.estimatedTimeLeft;
    String? filePath = currentStatus.filePath;
    int filePosition = currentStatus.filePosition;
    bool isActive = currentStatus.isActive;

    // Extract data from print_stats if available
    if (statusData.containsKey('print_stats')) {
      final printStats = statusData['print_stats'];
      if (printStats is Map<String, dynamic>) {
        // Update state if available
        if (printStats.containsKey('state')) {
          state = printStats['state'] as String;
        }

        // Update filename if available
        if (printStats.containsKey('filename')) {
          filename = printStats['filename'] as String;
        }

        // Update total_duration if available
        if (printStats.containsKey('total_duration')) {
          totalDuration = (printStats['total_duration'] as num).toInt();
        }

        // Update estimated_time_left if available
        if (printStats.containsKey('estimated_time_left')) {
          estimatedTimeLeft = (printStats['estimated_time_left'] as num).toInt();
        }

        // Update print_time_left if available
        if (printStats.containsKey('print_time_left')) {
          printTimeLeft = (printStats['print_time_left'] as num).toInt();
        }
      }
    }

    // Extract data from virtual_sdcard if available
    if (statusData.containsKey('virtual_sdcard')) {
      final sdcard = statusData['virtual_sdcard'];
      if (sdcard is Map<String, dynamic>) {
        // Update progress if available
        if (sdcard.containsKey('progress')) {
          progress = (sdcard['progress'] as num).toDouble();
        }

        // Update file_path if available
        if (sdcard.containsKey('file_path')) {
          filePath = sdcard['file_path'] as String;

          // If we don't have a filename but have a file path, extract filename from path
          if (filename.isEmpty && filePath != null) {
            final parts = filePath.split('/');
            if (parts.isNotEmpty) {
              filename = parts.last;
            }
          }
        }

        // Update is_active if available
        if (sdcard.containsKey('is_active')) {
          isActive = sdcard['is_active'] as bool;
        }

        // Update file_position if available
        if (sdcard.containsKey('file_position')) {
          filePosition = (sdcard['file_position'] as num).toInt();
        }
      }
    }

    // Create and return the new status
    return PrintStatus(
      state: state,
      filename: filename,
      progress: progress,
      totalDuration: totalDuration,
      printTimeLeft: printTimeLeft,
      estimatedTimeLeft: estimatedTimeLeft,
      filePath: filePath,
      filePosition: filePosition,
      isActive: isActive,
    );
  }

  // Create a copy with updated fields
  PrintStatus copyWith({
    String? state,
    String? filename,
    double? progress,
    int? totalDuration,
    int? printTimeLeft,
    int? estimatedTimeLeft,
    String? filePath,
    int? filePosition,
    bool? isActive,
  }) {
    return PrintStatus(
      state: state ?? this.state,
      filename: filename ?? this.filename,
      progress: progress ?? this.progress,
      totalDuration: totalDuration ?? this.totalDuration,
      printTimeLeft: printTimeLeft ?? this.printTimeLeft,
      estimatedTimeLeft: estimatedTimeLeft ?? this.estimatedTimeLeft,
      filePath: filePath ?? this.filePath,
      filePosition: filePosition ?? this.filePosition,
      isActive: isActive ?? this.isActive,
    );
  }

  // Calculate the print time for compatibility with older code
  int get printTime => totalDuration;

  // For comparing if the status has changed
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PrintStatus &&
        other.state == state &&
        other.filename == filename &&
        other.progress == progress &&
        other.totalDuration == totalDuration &&
        other.printTimeLeft == printTimeLeft &&
        other.estimatedTimeLeft == estimatedTimeLeft &&
        other.filePath == filePath &&
        other.filePosition == filePosition &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return state.hashCode ^
    filename.hashCode ^
    progress.hashCode ^
    totalDuration.hashCode ^
    printTimeLeft.hashCode ^
    estimatedTimeLeft.hashCode ^
    filePath.hashCode ^
    filePosition.hashCode ^
    isActive.hashCode;
  }

  @override
  String toString() {
    return 'PrintStatus(state: $state, filename: $filename, progress: $progress, '
        'totalDuration: $totalDuration, printTimeLeft: $printTimeLeft, '
        'isActive: $isActive)';
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
      currentTemperature: _extractTemp(json, 'current'),
      targetTemperature: _extractTemp(json, 'target'),
      state: json['state'] as String? ?? '',
    );
  }

  // Helper method to extract temperature which might use different field names
  static double _extractTemp(Map<String, dynamic> json, String type) {
    // Check various possible field names
    if (json.containsKey('${type}_temperature')) {
      return (json['${type}_temperature'] as num?)?.toDouble() ?? 0.0;
    } else if (json.containsKey('${type}')) {
      return (json['${type}'] as num?)?.toDouble() ?? 0.0;
    } else if (json.containsKey('temperature_${type}')) {
      return (json['temperature_${type}'] as num?)?.toDouble() ?? 0.0;
    }
    return 0.0;
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
      currentTemperature: HeaterBed._extractTemp(json, 'current'),
      targetTemperature: HeaterBed._extractTemp(json, 'target'),
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
  final DateTime? modified;
  final String? filename;

  PrintFile({
    required this.path,
    required this.size,
    this.modified,
    this.filename,
  });

  factory PrintFile.fromJson(Map<String, dynamic> json) {
    return PrintFile(
      path: json['path'] ?? '',
      size: json['size'] ?? 0,
      modified: json['modified'] != null
          ? DateTime.fromMillisecondsSinceEpoch((json['modified'] as num).toInt() * 1000)
          : null,
      filename: json['filename'] ?? json['path']?.toString().split('/').last,
    );
  }
}

class FileList {
  final List<PrintFile> files;

  FileList({
    required this.files
  });

  // Create an empty file list
  static FileList empty() {
    return FileList(files: []);
  }
}

// New class to handle JSON-RPC response
class JsonRpcResponse {
  final dynamic result;
  final Map<String, dynamic>? error;
  final String jsonrpc;
  final dynamic id;

  JsonRpcResponse({
    this.result,
    this.error,
    required this.jsonrpc,
    required this.id,
  });

  factory JsonRpcResponse.fromJson(Map<String, dynamic> json) {
    return JsonRpcResponse(
      result: json['result'],
      error: json['error'] != null ? json['error'] as Map<String, dynamic> : null,
      jsonrpc: json['jsonrpc'] as String? ?? '2.0',
      id: json['id'],
    );
  }

  bool get hasError => error != null;
}