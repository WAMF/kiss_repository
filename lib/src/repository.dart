import 'dart:async';

/// Base class for all query types.
class Query {
  /// Creates a new query.
  const Query();
}

/// A query that matches all items.
class AllQuery extends Query {
  /// Creates a new all query.
  const AllQuery();
}

/// Builds implementation-specific queries from generic queries.
// ignore: one_member_abstracts
abstract class QueryBuilder<T> {
  /// Builds an implementation-specific query from a generic query.
  T build(Query query);
}

/// Wraps an object with its unique identifier.
class IdentifiedObject<T> {
  /// Creates an identified object with the given ID and object.
  IdentifiedObject(this.id, this.object);

  /// The unique identifier for this object.
  final String id;

  /// The wrapped object.
  final T object;
}

/// Error codes for repository operations.
enum RepositoryErrorCode {
  /// Item was not found.
  notFound,

  /// Item already exists.
  alreadyExists,

  /// Unknown error.
  unknown
}

/// Exception thrown by repository operations.
class RepositoryException implements Exception {
  /// Creates a repository exception with the given message and error code.
  RepositoryException({
    required this.message,
    this.code = RepositoryErrorCode.unknown,
  });

  /// Creates a not found exception for the given ID.
  factory RepositoryException.notFound(String id) {
    return RepositoryException(
      message: 'Item with id $id not found',
      code: RepositoryErrorCode.notFound,
    );
  }

  /// Creates an already exists exception for the given ID.
  factory RepositoryException.alreadyExists(String id) {
    return RepositoryException(
      message: 'Item with id $id already exists',
      code: RepositoryErrorCode.alreadyExists,
    );
  }

  /// The error message.
  final String message;

  /// The error code.
  final RepositoryErrorCode code;

  @override
  String toString() => 'RepositoryException: $message';
}

/// Generic repository interface for CRUD operations.
abstract class Repository<T> {
  /// The path or location of this repository.
  String? get path;

  /// Returns the item with the given ID.
  /// Throws [RepositoryException.notFound] if the item does not exist.
  Future<T> get(String id);

  /// Creates a real-time stream of changes for a specific document.
  ///
  /// **Initial Emission**: Immediately emits existing data
  /// (BehaviorSubject-like).
  /// **Error**: Emits [RepositoryException.notFound] if document doesn't exist
  /// (consistent with get).
  /// **Deletion**: Stream closes when document is deleted.
  /// **Error**: Emits [RepositoryException.notFound] if document doesn't exist
  /// (consistent with get).
  Stream<T> stream(String id);

  /// Queries for items matching the given query.
  Future<List<T>> query({Query query = const AllQuery()});

  /// Creates a real-time stream of query results.
  Stream<List<T>> streamQuery({Query query = const AllQuery()});

  /// Adds a new item to the repository.
  Future<T> add(IdentifiedObject<T> item);

  /// Updates an existing item in the repository.
  Future<T> update(String id, T Function(T current) updater);

  /// Deletes an item from the repository.
  Future<void> delete(String id);

  /// Adds multiple items to the repository.
  Future<Iterable<T>> addAll(Iterable<IdentifiedObject<T>> items);

  /// Updates multiple items in the repository.
  Future<Iterable<T>> updateAll(Iterable<IdentifiedObject<T>> items);

  /// Deletes multiple items from the repository.
  Future<void> deleteAll(Iterable<String> ids);

  /// Generates a unique ID for an object and returns an [IdentifiedObject].
  ///
  /// If [updateObjectWithId] is provided, the object is updated with the
  /// generated ID.
  /// If not provided, the object remains unchanged.
  IdentifiedObject<T> autoIdentify(
    T object, {
    T Function(T object, String id)? updateObjectWithId,
  });

  /// Convenience method that combines [autoIdentify] and [add].
  ///
  /// If [updateObjectWithId] is provided, the object is updated with the
  /// generated ID.
  /// If not provided, the object remains unchanged.
  Future<T> addAutoIdentified(
    T object, {
    T Function(T object, String id)? updateObjectWithId,
  });

  /// Disposes of the repository and cleans up resources.
  void dispose();
}
