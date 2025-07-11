import 'package:example/models/product_model.dart';
import 'package:example/repositories/query_builders/pocketbase_product_query_builder.dart';
import 'package:example/repositories/repository_provider.dart';
import 'package:example/utils/logger.dart' as logger;
import 'package:kiss_pocketbase_repository/kiss_pocketbase_repository.dart';
// ignore: depend_on_referenced_packages
import 'package:pocketbase/pocketbase.dart';

class PocketBaseRepositoryProvider implements RepositoryProvider<ProductModel> {
  PocketBaseRepositoryProvider({this.serverUrl = 'http://localhost:8090'});
  Repository<ProductModel>? _repository;
  final String serverUrl;

  static const String testUserEmail = 'testuser@example.com';
  static const String testUserPassword = 'testuser123';

  late PocketBase _client;

  @override
  Future<void> initialize() async {
    if (_repository != null) return;

    _client = PocketBase(serverUrl);

    await _authenticate();

    try {
      _repository = RepositoryPocketBase<ProductModel>(
        client: _client,
        collection: 'products',
        fromPocketBase: (record) => ProductModel(
          id: record.id,
          name: (record.data['name'] as String?) ?? '',
          price: (record.data['price'] as num?)?.toDouble() ?? 0.0,
          description: (record.data['description'] as String?) ?? '',
          created: DateTime.parse(record.get<String>('created')),
        ),
        toPocketBase: (product) => {
          'name': product.name,
          'price': product.price,
          'description': product.description,
        },
        queryBuilder: PocketBaseProductQueryBuilder(),
      );

      logger.log('✅ PocketBase repository initialized for $serverUrl');
    } catch (e) {
      logger.log('⚠️ PocketBase initialization error: $e');
      rethrow;
    }
  }

  /// PocketBase requires per-user authentication to access the database
  Future<void> _authenticate() async {
    await _client
        .collection('users')
        .authWithPassword(testUserEmail, testUserPassword);
    logger.log('🔐 Authenticated as test user: $testUserEmail');
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
