import 'package:kiss_repository/kiss_repository.dart';
import '../../models/product_model.dart';
import '../../queries/product_queries.dart';

class InMemoryProductQueryBuilder implements QueryBuilder<InMemoryFilterQuery<ProductModel>> {
  @override
  InMemoryFilterQuery<ProductModel> build(Query query) {
    if (query is QueryByName) {
      return InMemoryFilterQuery<ProductModel>(
          (product) => product.name.toLowerCase().contains(query.searchTerm.toLowerCase()));
    }

    if (query is QueryByPriceGreaterThan) {
      return InMemoryFilterQuery<ProductModel>((product) => product.price > query.threshold);
    }

    if (query is QueryByPriceLessThan) {
      return InMemoryFilterQuery<ProductModel>((product) => product.price < query.threshold);
    }

    if (query is QueryByCreatedAfter) {
      return InMemoryFilterQuery<ProductModel>((product) => product.created.isAfter(query.dateTime));
    }

    if (query is QueryByCreatedBefore) {
      return InMemoryFilterQuery<ProductModel>((product) => product.created.isBefore(query.dateTime));
    }

    // Default: return all products
    return InMemoryFilterQuery<ProductModel>((product) => true);
  }
}
