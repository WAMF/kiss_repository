import 'package:kiss_repository/kiss_repository.dart';
import 'package:kiss_firebase_repository/kiss_firebase_repository.dart';
import 'package:kiss_pocketbase_repository/kiss_pocketbase_repository.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:kiss_dependencies/kiss_dependencies.dart';

import 'models/user.dart';
import 'repositories/query_builders/firebase_user_query_builder.dart';
import 'repositories/query_builders/inmemory_user_query_builder.dart';
import 'repositories/query_builders/pocketbase_user_query_builder.dart';

class Dependencies {
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;

    // Register Firebase Repository
    registerLazy<Repository<User>>(
      () => RepositoryFirestore<User>(
        path: 'users',
        toFirestore: (user) => {
          'id': user.id,
          'name': user.name,
          'email': user.email,
          'createdAt': user.createdAt,
        },
        fromFirestore: (ref, data) => User(
          id: ref.id,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          createdAt: data['createdAt'] as DateTime,
        ),
        queryBuilder: FirestoreUserQueryBuilder('users'),
      ),
      identifier: 'firebase_user_repository',
    );

    // Register InMemory Repository
    registerLazy<Repository<User>>(
      () => InMemoryRepository<User>(
        queryBuilder: InMemoryUserQueryBuilder(),
        path: 'users',
      ),
      identifier: 'inmemory_user_repository',
    );

    _isInitialized = true;
  }

  static void registerPocketBaseRepository(String serverUrl) {
    final client = PocketBase(serverUrl);

    registerLazy<Repository<User>>(
      () => RepositoryPocketBase<User>(
        client: client,
        collection: 'users',
        fromPocketBase: (record) => User(
          id: record.id,
          name: record.data['name'] as String? ?? '',
          email: record.data['email'] as String? ?? '',
          createdAt: DateTime.tryParse(record.data['created'] as String? ?? '') ?? DateTime.now(),
        ),
        toPocketBase: (user) => {
          'name': user.name,
          'email': user.email,
          'created': user.createdAt.toIso8601String(),
        },
        queryBuilder: PocketBaseUserQueryBuilder(),
      ),
      identifier: 'pocketbase_user_repository',
    );
  }

  static Repository<User> getRepository(String identifier) {
    return resolve<Repository<User>>(identifier: identifier);
  }
}
