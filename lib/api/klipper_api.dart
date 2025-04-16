import 'dart:async';
import 'dart:convert';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:klipper_view_micro/models/printer_data.dart';
import 'package:rxdart/rxdart.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../utils/constants.dart';

class KlipperApi {
  static final KlipperApi _instance = KlipperApi._internal();

  factory KlipperApi() => _instance;

  KlipperApi._internal();

  Peer? _peer;
  WebSocketChannel? _channel;
  bool isConnected = false;

  String ipAddress = '127.0.0.1';
  int port = AppConstants.defaultPort;

  // Use BehaviorSubjects to cache the latest value
  final _printStatsSubject = BehaviorSubject<PrintStats>.seeded(PrintStats.empty());
  final _resourceUsageSubject = BehaviorSubject<ResourceUsage>.seeded(ResourceUsage.empty());
  final _heaterBedSubject = BehaviorSubject<HeaterBed>.seeded(HeaterBed.empty());
  final _extruderSubject = BehaviorSubject<Extruder>.seeded(Extruder.empty());
  final _virtualSdCardSubject = BehaviorSubject<VirtualSdCard>.seeded(VirtualSdCard());

  // Throttled streams - update at most once every 250ms
  late final Stream<PrintStats> printStatus;
  late final Stream<ResourceUsage> resourceUsage;
  late final Stream<HeaterBed> heaterBedStatus;
  late final Stream<Extruder> extruderStatus;
  late final Stream<VirtualSdCard> virtualSdCardStatus;

  // Direct access to latest values (doesn't require subscription)
  PrintStats get latestPrintStats => _printStatsSubject.value;
  ResourceUsage get latestResourceUsage => _resourceUsageSubject.value;
  HeaterBed get latestHeaterBed => _heaterBedSubject.value;
  Extruder get latestExtruder => _extruderSubject.value;
  VirtualSdCard get latestVirtualSdCard => _virtualSdCardSubject.value;


  void _initStreams() {
    final throttleDuration = Duration(milliseconds: 250);

    // Apply throttling to each stream
    printStatus = _printStatsSubject.stream
        .throttleTime(throttleDuration)
        .distinct();

    resourceUsage = _resourceUsageSubject.stream
        .throttleTime(throttleDuration)
        .distinct();

    heaterBedStatus = _heaterBedSubject.stream
        .throttleTime(throttleDuration)
        .distinct();

    extruderStatus = _extruderSubject.stream
        .throttleTime(throttleDuration)
        .distinct();

    virtualSdCardStatus = _virtualSdCardSubject.stream
        .throttleTime(throttleDuration)
        .distinct();
  }

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

      _initStreams();

      // Register methods to handle server notifications
      _peer!.registerMethod('notify_status_update', (Parameters params) {
        try {
          // print('Received status update: ${params.value}');

          // Extract component data from the list format
          if (params.value is List && params.value.isNotEmpty) {
            // First element contains the update data
            final updateData = params.value[0];
            if (updateData is Map<String, dynamic>) {
              _processComponentUpdates(updateData);
            }
          } else if (params.value is Map<String, dynamic>) {
            // If already a map, process directly
            _processComponentUpdates(params.value);
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
            _resourceUsageSubject.add(resourceUsage);
          }
        } catch (e) {
          print('Error processing resource update: $e');
        }
        return null; // No response needed for notifications
      });

      // Start listening for messages
      unawaited(_peer!.listen());
      isConnected = true;

      _getInitialStatus();

      print('Connected to Klipper server: $url');
      return true;
    } catch (e) {
      isConnected = false;
      print('Failed to connect to Klipper server: $e');

      // Even if connection fails, emit dummy data so UI shows something

      return false;
    }
  }

  void _processComponentUpdates(Map<String, dynamic> statusData) {
    if (statusData.containsKey('heater_bed')) {
      final bedData = statusData['heater_bed'];
      if (bedData is Map<String, dynamic>) {
        final bedStatus = HeaterBed.fromJson(bedData);
        _heaterBedSubject.add(bedStatus);
      }
    }

    if (statusData.containsKey('extruder')) {
      final extruderData = statusData['extruder'];
      if (extruderData is Map<String, dynamic>) {
        final extruderStatus = Extruder.fromJson(extruderData);
        _extruderSubject.add(extruderStatus);
      }
    }

    if (statusData.containsKey('print_stats')) {
      final updatedStats = PrintStats.fromJson(statusData['print_stats']);
      _printStatsSubject.add(updatedStats);
    }

    if (statusData.containsKey('virtual_sdcard')) {
      final sdCardData = statusData['virtual_sdcard'];
      if (sdCardData is Map<String, dynamic>) {
        final sdCardStatus = VirtualSdCard.fromJson(sdCardData);
        _virtualSdCardSubject.add(sdCardStatus);
      }
    }

    // Add other component types as needed
  }

  Future<void> _getInitialStatus() async {
    final response = await call('printer.objects.subscribe', {
      "objects": {
        "heater_bed": null,
        "extruder": null,
        "print_stats": null,
        "virtual_sdcard": null,
      }
    });
    print('Initial status response: $response');
    _processComponentUpdates(response['status']);
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