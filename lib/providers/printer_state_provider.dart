import 'dart:async';
import 'dart:convert'; // For debugging JSON output
import 'package:flutter/material.dart';
import 'package:klipper_view_micro/models/printer_data.dart';
import 'package:klipper_view_micro/api/klipper_api.dart';

// Combined state class that holds all printer data
class PrinterState {
  final HeaterBed heaterBed;
  final Extruder extruder;
  final PrintStats printStats;
  final VirtualSdCard virtualSdCard;
  final ResourceUsage resourceUsage;
  final bool isConnected;

  PrinterState({
    required this.heaterBed,
    required this.extruder,
    required this.printStats,
    required this.virtualSdCard,
    required this.resourceUsage,
    required this.isConnected,
  });

  // Factory to create initial empty state
  factory PrinterState.empty() {
    return PrinterState(
      heaterBed: HeaterBed.empty(),
      extruder: Extruder.empty(),
      printStats: PrintStats.empty(),
      virtualSdCard: VirtualSdCard(),
      resourceUsage: ResourceUsage.empty(),
      isConnected: false,
    );
  }

  // Helper methods for UI
  bool get isPrinting => printStats.state == 'printing';
  bool get isPaused => printStats.state == 'paused';
  double get progress => virtualSdCard.progress;
  String get filename => virtualSdCard.filePath?.split('/').last.split('.').first ?? 'No file selected';
  double get printTime => printStats.printDuration;
  double get remainingTime => printStats.totalDuration - printStats.printDuration;

