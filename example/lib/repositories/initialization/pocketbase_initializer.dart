import 'repository_initializer.dart';
import '../../utils/logger.dart' as logger;

class PocketBaseInitializer implements RepositoryInitializer {
  final _serverUrl = 'http://localhost:8090';
  bool _initialized = false;

  @override
  Future<void> init() async {
    if (_initialized) {
      return;
    }

    try {
      // Basic validation of URL format
      final uri = Uri.parse(_serverUrl);
      if (!uri.hasScheme || !uri.hasAuthority) {
        return;
      }

      _initialized = true;
    } catch (e) {
      logger.log('Failed to initialize PocketBase: $e');
    }
  }

  @override
  bool get isInitialized => _initialized;
}
