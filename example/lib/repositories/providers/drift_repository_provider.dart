import 'package:kiss_drift_repository/kiss_drift_repository.dart';
import 'package:kiss_repository/kiss_repository.dart';

import '../../models/product_model.dart';
import '../../utils/logger.dart' as logger;
import '../query_builders/drift_product_query_builder.dart';
import '../repository_provider.dart';

class DriftRepositoryProvider implements RepositoryProvider<ProductModel> {
  Repository<ProductModel>? _repository;

  @override
  bool get isInitialized => _repository != null;

  @override
  Future<void> initialize() async {
    if (_repository != null) return;

    try {
      _repository = await RepositoryDrift.create<ProductModel>(
        tableName: 'products',
        toDrift: (product) => {
          'id': product.id,
          'name': product.name,
          'price': product.price,
          'description': product.description,
          'created': product.created.toIso8601String(),
        },
        fromDrift: (data) => ProductModel(
          id: data['id'] as String,
          name: data['name'] as String,
          price: (data['price'] as num).toDouble(),
          description: data['description'] as String,
          created: DateTime.parse(data['created'] as String),
        ),
        queryBuilder: DriftProductQueryBuilder(),
      );

      logger.log('✅ Drift repository initialized (SQLite embedded)');
    } catch (e) {
      logger.log('⚠️ Drift initialization error: $e');
      rethrow;
    }
  }

  @override
  Repository<ProductModel> get repository {
    if (_repository == null) {
      throw StateError('Repository not initialized. Call initialize() first.');
    }
    return _repository!;
  }

  @override
  void dispose() {
    _repository?.dispose();
    _repository = null;
    logger.log('🧹 Drift repository disposed');
  }
}
