import 'package:kiss_repository/kiss_repository.dart';
import 'package:kiss_pocketbase_repository/kiss_pocketbase_repository.dart';
import 'package:pocketbase/pocketbase.dart';
import '../repository_provider.dart';
import '../query_builders/pocketbase_user_query_builder.dart';
import '../../models/user.dart';
import '../../utils/logger.dart' as logger;

class PocketBaseUserRepositoryProvider implements RepositoryProvider<User> {
  Repository<User>? _repository;
  final String serverUrl;

  PocketBaseUserRepositoryProvider({this.serverUrl = 'http://localhost:8090'});

  @override
  Future<void> initialize() async {
    if (_repository != null) return;

    try {
      final client = PocketBase(serverUrl);

      _repository = RepositoryPocketBase<User>(
        client: client,
        collection: 'users',
        fromPocketBase: (record) => User(
          id: record.id,
          name: record.data['name'] ?? '',
          email: record.data['email'] ?? '',
          createdAt: DateTime.parse(record.created),
        ),
        toPocketBase: (user) => {
          'name': user.name,
          'email': user.email,
        },
        queryBuilder: PocketBaseUserQueryBuilder(),
      );

      logger.log('✅ PocketBase repository initialized for $serverUrl');
    } catch (e) {
      logger.log('⚠️ PocketBase initialization error: $e');
      rethrow;
    }
  }

  @override
  Repository<User> get repository {
    if (_repository == null) {
      throw StateError('Repository not initialized. Call initialize() first.');
    }
    return _repository!;
  }

  @override
  bool get isInitialized => _repository != null;

  @override
  void dispose() {
    _repository?.dispose();
    _repository = null;
  }
}
