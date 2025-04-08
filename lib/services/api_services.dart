import '../api/klipper_api.dart';

class ApiService {
  // Singleton instance
  static final ApiService _instance = ApiService._internal();

  // Factory constructor to return the singleton instance
  factory ApiService() => _instance;

  // Private constructor
  ApiService._internal();

  // Store the API instance once it's initialized
  KlipperApi? _api;

  // Getter for the API
  KlipperApi get api {
    if (_api == null) {
      throw Exception('KlipperApi not initialized. Call ApiService().initialize() first.');
    }
    return _api!;
  }

  // Check if the API is initialized
  bool get isInitialized => _api != null;

  // Initialize with an existing API instance
  void initialize(KlipperApi api) {
    _api = api;
  }
}