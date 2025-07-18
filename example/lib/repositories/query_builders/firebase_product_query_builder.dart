import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:example/queries/product_queries.dart';
import 'package:kiss_firebase_repository/kiss_firebase_repository.dart';

class FirestoreProductQueryBuilder
    implements QueryBuilder<firestore.Query<Map<String, dynamic>>> {
  FirestoreProductQueryBuilder(this.collectionPath);
  final String collectionPath;

  @override
  firestore.Query<Map<String, dynamic>> build(Query query) {
    final baseQuery =
        firestore.FirebaseFirestore.instance.collection(collectionPath);

    if (query is QueryByName) {
      // Search for products by name (case-insensitive prefix search)
      if (query.searchTerm.isNotEmpty) {
        return baseQuery
            .where('name', isGreaterThanOrEqualTo: query.searchTerm)
            .where('name', isLessThan: '${query.searchTerm}\uf8ff')
            .orderBy('name');
      }
    }

    if (query is QueryByPriceGreaterThan) {
      return baseQuery
          .where('price', isGreaterThan: query.threshold)
          .orderBy('price');
    }

    if (query is QueryByPriceLessThan) {
      return baseQuery
          .where('price', isLessThan: query.threshold)
          .orderBy('price', descending: true);
    }

    if (query is QueryByCreatedAfter) {
      return baseQuery
          .where('created', isGreaterThan: query.dateTime)
          .orderBy('created', descending: true);
    }

    if (query is QueryByCreatedBefore) {
      return baseQuery
          .where('created', isLessThan: query.dateTime)
          .orderBy('created', descending: true);
    }

    // Default: return all products ordered by creation date (newest first)
    return baseQuery.orderBy('created', descending: true);
  }
}
