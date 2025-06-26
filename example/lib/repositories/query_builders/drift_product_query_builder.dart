import 'package:kiss_repository/kiss_repository.dart';

import '../../queries/product_queries.dart';

class DriftProductQueryBuilder implements QueryBuilder<String> {
  @override
  String build(Query query) {
    if (query is QueryByName) {
      return 'name:${query.searchTerm}';
    }

    if (query is QueryByPriceGreaterThan) {
      return 'price_gt:${query.threshold}';
    }

    if (query is QueryByPriceLessThan) {
      return 'price_lt:${query.threshold}';
    }

    if (query is QueryByCreatedAfter) {
      return 'created_after:${query.dateTime.toIso8601String()}';
    }

    if (query is QueryByCreatedBefore) {
      return 'created_before:${query.dateTime.toIso8601String()}';
    }

    return '';
  }
}
