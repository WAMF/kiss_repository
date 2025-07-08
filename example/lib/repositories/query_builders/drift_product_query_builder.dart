import 'package:drift/drift.dart';
import 'package:kiss_repository/kiss_repository.dart' as kiss;

import '../../queries/product_queries.dart';

class DriftProductQueryBuilder implements kiss.QueryBuilder<Expression<bool>?> {
  @override
  Expression<bool>? build(kiss.Query query) {
    if (query is QueryByName) {
      return CustomExpression("data LIKE '%\"name\":\"${query.searchTerm}%'");
    }

    if (query is QueryByPriceRange) {
      final conditions = <String>[];
      if (query.minPrice != null) {
        conditions.add("CAST(JSON_EXTRACT(data, '\$.price') AS REAL) >= ${query.minPrice}");
      }
      if (query.maxPrice != null) {
        conditions.add("CAST(JSON_EXTRACT(data, '\$.price') AS REAL) <= ${query.maxPrice}");
      }
      if (conditions.isNotEmpty) {
        return CustomExpression(conditions.join(' AND '));
      }
    }

    return null;
  }
}
