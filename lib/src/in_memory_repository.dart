import 'dart:async';

import 'package:kiss_repository/src/repository.dart';
import 'package:rxdart/rxdart.dart';

/// A query that filters items using a predicate function.
class InMemoryFilterQuery<T> extends Query {
  /// Creates a filter query with the given predicate function.
  const InMemoryFilterQuery(this.filter);

  /// The function used to filter items. Returns `true` if the item should be
  /// included in the results.
  final bool Function(T item) filter;
}

int _idCounter = 0;

String _generateId() {
  return 'Mem-${_idCounter++}';
}

/// A basic in-memory implementation of the [Repository] interface.
///
/// This repository stores items in a simple [Map]. It supports basic CRUD
/// operations and streams for real-time updates.
///
/// The repository provides:
/// - Basic CRUD operations (create, read, update, delete)
/// - Real-time streaming of individual items and query results
/// - Batch operations for multiple items
/// - Query system with custom filters
/// - Automatic cleanup of resources
///
/// Example usage:
/// ```dart
/// final repository = InMemoryRepository<MyObject>(
///   queryBuilder: MyQueryBuilder(),
///   path: 'my_objects',
///   initialItems: [
///     IdentifiedObject('id1', MyObject(name: 'Initial Item 1')),
///     IdentifiedObject('id2', MyObject(name: 'Initial Item 2')),
///   ],
/// );
///
/// // Add an item
/// final item = MyObject(name: 'test');
/// final added = await repository.add(IdentifiedObject('id3', item));
///
/// // Get an item
/// final retrieved = await repository.get('id1');
///
/// // Clean up when done
/// repository.dispose();
/// ```
class InMemoryRepository<T> implements Repository<T> {
  /// Creates a new in-memory repository.
  ///
  /// [queryBuilder] - Builder for creating custom filter queries
  /// [path] - The path/namespace for this repository
  /// [initialItems] - Optional collection of items to populate the
  /// repository with on creation
  InMemoryRepository({
    required QueryBuilder<InMemoryFilterQuery<T>> queryBuilder,
    required String path,
    Iterable<IdentifiedObject<T>>? initialItems,
  })  : _queryBuilder = queryBuilder,
        _path = path {
    if (initialItems != null) {
      for (final item in initialItems) {
        final itemPath = _fullItemPath(item.id);
        _items[itemPath] = item.object;
      }
      if (initialItems.isNotEmpty) {
        _queryStreamController.add(List<T>.unmodifiable(_items.values));
      }
    }
  }
  final QueryBuilder<InMemoryFilterQuery<T>> _queryBuilder;
  final String _path;
  final Map<String, T> _items = {};

  final Map<String, BehaviorSubject<T>> _itemStreamControllers = {};

  final BehaviorSubject<List<T>> _queryStreamController =
      BehaviorSubject<List<T>>.seeded(
    const [],
  );

  @override
  String? get path => _path;

  String _fullItemPath(String id) => '$_path/$id';

  @override
  Future<T> get(String id) async {
    await Future<void>.delayed(Duration.zero);
    final item = _items[_fullItemPath(id)];
    if (item == null) {
      throw RepositoryException.notFound(id);
    }
    return item;
  }

  /// Creates a real-time stream of changes for a specific document.
  ///
  /// **Initial Emission**: Immediately emits existing data when subscribed
  /// (BehaviorSubject-like).
  /// **Deletion Behavior**: InMemory closes stream on deletion.
  @override
  Stream<T> stream(String id) {
    final itemPath = _fullItemPath(id);
    final subject = _itemStreamControllers.putIfAbsent(id, () {
      final currentItem = _items[itemPath];
      if (currentItem != null) {
        return BehaviorSubject<T>.seeded(currentItem);
      } else {
        final error = RepositoryException.notFound(id);
        return BehaviorSubject<T>()..addError(error);
      }
    });

    return (subject
          ..onCancel = () {
            final currentSubject = _itemStreamControllers[id];
            if (currentSubject != null && !currentSubject.hasListener) {
              _itemStreamControllers.remove(id)?.close();
            }
          })
        .stream;
  }

  @override
  Future<List<T>> query({Query query = const AllQuery()}) async {
    return _getFilteredItems(query);
  }

  List<T> _getFilteredItems(Query query) {
    if (query is AllQuery) {
      return List<T>.unmodifiable(_items.values);
    }
    final implementationQuery = _queryBuilder.build(query);
    return List<T>.unmodifiable(
      _items.values.where(implementationQuery.filter),
    );
  }

  @override
  Stream<List<T>> streamQuery({Query query = const AllQuery()}) {
    final subject = BehaviorSubject<List<T>>();
    final subscription = _queryStreamController
        .map((_) => _getFilteredItems(query))
        .handleError(subject.addError)
        .listen(subject.add);

    subject.onCancel = () {
      subscription.cancel();
      if (!subject.hasListener) {
        subject.close();
      }
    };

    return subject.stream;
  }

