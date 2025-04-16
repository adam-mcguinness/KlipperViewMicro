import 'dart:async';
import 'dart:convert'; // For debugging JSON output
import 'package:flutter/material.dart';
import 'package:klipper_view_micro/models/printer_data.dart';
import 'package:klipper_view_micro/services/klipper_service.dart';
import 'package:rxdart/rxdart.dart';

// Combined state class that holds all printer data
class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;

  final KlipperService _api = KlipperService();

  final CompositeSubscription _subscriptions = CompositeSubscription();

  // Error stream for notifying UI of problems
  final _errorSubject = PublishSubject<String>();
  Stream<String> get errors => _errorSubject.stream;

  // Raw API access if needed for direct commands
  KlipperService get api => _api;

  // ========== Resource Usage Streams ==========
  // Create specific streams for Resource data
  late final Stream<ResourceUsage> resourceUsageStream;
  late final Stream<double> cpuUsageStream;
  late final Stream<int> memoryUsageStream;

  // ========== EXTRUDER STREAMS ==========
  // Create specific streams for extruder data
  late final Stream<Extruder> extruderStream;
  late final Stream<double> extruderTemperatureStream;
  late final Stream<double> extruderTargetStream;
  late final Stream<bool> extruderHeatingStream;

  // ========== HEATER BED STREAMS ==========
  // Create specific streams for heater bed data
  late final Stream<HeaterBed> heaterBedStream;
  late final Stream<double> bedTemperatureStream;
  late final Stream<double> bedTargetStream;
  late final Stream<bool> bedHeatingStream;

  // ========== PRINT STATE STREAMS ==========
  // Create specific streams for print status
  late final Stream<PrintStats> printStatsStream;
  late final Stream<String> printStateStream;
  late final Stream<String?> fileNameStream;
  late final Stream<bool> isPrintingStream;
  late final Stream<bool> isPausedStream;

  // ========== SD CARD STREAMS ==========
  // Create specific streams for SD card data
  late final Stream<VirtualSdCard> sdCardStream;
  late final Stream<double> progressStream;
  late final Stream<bool> sdCardActiveStream;

  // ========== DERIVED STREAMS ==========
  // Computed streams that combine multiple data sources
  late final Stream<double> remainingTimeStream;

  // Direct value access (for non-reactive use)
  bool get isConnected => _api.isConnected;
  double get currentExtruderTemp => _api.latestExtruder.currentTemperature;
  double get currentBedTemp => _api.latestHeaterBed.currentTemperature;
  bool get isPrinting => _api.latestPrintStats.state == 'printing';
  int get totalMemory => _api.latestResourceUsage.memoryTotal;

  PrinterService._internal() {
    _connectToPrinter().then((_) {
      _initializeStreams();
    });
  }

  void _initializeStreams() {
    final throttleDuration = Duration(milliseconds: 250);

    // ========== RESOURCE USAGE STREAMS ==========
    // Base resource usage stream with throttling
    resourceUsageStream = _api.resourceUsage
        .throttleTime(throttleDuration)
        .distinct()
        .share();
    // Derived resource usage streams
    cpuUsageStream = resourceUsageStream
        .map((r) => r.cpuUsage)
        .distinct()
        .share();
    memoryUsageStream = resourceUsageStream
        .map((r) => r.memoryUsed)
        .distinct()
        .share();

    // ========== EXTRUDER STREAMS ==========
    // Base extruder stream with throttling
    extruderStream = _api.extruderStatus
        .throttleTime(throttleDuration)
        .distinct()
        .share();

    // Derived extruder streams
    extruderTemperatureStream = extruderStream
        .map((e) => e.currentTemperature)
        .distinct()
        .share();

    extruderTargetStream = extruderStream
        .map((e) => e.targetTemperature)
        .distinct()
        .share();

    extruderHeatingStream = extruderStream
        .map((e) => e.targetTemperature > 0 &&
        e.currentTemperature < e.targetTemperature - 1)
        .distinct()
        .share();

    // ========== HEATER BED STREAMS ==========
    // Base heater bed stream with throttling
    heaterBedStream = _api.heaterBedStatus
        .throttleTime(throttleDuration)
        .distinct()
        .share();

    // Derived heater bed streams
    bedTemperatureStream = heaterBedStream
        .map((b) => b.currentTemperature)
        .distinct()
        .share();

    bedTargetStream = heaterBedStream
        .map((b) => b.targetTemperature)
        .distinct()
        .share();

    bedHeatingStream = heaterBedStream
        .map((b) => b.targetTemperature > 0 &&
        b.currentTemperature < b.targetTemperature - 1)
        .distinct()
        .share();

    // ========== PRINT STATE STREAMS ==========
    // Base print stats stream with throttling
    printStatsStream = _api.printStatus
        .throttleTime(throttleDuration)
        .distinct()
        .share();

    // Derived print stats streams
    printStateStream = printStatsStream
        .map((p) => p.state)
        .distinct()
        .share();

    fileNameStream = printStatsStream
        .map((p) => p.fileName)
        .distinct()
        .share();

    isPrintingStream = printStatsStream
        .map((p) => p.state == 'printing')
        .distinct()
        .share();

    isPausedStream = printStatsStream
        .map((p) => p.state == 'paused')
        .distinct()
        .share();

    // ========== SD CARD STREAMS ==========
    // Base SD card stream with throttling
    sdCardStream = _api.virtualSdCardStatus
        .throttleTime(throttleDuration)
        .distinct()
        .share();

    // Derived SD card streams
    progressStream = sdCardStream
        .map((sd) => sd.progress)
        .distinct()
        .share();

    sdCardActiveStream = sdCardStream
        .map((sd) => sd.isActive)
        .distinct()
        .share();

    // ========== DERIVED STREAMS ==========
    // Compute remaining time from multiple streams
    remainingTimeStream = Rx.combineLatest2(
      printStatsStream,
      sdCardStream,
          (PrintStats stats, VirtualSdCard card) {
        if (stats.totalDuration <= 0 || !card.isActive) return 0.0;
        return stats.totalDuration - stats.printDuration;
      },
    )
        .distinct()
        .throttleTime(throttleDuration)
        .share();
  }

  Future<void> _connectToPrinter() async {
    try {
      final success = await _api.connect();
      if (!success) {
        _errorSubject.add('Failed to connect to printer');
      }
    } catch (e) {
      _errorSubject.add('Connection error: $e');
    }
  }

  // ========== PRINTER CONTROL METHODS ==========

  Future<bool> reconnect() async {
    try {
      return await _api.connect();
    } catch (e) {
      _errorSubject.add('Reconnection error: $e');
      return false;
    }
  }

  Future<void> pausePrint() async {
    if (!isConnected) {
      _errorSubject.add('Not connected to printer');
      return;
    }

    try {
      await _api.call('printer.print.pause');
    } catch (e) {
      _errorSubject.add('Failed to pause print: $e');
    }
  }

  Future<void> resumePrint() async {
    if (!isConnected) {
      _errorSubject.add('Not connected to printer');
      return;
    }

    try {
      await _api.call('printer.print.resume');
    } catch (e) {
      _errorSubject.add('Failed to resume print: $e');
    }
  }

  Future<void> cancelPrint() async {
    if (!isConnected) {
      _errorSubject.add('Not connected to printer');
      return;
    }

    try {
      await _api.call('printer.print.cancel');
    } catch (e) {
      _errorSubject.add('Failed to cancel print: $e');
    }
  }

  Future<void> setExtruderTemperature(double temperature) async {
    if (!isConnected) {
      _errorSubject.add('Not connected to printer');
      return;
    }

    try {
      await _api.call('printer.gcode.script',
          {'script': 'SET_HEATER_TEMPERATURE HEATER=extruder TARGET=$temperature'});
    } catch (e) {
      _errorSubject.add('Failed to set extruder temperature: $e');
    }
  }

  Future<void> setBedTemperature(double temperature) async {
    if (!isConnected) {
      _errorSubject.add('Not connected to printer');
      return;
    }

    try {
      await _api.call('printer.gcode.script',
          {'script': 'SET_HEATER_TEMPERATURE HEATER=heater_bed TARGET=$temperature'});
    } catch (e) {
      _errorSubject.add('Failed to set bed temperature: $e');
    }
  }

  // Dispose method to clean up resources
  void dispose() {
    _subscriptions.dispose();
    _errorSubject.close();
    _api.dispose();
  }
}