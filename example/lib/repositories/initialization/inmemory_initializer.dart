import 'repository_initializer.dart';

class InMemoryInitializer implements RepositoryInitializer {
  bool _initialized = false;

  @override
  Future<void> init() async {
    if (_initialized) {
      return;
    }

    _initialized = true;
  }

  @override
  bool get isInitialized => _initialized; 
}
