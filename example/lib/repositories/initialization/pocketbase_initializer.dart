import 'repository_initializer.dart';

class PocketBaseInitializer implements RepositoryInitializer {
  String _serverUrl = 'http://localhost:8090';
  bool _initialized = false;
  String _statusMessage = 'Not initialized';

  @override
  Future<bool> init(Map<String, dynamic>? config) async {
    try {
      _serverUrl = config?['serverUrl'] as String? ?? 'http://localhost:8090';

      // Basic validation of URL format
      final uri = Uri.parse(_serverUrl);
      if (!uri.hasScheme || !uri.hasAuthority) {
        _statusMessage = 'Invalid PocketBase server URL: $_serverUrl';
        return false;
      }

      _initialized = true;
      _statusMessage = 'PocketBase initialized with URL: $_serverUrl';
      return true;
    } catch (e) {
      _statusMessage = 'Failed to initialize PocketBase: $e';
      return false;
    }
  }

  @override
  bool get isInitialized => _initialized;

  @override
  String get statusMessage => _statusMessage;

  String get serverUrl => _serverUrl;
}
