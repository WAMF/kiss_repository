import 'dart:async';

class Query {
  const Query();
}

class AllQuery extends Query {
  const AllQuery();
}

abstract class QueryBuilder<T> {
  T build(Query query);
}

class IdentifiedObject<T> {
  IdentifiedObject(this.id, this.object);
  final String id;
  final T object;
}

enum RepositoryErrorCode { notFound, alreadyExists, unknown }

class RepositoryException implements Exception {
  RepositoryException({
    required this.message,
    this.code = RepositoryErrorCode.unknown,
  });

  factory RepositoryException.notFound(String id) {
    return RepositoryException(
      message: 'Item with id $id not found',
      code: RepositoryErrorCode.notFound,
    );
  }

  factory RepositoryException.alreadyExists(String id) {
    return RepositoryException(
      message: 'Item with id $id already exists',
      code: RepositoryErrorCode.alreadyExists,
    );
  }
  final String message;
  final RepositoryErrorCode code;

  @override
  String toString() => 'RepositoryException: $message';
}

abstract class Repository<T> {
  String? get path;
  //read operations
  /// Returns the item with the given ID.
  /// Throws [RepositoryException.notFound] if the item does not exist.
  Future<T> get(String id);

  /// Creates a real-time stream of changes for a specific document.
  ///
  /// **Initial Emission**: Immediately emits existing data (BehaviorSubject-like).
  /// **Error**: Emits [RepositoryException.notFound] if document doesn't exist (consistent with get).
  /// **Deletion**: Stream closes when document is deleted.
  /// **Error**: Emits [RepositoryException.notFound] if document doesn't exist (consistent with get).
  Stream<T> stream(String id);

  Future<List<T>> query({Query query = const AllQuery()});
  Stream<List<T>> streamQuery({Query query = const AllQuery()});

  Future<T> add(IdentifiedObject<T> item);
  Future<T> update(String id, T Function(T current) updater);
  Future<void> delete(String id);

  //batch operations
  Future<Iterable<T>> addAll(Iterable<IdentifiedObject<T>> items);
  Future<Iterable<T>> updateAll(Iterable<IdentifiedObject<T>> items);
  Future<void> deleteAll(Iterable<String> ids);

  //auto identify
  
  /// Generates a unique ID for an object and returns an [IdentifiedObject].
  ///
  /// If [updateObjectWithId] is provided, the object is updated with the generated ID.
  /// If not provided, the object remains unchanged.
  IdentifiedObject<T> autoIdentify(
    T object, {
    T Function(T object, String id)? updateObjectWithId,
  });

  /// Convenience method that combines [autoIdentify] and [add].
  ///
  /// If [updateObjectWithId] is provided, the object is updated with the generated ID.
  /// If not provided, the object remains unchanged.
  Future<T> addAutoIdentified(
    T object, {
    T Function(T object, String id)? updateObjectWithId,
  });

  void dispose();
}
