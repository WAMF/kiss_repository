import 'package:kiss_dependencies/kiss_dependencies.dart';

import 'models/user.dart';
import 'repositories/providers/firebase_repository_provider.dart';
import 'repositories/providers/inmemory_repository_provider.dart';
import 'repositories/providers/pocketbase_repository_provider.dart';
import 'repositories/repository_provider.dart';

class Dependencies {
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;

    registerLazy<RepositoryProvider<User>>(
      () => FirebaseRepositoryProvider(),
      identifier: 'firebase_user_provider',
    );

    registerLazy<RepositoryProvider<User>>(
      () => InMemoryRepositoryProvider(),
      identifier: 'inmemory_user_provider',
    );

    registerLazy<RepositoryProvider<User>>(
      () => PocketbaseRepositoryProvider(),
      identifier: 'pocketbase_user_provider',
    );

    _isInitialized = true;
  }

  static RepositoryProvider<User> getProvider(String identifier) {
    return resolve<RepositoryProvider<User>>(identifier: identifier);
  }
}
