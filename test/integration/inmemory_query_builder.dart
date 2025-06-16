import 'package:kiss_repository/kiss_repository.dart';

import '../../shared_test_logic/data/queries.dart';
import '../../shared_test_logic/data/product_model.dart';

/// InMemory-specific query builder for ProductModel
/// Uses InMemoryFilterQuery with predicate functions
class TestInMemoryProductQueryBuilder implements QueryBuilder<InMemoryFilterQuery<ProductModel>> {
  @override
  InMemoryFilterQuery<ProductModel> build(Query query) {
    if (query is QueryByName) {
      // Case-insensitive contains matching for InMemory
      return InMemoryFilterQuery<ProductModel>((product) {
        return product.name.toLowerCase().contains(query.namePrefix.toLowerCase());
      });
    }

    if (query is QueryByCreatedAfter) {
      return InMemoryFilterQuery<ProductModel>((product) {
        return product.created.isAfter(query.date);
      });
    }

    if (query is QueryByCreatedBefore) {
      return InMemoryFilterQuery<ProductModel>((product) {
        return product.created.isBefore(query.date);
      });
    }

    if (query is QueryByPriceGreaterThan) {
      return InMemoryFilterQuery<ProductModel>((product) {
        return product.price > query.price;
      });
    }

    if (query is QueryByPriceLessThan) {
      return InMemoryFilterQuery<ProductModel>((product) {
        return product.price < query.price;
      });
    }

    throw UnsupportedError('TestInMemoryProductQueryBuilder: unsupported query type ${query.runtimeType}');
  }
}
