import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/printer_data.dart';

class KlipperApi {
  final String ipAddress;
  final String port;
  late String baseUrl;
  late String wsUrl;

  WebSocketChannel? _socketChannel;

  // Fix the stream controller declaration
  StreamController<ResourceUsage> _resourceUsageStreamController = StreamController<ResourceUsage>.broadcast();
  StreamController<String> _stateStreamController = StreamController<String>.broadcast();

  // Streams that clients can listen to for updates
  Stream<ResourceUsage> get resourceUsageStream => _resourceUsageStreamController.stream;
  Stream<String> get stateStream => _stateStreamController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  String _currentState = "disconnected";
  String get currentState => _currentState;

  KlipperApi({required this.ipAddress, required this.port}) {
    baseUrl = 'http://$ipAddress:$port';
    wsUrl = 'ws://$ipAddress:$port/websocket';
  }

  // Initialize WebSocket connection and start listening
  Future<bool> connect() async {
    try {
      // First test HTTP connection
      final success = await testConnection();
      if (!success) {
        return false;
      }

      // Initialize WebSocket connection
      _socketChannel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Send the subscription message for printer updates
      _socketChannel!.sink.add(jsonEncode({
        "jsonrpc": "2.0",
        "method": "printer.objects.subscribe",
        "params": {
          "objects": {
            "heater_bed": null,
            "extruder": null,
            "print_stats": null,
            "toolhead": null,
            "virtual_sdcard": null,
            "fan": null,
            "idle_timeout": null,
            "server": null,
            "gcode_move": null
          }
        },
        "id": 4564
      }));

      // Subscribe to printer state notifications
      _socketChannel!.sink.add(jsonEncode({
        "jsonrpc": "2.0",
        "method": "notify_status_update",
        "params": {
          "subscribe": true
        },
        "id": 5644
      }));

      // Listen for incoming data
      _socketChannel!.stream.listen(
              (dynamic message) {
            _handleWebSocketMessage(message);
          },
          onError: (error) {
            print('WebSocket Error: $error');
            _isConnected = false;
            _currentState = "error";
            _stateStreamController.add(_currentState);
          },
          onDone: () {
            print('WebSocket connection closed');
            _isConnected = false;
            _currentState = "disconnected";
            _stateStreamController.add(_currentState);
          }
      );

      _isConnected = true;
      _currentState = "connected";
      _stateStreamController.add(_currentState);

      return true;
    } catch (e) {
      print('WebSocket connection error: $e');
      _isConnected = false;
      _currentState = "error";
      _stateStreamController.add(_currentState);
      return false;
    }
  }

  // Handle incoming WebSocket messages
  void _handleWebSocketMessage(dynamic message) {
    try {
      // For debugging purposes
      print('WebSocket received: $message');

      // Try to decode the message
      dynamic data;
      if (message is String) {
        data = jsonDecode(message);
      } else {
        // If it's already decoded (like a List or Map)
        data = message;
      }

      // Handle resource stats update
      if (data['method'] == 'notify_proc_stat_update' &&
          data['params'] is List &&
          data['params'].isNotEmpty) {
        final procStats = data['params'][0];
        final resourceUsage = ResourceUsage.fromJson(procStats);
        _resourceUsageStreamController.add(resourceUsage);
      }
    } catch (e) {
      print('Error processing WebSocket message: $e');
    }
  }