  // Create a new state by copying the current one with specific updates
  PrinterState copyWith({
    HeaterBed? heaterBed,
    Extruder? extruder,
    PrintStats? printStats,
    VirtualSdCard? virtualSdCard,
    ResourceUsage? resourceUsage,
    bool? isConnected,
  }) {
    return PrinterState(
      heaterBed: heaterBed ?? this.heaterBed,
      extruder: extruder ?? this.extruder,
      printStats: printStats ?? this.printStats,
      virtualSdCard: virtualSdCard ?? this.virtualSdCard,
      resourceUsage: resourceUsage ?? this.resourceUsage,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  // For debugging - converts the state to a readable JSON string
  String toJson() {
    final Map<String, dynamic> stateMap = {
      'isConnected': isConnected,
      'heaterBed': {
        'currentTemp': heaterBed.currentTemperature,
        'targetTemp': heaterBed.targetTemperature,
        'state': heaterBed.state,
      },
      'extruder': {
        'currentTemp': extruder.currentTemperature,
        'targetTemp': extruder.targetTemperature,
        'state': extruder.state,
      },
      'printStats': {
        'fileName': printStats.fileName,
        'totalDuration': printStats.totalDuration,
        'printDuration': printStats.printDuration,
        'state': printStats.state,
      },
      'virtualSdCard': {
        'filePath': virtualSdCard.filePath,
        'progress': virtualSdCard.progress,
        'isActive': virtualSdCard.isActive,
      },
      'resourceUsage': {
        'cpuUsage': resourceUsage.cpuUsage,
        'memoryUsed': resourceUsage.memoryUsed,
        'memoryTotal': resourceUsage.memoryTotal,
      },
    };

    return const JsonEncoder.withIndent('  ').convert(stateMap);
  }

  @override
  String toString() {
    return toJson();
  }
}

// Provider class that manages the printer state
class PrinterStateProvider with ChangeNotifier {
  final KlipperApi _api = KlipperApi();
  PrinterState _state = PrinterState.empty();
  List<StreamSubscription> _subscriptions = [];

  PrinterState get state => _state;
  KlipperApi get api => _api;

  PrinterStateProvider() {
    _initializeApi();
  }

  void _initializeApi() async {
    // Try to connect if not already connected
    if (!_api.isConnected) {
      await _api.connect();
    }

    // Update connection state
    _state = _state.copyWith(isConnected: _api.isConnected);
    notifyListeners();

    // Subscribe to all streams
    _subscribeToStreams();
  }

  void _subscribeToStreams() {
    // Clear any existing subscriptions
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    // Subscribe to heater bed updates with state merging
    _subscriptions.add(_api.heaterBedStatus.listen((newHeaterBed) {
      // Create merged heater bed state
      final mergedHeaterBed = HeaterBed(
        currentTemperature: newHeaterBed.currentTemperature != 0 ?
        newHeaterBed.currentTemperature : _state.heaterBed.currentTemperature,
        targetTemperature: newHeaterBed.targetTemperature != 0 ?
        newHeaterBed.targetTemperature : _state.heaterBed.targetTemperature,
        state: newHeaterBed.state.isNotEmpty ?
        newHeaterBed.state : _state.heaterBed.state,
      );

      _state = _state.copyWith(heaterBed: mergedHeaterBed);
      notifyListeners();
    }));

    // Subscribe to extruder updates with state merging
    _subscriptions.add(_api.extruderStatus.listen((newExtruder) {
      // Create merged extruder state
      final mergedExtruder = Extruder(
        currentTemperature: newExtruder.currentTemperature != 0 ?
        newExtruder.currentTemperature : _state.extruder.currentTemperature,
        targetTemperature: newExtruder.targetTemperature != 0 ?
        newExtruder.targetTemperature : _state.extruder.targetTemperature,
        state: newExtruder.state.isNotEmpty ?
        newExtruder.state : _state.extruder.state,
      );

      _state = _state.copyWith(extruder: mergedExtruder);
      notifyListeners();
    }));

    // Subscribe to print stats updates with state merging
    _subscriptions.add(_api.printStatus.listen((newPrintStats) {
      // Create merged print stats state
      final mergedPrintStats = PrintStats(
        // Keep fileName if new one is null and current one exists
        fileName: newPrintStats.fileName ?? _state.printStats.fileName,

        // For numerical values, only use new values if they're not 0
        totalDuration: newPrintStats.totalDuration != 0 ?
        newPrintStats.totalDuration : _state.printStats.totalDuration,
        printDuration: newPrintStats.printDuration != 0 ?
        newPrintStats.printDuration : _state.printStats.printDuration,

        // Keep the state string if new one is empty and current one exists
        state: newPrintStats.state.isNotEmpty ?
        newPrintStats.state : _state.printStats.state,
      );

      _state = _state.copyWith(printStats: mergedPrintStats);
      notifyListeners();
    }));

    // Subscribe to virtual SD card updates with state merging
    _subscriptions.add(_api.virtualSdCardStatus.listen((newVirtualSdCard) {
      // Create merged virtual SD card state
      final mergedVirtualSdCard = VirtualSdCard(
        filePath: newVirtualSdCard.filePath ?? _state.virtualSdCard.filePath,
        progress: newVirtualSdCard.progress != 0 ?
        newVirtualSdCard.progress : _state.virtualSdCard.progress,
        isActive: newVirtualSdCard.isActive || _state.virtualSdCard.isActive,
      );

      _state = _state.copyWith(virtualSdCard: mergedVirtualSdCard);
      notifyListeners();
    }));

    // Subscribe to resource usage updates
    _subscriptions.add(_api.resourceUsage.listen((newResourceUsage) {
      // For resource usage, we typically want to use the latest values
      // rather than merging, since these are real-time metrics
      _state = _state.copyWith(resourceUsage: newResourceUsage);
      notifyListeners();
    }));
  }

  // Method to reconnect to the printer
  Future<bool> reconnect() async {
    bool success = await _api.connect();
    _state = _state.copyWith(isConnected: _api.isConnected);
    notifyListeners();

    if (success) {
      _subscribeToStreams();
    }

    return success;
  }

  // API wrapper methods
  Future<void> pausePrint() async {
    if (!_state.isConnected) return;
    await _api.call('printer.print.pause');
  }

  Future<void> resumePrint() async {
    if (!_state.isConnected) return;
    await _api.call('printer.print.resume');
  }

  Future<void> cancelPrint() async {
    if (!_state.isConnected) return;
    await _api.call('printer.print.cancel');
  }

  @override
  void dispose() {
    // Cancel all stream subscriptions
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    super.dispose();
  }
}