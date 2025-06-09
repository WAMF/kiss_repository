import 'repository_initializer.dart';

class InMemoryInitializer implements RepositoryInitializer {
  bool _initialized = false;

  @override
  Future<bool> init(Map<String, dynamic>? config) async {
    // InMemory repository requires no initialization
    _initialized = true;
    return true;
  }

  @override
  bool get isInitialized => _initialized;

  @override
  String get statusMessage => _initialized ? 'InMemory repository ready' : 'InMemory repository not initialized';
}