  @override
  IdentifiedObject<T> autoIdentify(
    T object, {
    T Function(
      T object,
      String id,
    )? updateObjectWithId,
  }) {
    final id = _generateId();
    final updatedObject = updateObjectWithId?.call(object, id) ?? object;
    return IdentifiedObject(id, updatedObject);
  }

  @override
  Future<T> addAutoIdentified(
    T object, {
    T Function(T object, String id)? updateObjectWithId,
  }) async {
    final identified =
        autoIdentify(object, updateObjectWithId: updateObjectWithId);
    return add(identified);
  }

  @override
  Future<T> add(IdentifiedObject<T> item) async {
    await Future<void>.delayed(Duration.zero);
    final itemPath = _fullItemPath(item.id);
    if (_items.containsKey(itemPath)) {
      throw RepositoryException.alreadyExists(item.id);
    }
    _items[itemPath] = item.object;
    _notifyItemUpdate(item.id, item.object);
    _notifyQueryUpdate();
    return item.object;
  }

  @override
  Future<T> update(String id, T Function(T current) updater) async {
    await Future<void>.delayed(Duration.zero);
    final itemPath = _fullItemPath(id);
    final currentItem = _items[itemPath];
    if (currentItem == null) {
      throw RepositoryException.notFound(id);
    }
    final updatedItem = updater(currentItem);
    _items[itemPath] = updatedItem;
    _notifyItemUpdate(id, updatedItem);
    _notifyQueryUpdate();
    return updatedItem;
  }

  @override
  Future<void> delete(String id) async {
    await Future<void>.delayed(Duration.zero);
    final itemPath = _fullItemPath(id);
    final removedItem = _items.remove(itemPath);
    if (removedItem == null) {
      throw RepositoryException.notFound(id);
    }
    _notifyItemDelete(id);
    _notifyQueryUpdate();
  }

  @override
  Future<Iterable<T>> addAll(Iterable<IdentifiedObject<T>> items) async {
    await Future<void>.delayed(Duration.zero);
    final addedItems = <T>[];
    final ids = <String>[];
    for (final item in items) {
      final id = item.id;
      final itemPath = _fullItemPath(id);
      if (_items.containsKey(itemPath)) {
        throw RepositoryException.alreadyExists(id);
      }
      _items[itemPath] = item.object;
      addedItems.add(item.object);
      ids.add(id);
    }
    for (var i = 0; i < ids.length; i++) {
      _notifyItemUpdate(ids[i], addedItems[i]);
    }
    _notifyQueryUpdate();
    return addedItems;
  }

  @override
  Future<Iterable<T>> updateAll(Iterable<IdentifiedObject<T>> items) async {
    await Future<void>.delayed(Duration.zero);
    final updatedItems = <T>[];
    final updates = <String, T>{};

    for (final identifiedObject in items) {
      final itemPath = _fullItemPath(identifiedObject.id);
      if (!_items.containsKey(itemPath)) {
        throw RepositoryException.notFound(identifiedObject.id);
      }
      updates[identifiedObject.id] = identifiedObject.object;
    }

    updates.forEach((id, item) {
      final itemPath = _fullItemPath(id);
      _items[itemPath] = item;
      updatedItems.add(item);
      _notifyItemUpdate(id, item);
    });

    if (updates.isNotEmpty) {
      _notifyQueryUpdate();
    }
    return updatedItems;
  }

  @override
  Future<void> deleteAll(Iterable<String> ids) async {
    await Future<void>.delayed(Duration.zero);
    var changed = false;
    final actuallyDeletedIds = <String>[];
    for (final id in ids) {
      final itemPath = _fullItemPath(id);
      final removedItem = _items.remove(itemPath);
      if (removedItem != null) {
        changed = true;
        actuallyDeletedIds.add(id);
      }
    }

    for (final id in actuallyDeletedIds) {
      _notifyItemDelete(id);
    }

    if (changed) {
      _notifyQueryUpdate();
    }
  }

  void _notifyItemUpdate(String id, T item) {
    _itemStreamControllers.putIfAbsent(id, BehaviorSubject<T>.new).add(item);
  }

  void _notifyItemDelete(String id) {
    final subject = _itemStreamControllers[id];
    if (subject != null) {
      subject.close();
      _itemStreamControllers.remove(id);
    }
  }

  void _notifyQueryUpdate() {
    _queryStreamController.add(List<T>.unmodifiable(_items.values));
  }

  /// Closes all stream controllers. Call this when the repository is disposed.
  @override
  void dispose() {
    for (final subject in _itemStreamControllers.values) {
      subject.close();
    }
    _itemStreamControllers.clear();
    _queryStreamController.close();
  }
}
