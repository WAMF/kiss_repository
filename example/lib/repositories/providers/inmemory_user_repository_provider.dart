import 'package:kiss_repository/kiss_repository.dart';
import '../repository_provider.dart';
import '../query_builders/inmemory_user_query_builder.dart';
import '../../models/user.dart';

class InMemoryUserRepositoryProvider implements RepositoryProvider<User> {
  Repository<User>? _repository;

  @override
  Future<void> initialize() async {
    if (_repository != null) return;

    _repository = InMemoryRepository<User>(
      queryBuilder: InMemoryUserQueryBuilder(),
      path: 'users',
    );
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
