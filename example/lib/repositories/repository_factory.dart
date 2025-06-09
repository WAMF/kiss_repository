import 'package:kiss_repository/kiss_repository.dart';
import '../dependencies.dart';
import 'repository_type.dart';
import 'initialization/firebase_initializer.dart';
import 'initialization/pocketbase_initializer.dart';
import 'initialization/inmemory_initializer.dart';
import '../models/user.dart';

class RepositoryFactory {
  static final Map<RepositoryType, dynamic> _initializers = {
    RepositoryType.firebase: FirebaseInitializer(),
    RepositoryType.pocketbase: PocketBaseInitializer(),
    RepositoryType.inMemory: InMemoryInitializer(),
  };

  static Future<Repository<User>> create(
    RepositoryType type, {
    Map<String, dynamic>? config,
  }) async {
    // Initialize the repository type
    final initializer = _initializers[type]!;
    await initializer.init(config);

    // Handle PocketBase registration separately since it needs config
    if (type == RepositoryType.pocketbase) {
      final pocketbaseInit = initializer as PocketBaseInitializer;
      Dependencies.registerPocketBaseRepository(pocketbaseInit.serverUrl);
    }

    final identifier = _getIdentifier(type);
    return Dependencies.getRepository(identifier);
  }

  static String _getIdentifier(RepositoryType type) {
    switch (type) {
      case RepositoryType.firebase:
        return 'firebase_user_repository';
      case RepositoryType.pocketbase:
        return 'pocketbase_user_repository';
      case RepositoryType.inMemory:
        return 'inmemory_user_repository';
    }
  }

  static void dispose(RepositoryType type) {
    final identifier = _getIdentifier(type);
    try {
      final repository = Dependencies.getRepository(identifier);
      repository.dispose();
      // Note: kiss_dependencies doesn't expose unregister functionality in the public API
      // The dependency will remain registered but the repository will be disposed
    } catch (e) {
      // Repository not registered, ignore
    }
  }

  static void disposeAll() {
    for (final type in RepositoryType.values) {
      dispose(type);
    }
  }

  static String getStatusMessage(RepositoryType type) {
    final initializer = _initializers[type];
    return initializer?.statusMessage ?? 'Unknown';
  }
}
