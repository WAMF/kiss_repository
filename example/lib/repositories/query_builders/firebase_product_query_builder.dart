import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:kiss_firebase_repository/kiss_firebase_repository.dart';
import '../../queries/product_queries.dart';

class FirestoreProductQueryBuilder implements QueryBuilder<firestore.Query<Map<String, dynamic>>> {
  final String collectionPath;

  FirestoreProductQueryBuilder(this.collectionPath);

  @override
  firestore.Query<Map<String, dynamic>> build(Query query) {
    final baseQuery = firestore.FirebaseFirestore.instance.collection(collectionPath);

    if (query is QueryByName) {
      // Search for products by name (case-insensitive prefix search)
      if (query.searchTerm.isNotEmpty) {
        return baseQuery
            .where('name', isGreaterThanOrEqualTo: query.searchTerm)
            .where('name', isLessThan: '${query.searchTerm}\uf8ff')
            .orderBy('name');
      }
    }

    if (query is QueryByPriceRange) {
      firestore.Query<Map<String, dynamic>> result = baseQuery;
      if (query.minPrice != null) {
        result = result.where('price', isGreaterThanOrEqualTo: query.minPrice);
      }
      if (query.maxPrice != null) {
        result = result.where('price', isLessThanOrEqualTo: query.maxPrice);
      }
      return result.orderBy('price');
    }

    // Default: return all products ordered by creation date (newest first)
    return baseQuery.orderBy('created', descending: true);
  }
}