  // Test connection to the Klipper instance
  Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/printer/info'),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('Connection error: $e');
      return false;
    }
  }

  // Fetch printer temperature data (HTTP fallback)
  Future<Map<String, dynamic>> fetchTemperatureData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/printer/objects/query?heater_bed&extruder&print_stats&virtual_sdcard&toolhead&fan&idle_timeout&gcode_move'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['result']['status'];
      } else {
        throw Exception('Failed to load temperature data');
      }
    } catch (e) {
      print('Error fetching printer data: $e');
      return {};
    }
  }

  // Fetch files from the printer
  // Future<List<PrintFile>> fetchFiles() async {
  //   try {
  //     final response = await http.get(
  //       Uri.parse('$baseUrl/server/files/list'),
  //     );
  //
  //     if (response.statusCode == 200) {
  //       final Map<String, dynamic> data = json.decode(response.body);
  //       final List<dynamic> filesList = data['result'] ?? [];
  //
  //       final files = filesList
  //           .where((file) => file['filename'].toString().endsWith('.gcode'))
  //           .map((file) => PrintFile(
  //         name: file['filename'] ?? '',
  //         path: file['path'] ?? '',
  //         size: file['size'] ?? 0,
  //         modified: DateTime.fromMillisecondsSinceEpoch(
  //             (file['modified'] ?? 0) * 1000),
  //       ))
  //           .toList();
  //
  //       _filesStreamController.add(files);
  //       return files;
  //     } else {
  //       throw Exception('Failed to load files');
  //     }
  //   } catch (e) {
  //     print('Error fetching files: $e');
  //     return [];
  //   }
  // }

  // Start a print job
  Future<bool> startPrint(String filename) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/printer/print/start'),
        body: {'filename': filename},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error starting print: $e');
      return false;
    }
  }

  // Pause the current print
  Future<bool> pausePrint() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/printer/print/pause'),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error pausing print: $e');
      return false;
    }
  }

  // Resume the current print
  Future<bool> resumePrint() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/printer/print/resume'),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error resuming print: $e');
      return false;
    }
  }

  // Cancel the current print
  Future<bool> cancelPrint() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/printer/print/cancel'),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error cancelling print: $e');
      return false;
    }
  }

  // Restart the current print
  Future<bool> restartPrint() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/printer/print/restart'),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error restarting print: $e');
      return false;
    }
  }

  // Send G-code commands
  Future<bool> sendGcode(String script) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/printer/gcode/script'),
        body: {'script': script},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error sending G-code: $e');
      return false;
    }
  }

  // Home specific axes
  Future<bool> homeAxis(String axes) async {
    return sendGcode('G28 $axes');
  }

  // Move printer head to absolute position
  Future<bool> moveHeadAbsolute({double? x, double? y, double? z, double? speed}) async {
    String gcode = 'G90\nG1';
    if (x != null) gcode += ' X$x';
    if (y != null) gcode += ' Y$y';
    if (z != null) gcode += ' Z$z';
    if (speed != null) gcode += ' F$speed';

    return sendGcode(gcode);
  }

  // Move printer head by relative distance
  Future<bool> moveHeadRelative({double? x, double? y, double? z, double? speed}) async {
    String gcode = 'G91\nG1';
    if (x != null) gcode += ' X$x';
    if (y != null) gcode += ' Y$y';
    if (z != null) gcode += ' Z$z';
    if (speed != null) gcode += ' F$speed';
    gcode += '\nG90';

    return sendGcode(gcode);
  }

  // Set bed temperature
  Future<bool> setBedTemperature(double temperature) async {
    return sendGcode('M140 S$temperature');
  }

  // Set hotend temperature
  Future<bool> setHotendTemperature(double temperature, {int index = 0}) async {
    if (index == 0) {
      return sendGcode('M104 S$temperature');
    } else {
      return sendGcode('M104 P$index S$temperature');
    }
  }

  // Set fan speed (0-255 or 0.0-1.0)
  Future<bool> setFanSpeed(dynamic speed) async {
    // Convert 0.0-1.0 to 0-255 if needed
    int fanSpeed;
    if (speed is double && speed <= 1.0) {
      fanSpeed = (speed * 255).round();
    } else {
      fanSpeed = speed.round();
    }

    return sendGcode('M106 S$fanSpeed');
  }

  // Turn off fans
  Future<bool> fanOff() async {
    return sendGcode('M107');
  }

  // Extrude/retract filament
  Future<bool> extrude(double length, {double? speed, int index = 0}) async {
    String gcode = 'G91\nG1 E$length';
    if (speed != null) gcode += ' F$speed';
    gcode += '\nG90';

    return sendGcode(gcode);
  }

  // Emergency stop
  Future<bool> emergencyStop() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/printer/emergency_stop'),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error sending emergency stop: $e');
      return false;
    }
  }

  // Restart firmware
  Future<bool> firmwareRestart() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/printer/firmware_restart'),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error restarting firmware: $e');
      return false;
    }
  }

  // Request system info
  Future<Map<String, dynamic>> getSystemInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/server/info'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['result'] ?? {};
      } else {
        throw Exception('Failed to get system info');
      }
    } catch (e) {
      print('Error getting system info: $e');
      return {};
    }
  }

  // Get printer config
  Future<Map<String, dynamic>> getPrinterConfig() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/printer/info'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['result'] ?? {};
      } else {
        throw Exception('Failed to get printer config');
      }
    } catch (e) {
      print('Error getting printer config: $e');
      return {};
    }
  }

  // Run bed mesh calibration
  Future<bool> runBedMeshCalibration() async {
    return sendGcode('BED_MESH_CALIBRATE');
  }

  // Save mesh to profile (default profile name is "default")
  Future<bool> saveBedMesh({String profile = 'default'}) async {
    return sendGcode('BED_MESH_PROFILE SAVE=$profile');
  }

  // Load mesh profile (default profile name is "default")
  Future<bool> loadBedMesh({String profile = 'default'}) async {
    return sendGcode('BED_MESH_PROFILE LOAD=$profile');
  }

  // Clear current bed mesh
  Future<bool> clearBedMesh() async {
    return sendGcode('BED_MESH_CLEAR');
  }

  // Run quad gantry level (for Voron printers)
  Future<bool> runQuadGantryLevel() async {
    return sendGcode('QUAD_GANTRY_LEVEL');
  }

  // Run Z-tilt adjust (for Voron printers)
  Future<bool> runZTiltAdjust() async {
    return sendGcode('Z_TILT_ADJUST');
  }

  // PID tuning for bed
  Future<bool> pidTuneBed(double target) async {
    return sendGcode('PID_CALIBRATE HEATER=heater_bed TARGET=$target');
  }

  // PID tuning for hotend
  Future<bool> pidTuneHotend(double target, {int index = 0}) async {
    String heater = index == 0 ? 'extruder' : 'extruder$index';
    return sendGcode('PID_CALIBRATE HEATER=$heater TARGET=$target');
  }

  // Save PID tuning results
  Future<bool> savePidTuning() async {
    return sendGcode('SAVE_CONFIG');
  }

  // Set print speed factor (percentage)
  Future<bool> setPrintSpeedFactor(int percentage) async {
    return sendGcode('M220 S$percentage');
  }

  // Set flow rate factor (percentage)
  Future<bool> setFlowRateFactor(int percentage) async {
    return sendGcode('M221 S$percentage');
  }

  // Get printer status including which macros are available
  Future<Map<String, dynamic>> getPrinterStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/printer/objects/list'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['result'] ?? {};
      } else {
        throw Exception('Failed to get printer status');
      }
    } catch (e) {
      print('Error getting printer status: $e');
      return {};
    }
  }

  // Run a custom macro
  Future<bool> runMacro(String macroName) async {
    return sendGcode(macroName);
  }

  // Disconnect and clean up
  void disconnect() {
    _socketChannel?.sink.close();
    _isConnected = false;
    _currentState = "disconnected";
    _stateStreamController.add(_currentState);
  }

  // Dispose of resources
  void dispose() {
    disconnect();
    _resourceUsageStreamController.close();
    _stateStreamController.close();
  }
}