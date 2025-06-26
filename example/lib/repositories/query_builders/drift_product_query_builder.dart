import 'package:kiss_repository/kiss_repository.dart';

import '../../models/product_model.dart';
import '../../queries/product_queries.dart';

typedef ProductFilter = bool Function(ProductModel);

class DriftProductQueryBuilder implements QueryBuilder<ProductFilter?> {
  @override
  ProductFilter? build(Query query) {
    if (query is QueryByName) {
      return (product) => product.name.toLowerCase().contains(query.searchTerm.toLowerCase());
    }

    if (query is QueryByPriceGreaterThan) {
      return (product) => product.price > query.threshold;
    }

    if (query is QueryByPriceLessThan) {
      return (product) => product.price < query.threshold;
    }

    if (query is QueryByCreatedAfter) {
      return (product) => product.created.isAfter(query.dateTime);
    }

    if (query is QueryByCreatedBefore) {
      return (product) => product.created.isBefore(query.dateTime);
    }

    return null;
  }
}
