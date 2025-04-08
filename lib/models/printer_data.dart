class TemperatureData {
  final double? current;
  final double? target;
  final double? power;

  TemperatureData({this.current, this.target, this.power});

  factory TemperatureData.fromJson(Map<String, dynamic> json) {
    return TemperatureData(
      current: json['temperature']?.toDouble(),
      target: json['target']?.toDouble(),
      power: json['power']?.toDouble(),
    );
  }

  static TemperatureData empty() {
    return TemperatureData(current: null, target: null, power: null);
  }
}

class ToolheadData {
  final List<double>? position;
  final double? maxVelocity;
  final double? maxAccel;
  final double? maxAccelToDecel;
  final double? squareCornerVelocity;

  ToolheadData({
    this.position,
    this.maxVelocity,
    this.maxAccel,
    this.maxAccelToDecel,
    this.squareCornerVelocity,
  });

  factory ToolheadData.fromJson(Map<String, dynamic> json) {
    return ToolheadData(
      position: json['position'] != null
          ? List<double>.from(json['position'].map((x) => x.toDouble()))
          : null,
      maxVelocity: json['max_velocity']?.toDouble(),
      maxAccel: json['max_accel']?.toDouble(),
      maxAccelToDecel: json['max_accel_to_decel']?.toDouble(),
      squareCornerVelocity: json['square_corner_velocity']?.toDouble(),
    );
  }

  static ToolheadData empty() {
    return ToolheadData(
      position: [0, 0, 0, 0],
      maxVelocity: 0,
      maxAccel: 0,
      maxAccelToDecel: 0,
      squareCornerVelocity: 0,
    );
  }
}

class FanData {
  final double? speed;
  final double? target;

  FanData({this.speed, this.target});

  factory FanData.fromJson(Map<String, dynamic> json) {
    return FanData(
      speed: json['speed']?.toDouble(),
      target: json['target']?.toDouble(),
    );
  }

  static FanData empty() {
    return FanData(speed: 0, target: 0);
  }
}

class PrintStats {
  final String state;
  final String filename;
  final double totalDuration;
  final double printDuration;
  final double filamentUsed;
  final int currentLayer;
  final int totalLayers;

  PrintStats({
    required this.state,
    required this.filename,
    required this.totalDuration,
    required this.printDuration,
    required this.filamentUsed,
    required this.currentLayer,
    required this.totalLayers,
  });

  factory PrintStats.fromJson(Map<String, dynamic> json) {
    return PrintStats(
      state: json['state'] ?? 'standby',
      filename: json['filename'] ?? '',
      totalDuration: json['total_duration']?.toDouble() ?? 0.0,
      printDuration: json['print_duration']?.toDouble() ?? 0.0,
      filamentUsed: json['filament_used']?.toDouble() ?? 0.0,
      currentLayer: json['current_layer'] ?? 0,
      totalLayers: json['total_layer'] ?? 0,
    );
  }

  static PrintStats empty() {
    return PrintStats(
      state: 'standby',
      filename: '',
      totalDuration: 0.0,
      printDuration: 0.0,
      filamentUsed: 0.0,
      currentLayer: 0,
      totalLayers: 0,
    );
  }
}

class VirtualSdCard {
  final bool? isActive;
  final double? progress;
  final double? filePosition;
  final double? fileSize;

  VirtualSdCard({
    this.isActive,
    this.progress,
    this.filePosition,
    this.fileSize,
  });

  factory VirtualSdCard.fromJson(Map<String, dynamic> json) {
    return VirtualSdCard(
      isActive: json['is_active'],
      progress: json['progress']?.toDouble(),
      filePosition: json['file_position']?.toDouble(),
      fileSize: json['file_size']?.toDouble(),
    );
  }

  static VirtualSdCard empty() {
    return VirtualSdCard(
      isActive: false,
      progress: 0.0,
      filePosition: 0.0,
      fileSize: 0.0,
    );
  }
}

class IdleTimeout {
  final String? state;
  final double? idleTimeout;

  IdleTimeout({this.state, this.idleTimeout});

  factory IdleTimeout.fromJson(Map<String, dynamic> json) {
    return IdleTimeout(
      state: json['state'],
      idleTimeout: json['idle_timeout']?.toDouble(),
    );
  }

  static IdleTimeout empty() {
    return IdleTimeout(state: 'Idle', idleTimeout: 0.0);
  }
}

class GcodeMove {
  final double? speedFactor;
  final double? speedRatio;
  final double? extrude_factor;
  final List<double>? position;

  GcodeMove({
    this.speedFactor,
    this.speedRatio,
    this.extrude_factor,
    this.position,
  });

  factory GcodeMove.fromJson(Map<String, dynamic> json) {
    return GcodeMove(
      speedFactor: json['speed_factor']?.toDouble(),
      speedRatio: json['speed']?.toDouble(),
      extrude_factor: json['extrude_factor']?.toDouble(),
      position: json['position'] != null
          ? List<double>.from(json['position'].map((x) => x.toDouble()))
          : null,
    );
  }

  static GcodeMove empty() {
    return GcodeMove(
      speedFactor: 1.0,
      speedRatio: 1.0,
      extrude_factor: 1.0,
      position: [0, 0, 0, 0],
    );
  }
}

class PrinterData {
  final TemperatureData bedTemperature;
  final TemperatureData hotendTemperature;
  final PrintStats printStats;
  final VirtualSdCard virtualSdCard;
  final ToolheadData toolhead;
  final FanData fan;
  final IdleTimeout idleTimeout;
  final GcodeMove gcodeMove;

  PrinterData({
    required this.bedTemperature,
    required this.hotendTemperature,
    required this.printStats,
    required this.virtualSdCard,
    required this.toolhead,
    required this.fan,
    required this.idleTimeout,
    required this.gcodeMove,
  });

  factory PrinterData.fromJson(Map<String, dynamic> json) {
    return PrinterData(
      bedTemperature: json.containsKey('heater_bed')
          ? TemperatureData.fromJson(json['heater_bed'])
          : TemperatureData.empty(),
      hotendTemperature: json.containsKey('extruder')
          ? TemperatureData.fromJson(json['extruder'])
          : TemperatureData.empty(),
      printStats: json.containsKey('print_stats')
          ? PrintStats.fromJson(json['print_stats'])
          : PrintStats.empty(),
      virtualSdCard: json.containsKey('virtual_sdcard')
          ? VirtualSdCard.fromJson(json['virtual_sdcard'])
          : VirtualSdCard.empty(),
      toolhead: json.containsKey('toolhead')
          ? ToolheadData.fromJson(json['toolhead'])
          : ToolheadData.empty(),
      fan: json.containsKey('fan')
          ? FanData.fromJson(json['fan'])
          : FanData.empty(),
      idleTimeout: json.containsKey('idle_timeout')
          ? IdleTimeout.fromJson(json['idle_timeout'])
          : IdleTimeout.empty(),
      gcodeMove: json.containsKey('gcode_move')
          ? GcodeMove.fromJson(json['gcode_move'])
          : GcodeMove.empty(),
    );
  }

  static PrinterData empty() {
    return PrinterData(
      bedTemperature: TemperatureData.empty(),
      hotendTemperature: TemperatureData.empty(),
      printStats: PrintStats.empty(),
      virtualSdCard: VirtualSdCard.empty(),
      toolhead: ToolheadData.empty(),
      fan: FanData.empty(),
      idleTimeout: IdleTimeout.empty(),
      gcodeMove: GcodeMove.empty(),
    );
  }
}