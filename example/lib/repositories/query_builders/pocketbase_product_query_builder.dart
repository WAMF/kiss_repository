import 'package:kiss_repository/kiss_repository.dart';
import '../../queries/product_queries.dart';

class PocketBaseProductQueryBuilder implements QueryBuilder<String> {
  @override
  String build(Query query) {
    if (query is QueryByName) {
      return "name ~ '${query.searchTerm}'";
    }

    if (query is QueryByPriceGreaterThan) {
      return "price > ${query.threshold}";
    }

    if (query is QueryByPriceLessThan) {
      return "price < ${query.threshold}";
    }

    if (query is QueryByCreatedAfter) {
      final dateString = query.dateTime.toIso8601String();
      return "created > '$dateString'";
    }

    if (query is QueryByCreatedBefore) {
      final dateString = query.dateTime.toIso8601String();
      return "created < '$dateString'";
    }

    // Default: return all products
    return "";
  }
}
