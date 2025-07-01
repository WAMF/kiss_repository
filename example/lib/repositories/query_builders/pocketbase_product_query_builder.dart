import 'package:kiss_repository/kiss_repository.dart';
import '../../queries/product_queries.dart';

class PocketBaseProductQueryBuilder implements QueryBuilder<String> {
  @override
  String build(Query query) {
    if (query is QueryByName) {
      return "name ~ '${query.searchTerm}'";
    }

    if (query is QueryByPriceRange) {
      final conditions = <String>[];
      if (query.minPrice != null) {
        conditions.add("price >= ${query.minPrice}");
      }
      if (query.maxPrice != null) {
        conditions.add("price <= ${query.maxPrice}");
      }
      return conditions.join(' && ');
    }

    // Default: return all products
    return "";
  }
}
