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

class IdentifedObject<T> {
  IdentifedObject(this.id, this.object);
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
  Future<T> get(String id);
  Stream<T> stream(String id);
  Future<List<T>> query({Query query = const AllQuery()});
  Stream<List<T>> streamQuery({Query query = const AllQuery()});

  Future<T> add(IdentifedObject<T> item);
  Future<T> update(String id, T Function(T current) updater);
  Future<void> delete(String id);

  //batch operations
  Future<Iterable<T>> addAll(Iterable<IdentifedObject<T>> items);
  Future<Iterable<T>> updateAll(Iterable<IdentifedObject<T>> items);
  Future<void> deleteAll(Iterable<String> ids);

  //dispose
  void dispose();
}
