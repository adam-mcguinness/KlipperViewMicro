import 'dart:async';
import 'package:flutter/material.dart';
import '../api/klipper_api.dart';
import '../models/printer_data.dart';
import '../utils/constants.dart';
import '../widgets/temperature_widget.dart';
import '../widgets/control_button.dart';

class HomeScreen extends StatefulWidget {
  final KlipperApi api;

  const HomeScreen({
    Key? key,
    required this.api,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PrinterData _printerData = PrinterData.empty();
  bool _isLoading = true;
  StreamSubscription? _dataSubscription;
  bool _connectionInProgress = false;

  @override
  void initState() {
    super.initState();
    _connectToWebSocket();
  }

  Future<void> _connectToWebSocket() async {
    if (_connectionInProgress) return;

    setState(() {
      _connectionInProgress = true;
      _isLoading = true;
    });

    try {
      // Connect to WebSocket
      final success = await widget.api.connect();

      if (success) {
        // Subscribe to the data stream
        _dataSubscription = widget.api.dataStream.listen(
                (data) {
              setState(() {
                _printerData = data;
                _isLoading = false;
              });
            },
            onError: (error) {
              print('Stream error: $error');
              _showConnectionError('Data stream error: $error');
            }
        );
      } else {
        _showConnectionError('Failed to connect to printer');
        // If WebSocket fails, fall back to HTTP polling
        _startHttpPolling();
      }
    } catch (e) {
      _showConnectionError('Connection error: $e');
      // If WebSocket fails, fall back to HTTP polling
      _startHttpPolling();
    } finally {
      setState(() {
        _connectionInProgress = false;
        // Only set _isLoading to false here if we're still in the loading state
        // (if the connection was successful, it will already be false)
        if (!widget.api.isConnected) {
          _isLoading = false;
        }
      });
    }
  }

  void _startHttpPolling() {
    // Fetch initial data
    _fetchPrinterData();

    // Set up periodic polling
    Timer.periodic(
        AppConstants.refreshInterval,
            (timer) {
          if (mounted && !widget.api.isConnected) {
            _fetchPrinterData();
          } else {
            timer.cancel();
          }
        }
    );
  }

  Future<void> _fetchPrinterData() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final data = await widget.api.fetchTemperatureData();

      setState(() {
        _printerData = PrinterData.fromJson(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching printer data: $e');
    }
  }

  void _showConnectionError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _homeAxis(String axes) async {
    try {
      await widget.api.homeAxis(axes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Homing $axes axis'),
          backgroundColor: AppTheme.primaryColor,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      print('Error homing axis: $e');
    }
  }

  Future<void> _moveHead({double? x, double? y, double? z}) async {
    try {
      await widget.api.moveHeadRelative(x: x, y: y, z: z);
    } catch (e) {
      print('Error moving head: $e');
    }
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    widget.api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Temperature displays
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: TemperatureWidget(
                      title: 'BED',
                      current: _printerData.bedTemperature.current,
                      target: _printerData.bedTemperature.target,
                      isLoading: _isLoading,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TemperatureWidget(
                      title: 'HOTEND',
                      current: _printerData.hotendTemperature.current,
                      target: _printerData.hotendTemperature.target,
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Controls section
              Expanded(
                child: Column(
                  children: [
                    // Home buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ControlButton(
                          icon: Icons.home,
                          label: 'HOME XY',
                          onPressed: () => _homeAxis('X Y'),
                        ),
                        ControlButton(
                          icon: Icons.vertical_align_bottom,
                          label: 'HOME Z',
                          onPressed: () => _homeAxis('Z'),
                        ),
                        ControlButton(
                          icon: Icons.home_work,
                          label: 'HOME ALL',
                          onPressed: () => _homeAxis(''),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // XY movement controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DirectionButton(
                          icon: Icons.arrow_upward,
                          onPressed: () => _moveHead(y: 10),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DirectionButton(
                          icon: Icons.arrow_back,
                          onPressed: () => _moveHead(x: -10),
                        ),
                        const SizedBox(width: 50),
                        DirectionButton(
                          icon: Icons.arrow_forward,
                          onPressed: () => _moveHead(x:  10),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DirectionButton(
                          icon: Icons.arrow_downward,
                          onPressed: () => _moveHead(y: -10),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Z movement controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DirectionButton(
                          icon: Icons.add,
                          label: 'Z',
                          onPressed: () => _moveHead(z: 1),
                        ),
                        const SizedBox(width: 20),
                        DirectionButton(
                          icon: Icons.remove,
                          label: 'Z',
                          onPressed: () => _moveHead(z: -1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status bar with connection indicator and mode
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: widget.api.isConnected ? Colors.green : Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Klipper @${widget.api.ipAddress}',
                      style: const TextStyle(fontSize: 10, color: AppTheme.textColorSecondary),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      widget.api.isConnected ? '(WebSocket)' : '(HTTP)',
                      style: TextStyle(
                          fontSize: 8,
                          color: widget.api.isConnected
                              ? Colors.green.withOpacity(0.8)
                              : Colors.orange.withOpacity(0.8)
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Refresh button
                    GestureDetector(
                      onTap: _connectionInProgress ? null : _connectToWebSocket,
                      child: Icon(
                        Icons.refresh,
                        size: 14,
                        color: _connectionInProgress
                            ? AppTheme.textColorSecondary.withOpacity(0.5)
                            : AppTheme.textColorSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}