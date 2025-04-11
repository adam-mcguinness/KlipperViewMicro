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

  Client? _client;
  WebSocketChannel? _channel;
  bool isConnected = false;

  String ipAddress = AppConstants.defaultIpAddress;
  int port = AppConstants.defaultPort;

  final _printStatusStream = StreamController<PrintStatus>.broadcast();
  Stream<PrintStatus> get printStatus => _printStatusStream.stream;

  final _resourceUsageStream = StreamController<ResourceUsage>.broadcast();
  Stream<ResourceUsage> get resourceUsage => _resourceUsageStream.stream;

  void updateConnectionDetails({String? ipAddress, int? port}) {
    if (ipAddress != null) ipAddress = ipAddress;
    if (port != null) port = port;
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
      _client = Client(_channel!.cast<String>());

      isConnected = true;
      _startListeningToMessages();

      await call('printer.objects.subscribe', {
        "objects": {
          "heater_bed": null,
          "extruder": null,
          "print_stats": null,
        }
      });

      print('Connected to Klipper server: $url');
      return true;
    } catch (e) {
      isConnected = false;
      print('Failed to connect to Klipper server: $e');
      return false;
    }
  }

  Future<dynamic> call(String method, [dynamic params]) async {
    if (!isConnected || _client == null) {
      throw Exception('Not connected to Klipper server');
    }

    try {
      return await _client!.sendRequest(method, params);
    } catch (e) {
      print('Error calling method $method: $e');
      rethrow;
    }
  }

  void sendNotification(String method, [dynamic params]) {
    if (!isConnected || _client == null) {
      throw Exception('Not connected to Klipper server');
    }

    try {
      _client!.sendNotification(method, params);
    } catch (e) {
      print('Error sending notification $method: $e');
      rethrow;
    }
  }

  Future<void> dispose() async {
    if (!isConnected) return;

    try {
      await _client?.close();
      await _channel?.sink.close();
      print('Disconnected from Klipper server');
    } catch (e) {
      print('Error closing connection: $e');
    } finally {
      _client = null;
      _channel = null;
      isConnected = false;
    }
  }

  void _startListeningToMessages() {
    _channel!.stream.listen(
          (msg) {
        try {
          final json = jsonDecode(msg);
          print('📨 Received message: $json');

          if (json['method'] == 'notify_proc_stat_update') {
            final params = json['params'];

            if (params is List && params.isNotEmpty && params.first is Map<String, dynamic>) {
              final resourceUsage = ResourceUsage.fromJson(params.first);
              _resourceUsageStream.add(resourceUsage);
            } else {
              print('Unexpected format in notify_proc_stat_update params: $params');
            }
          }

          if (json['method'] == 'notify_status_update') {
            // Handle print status or additional updates if needed
          }
        } catch (e) {
          print('Error parsing WebSocket message: $e');
        }
      },
      onError: (error) {
        print('Stream error: $error');
      },
      onDone: () {
        print('WebSocket stream closed');
      },
    );
  }
}
