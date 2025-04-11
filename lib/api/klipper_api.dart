import 'dart:async';
import 'dart:convert';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:klipper_view_micro/models/printer_data.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../utils/constants.dart';

class KlipperApi {
  static final KlipperApi _instance = KlipperApi._internal();

  factory KlipperApi() => _instance;

  KlipperApi._internal();

  Peer? _peer;
  WebSocketChannel? _channel;
  bool isConnected = false;

  String ipAddress = AppConstants.defaultIpAddress;
  int port = AppConstants.defaultPort;

  PrintStatus? _lastKnownPrintStatus;

  final _printStatusStream = StreamController<PrintStatus>.broadcast();
  Stream<PrintStatus> get printStatus => _printStatusStream.stream;

  final _resourceUsageStream = StreamController<ResourceUsage>.broadcast();
  Stream<ResourceUsage> get resourceUsage => _resourceUsageStream.stream;

  final _heaterBedStream = StreamController<HeaterBed>.broadcast();
  Stream<HeaterBed> get heaterBedStatus => _heaterBedStream.stream;

  final _extruderStream = StreamController<Extruder>.broadcast();
  Stream<Extruder> get extruderStatus => _extruderStream.stream;

  // Fix: Update method parameters to avoid variable shadowing
  void updateConnectionDetails({String? newIpAddress, int? newPort}) {
    if (newIpAddress != null) this.ipAddress = newIpAddress;
    if (newPort != null) this.port = newPort;
  }

  String get webSocketUrl => 'ws://$ipAddress:$port/websocket';

  Future<bool> connect() async {
    if (isConnected) {
      await dispose();
    }

    try {
      final url = webSocketUrl;
      print('Attempting to connect to: $url');

      _channel = WebSocketChannel.connect(Uri.parse(url));
      _peer = Peer(_channel!.cast<String>());

      // Register methods to handle server notifications
      _peer!.registerMethod('notify_status_update', (Parameters params) {
        try {
          if (params.value is List && params.value.isNotEmpty && params.value[0] is Map<String, dynamic>) {
            final statusData = params.value[0] as Map<String, dynamic>;

            // Process each component type
            _processComponentUpdates(statusData);
          }
        } catch (e) {
          print('Error processing status update: $e');
        }
        return null;
      });

      _peer!.registerMethod('notify_proc_stat_update', (Parameters params) {
        try {
          if (params.value is List && params.value.isNotEmpty && params.value.first is Map<String, dynamic>) {
            final resourceUsage = ResourceUsage.fromJson(params.value.first);
            _resourceUsageStream.add(resourceUsage);
          }
        } catch (e) {
          print('Error processing resource update: $e');
        }
        return null; // No response needed for notifications
      });

      // Start listening for messages
      unawaited(_peer!.listen());
      isConnected = true;

      // Add a dummy print status for the UI to show something initially
      _printStatusStream.add(PrintStatus(
        state: 'standby',
        filename: 'test_file.gcode',
        progress: 0.0,
        estimatedTimeLeft: 0,
        printTimeLeft: 0,
      ));

      // Send subscription request
      await call('printer.objects.subscribe', {
        "objects": {
          "heater_bed": null,
          "extruder": null,
          "print_stats": null,
          "virtual_sdcard": null,
        }
      });

      print('Connected to Klipper server: $url');
      return true;
    } catch (e) {
      isConnected = false;
      print('Failed to connect to Klipper server: $e');

      // Even if connection fails, emit dummy data so UI shows something
      _emitDummyStatus();

      return false;
    }
  }

  void _processComponentUpdates(Map<String, dynamic> statusData) {
    // For each known component type, check if it's in the update
    // and convert it to the appropriate class

    if (statusData.containsKey('heater_bed')) {
      final bedData = statusData['heater_bed'];
      if (bedData is Map<String, dynamic>) {
        final bedStatus = HeaterBed.fromJson(bedData);
        _heaterBedStream.add(bedStatus);
      }
    }

    if (statusData.containsKey('extruder')) {
      final extruderData = statusData['extruder'];
      if (extruderData is Map<String, dynamic>) {
        final extruderStatus = Extruder.fromJson(extruderData);
        _extruderStream.add(extruderStatus);
      }
    }

    if (statusData.containsKey('print_stats') || statusData.containsKey('virtual_sdcard')) {
      // Log for debugging
      if (statusData.containsKey('virtual_sdcard')) {
        print('virtualSdcard status: $statusData');
      }

      // Create new status by merging current with incoming data
      final updatedStatus = PrintStatus.fromStatusData(statusData, _lastKnownPrintStatus);

      // Store the last known status for future updates
      _lastKnownPrintStatus = updatedStatus;

      // Always emit the new status
      _printStatusStream.add(updatedStatus);
    }

    // Add other component types as needed
  }

  // Emit dummy data to ensure UI always shows something
  void _emitDummyStatus() {
    _printStatusStream.add(PrintStatus(
      state: 'standby',
      filename: 'test_file.gcode',
      progress: 0.5, // Show 50% progress in the UI
      estimatedTimeLeft: 0,
      printTimeLeft: 0,
    ));
  }

  Future<dynamic> call(String method, [dynamic params]) async {
    if (!isConnected || _peer == null) {
      throw Exception('Not connected to Klipper server');
    }

    try {
      return await _peer!.sendRequest(method, params);
    } catch (e) {
      print('Error calling method $method: $e');
      rethrow;
    }
  }

  void sendNotification(String method, [dynamic params]) {
    if (!isConnected || _peer == null) {
      throw Exception('Not connected to Klipper server');
    }

    try {
      _peer!.sendNotification(method, params);
    } catch (e) {
      print('Error sending notification $method: $e');
      rethrow;
    }
  }

  Future<void> dispose() async {
    if (!isConnected) return;

    try {
      await _peer?.close();
      await _channel?.sink.close();
      print('Disconnected from Klipper server');
    } catch (e) {
      print('Error closing connection: $e');
    } finally {
      _peer = null;
      _channel = null;
      isConnected = false;
    }
  }
}