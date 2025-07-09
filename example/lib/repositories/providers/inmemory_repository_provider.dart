import 'package:example/models/product_model.dart';
import 'package:example/repositories/query_builders/inmemory_product_query_builder.dart';
import 'package:example/repositories/repository_provider.dart';
import 'package:kiss_repository/kiss_repository.dart';

class InMemoryRepositoryProvider implements RepositoryProvider<ProductModel> {
  Repository<ProductModel>? _repository;

  @override
  Future<void> initialize() async {
    if (_repository != null) return;

    _repository = InMemoryRepository<ProductModel>(
      queryBuilder: InMemoryProductQueryBuilder(),
      path: 'products',
    );
  }

  @override
  Repository<ProductModel> get repository {
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
