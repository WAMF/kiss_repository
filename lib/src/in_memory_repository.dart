import 'dart:async';

import 'package:kiss_repository/src/repository.dart';
import 'package:rxdart/rxdart.dart';

class InMemoryFilterQuery<T> extends Query {
  const InMemoryFilterQuery(this.filter);

  /// The function used to filter items. Returns `true` if the item should be
  /// included in the results.
  final bool Function(T item) filter;
}

/// A basic in-memory implementation of the [Repository] interface.
///
/// This repository stores items in a simple [Map]. It supports basic CRUD
/// operations and streams for real-time updates.
///

int _idCounter = 0;

String _generateId() {
  return 'Mem-${_idCounter++}';
}

class InMemoryRepository<T> implements Repository<T> {
  final QueryBuilder<InMemoryFilterQuery<T>> _queryBuilder;
  final String _path;
  final Map<String, T> _items = {};

  // Stream controller for individual item updates using BehaviorSubject.
  final Map<String, BehaviorSubject<T>> _itemStreamControllers = {};

  // Stream controller for query results using BehaviorSubject, seeded with initial state.
  final BehaviorSubject<List<T>> _queryStreamController =
      BehaviorSubject<List<T>>.seeded(const []); // Seed with empty list initially

  InMemoryRepository({required QueryBuilder<InMemoryFilterQuery<T>> queryBuilder, required String path})
      : _queryBuilder = queryBuilder,
        _path = path;

  @override
  String? get path => _path;

  String _fullItemPath(String id) => '$_path/$id';

  @override
  Future<T> get(String id) async {
    await Future.delayed(Duration.zero); // Simulate async operation
    final item = _items[_fullItemPath(id)];
    if (item == null) {
      throw RepositoryException.notFound(id);
    }
    return item;
  }

  /// Creates a real-time stream of changes for a specific document.
  ///
  /// **Initial Emission**: Immediately emits existing data when subscribed (BehaviorSubject-like).
  /// **Deletion Behavior**: InMemory closes stream on deletion.
  @override
  Stream<T> stream(String id) {
    final itemPath = _fullItemPath(id);
    final subject = _itemStreamControllers.putIfAbsent(id, () {
      final currentItem = _items[itemPath];
      // Seed the BehaviorSubject with the current item or an error if not found
      if (currentItem != null) {
        return BehaviorSubject<T>.seeded(currentItem);
      } else {
        // Seed with error if not found initially
        final error = RepositoryException.notFound(id);
        final subject = BehaviorSubject<T>();
        subject.addError(error); // Add error immediately after creation
        return subject;
      }
    });

    // BehaviorSubject automatically emits the last value (or error) to new listeners.

    // Clean up controller when no listeners are left
    // Using onListen/onCancel to manage the lifecycle correctly with BehaviorSubject
    subject.onCancel = () {
      // Check if this specific subject associated with 'id' still exists and has no listeners
      final currentSubject = _itemStreamControllers[id];
      if (currentSubject != null && !currentSubject.hasListener) {
        _itemStreamControllers.remove(id)?.close();
      }
    };

    return subject.stream;
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
    return List<T>.unmodifiable(_items.values.where(implementationQuery.filter));
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
    final identified = autoIdentify(object, updateObjectWithId: updateObjectWithId);
    return add(identified);
  }

  @override
  Future<T> add(IdentifiedObject<T> item) async {
    await Future.delayed(Duration.zero);
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
    await Future.delayed(Duration.zero);
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
    await Future.delayed(Duration.zero);
    final itemPath = _fullItemPath(id);
    final removedItem = _items.remove(itemPath);
    if (removedItem != null) {
      _notifyItemDelete(id);
      _notifyQueryUpdate();
    }
    // Silently succeed if item doesn't exist (consistent with other implementations)
  }

  // --- Batch Operations ---

  @override
  Future<Iterable<T>> addAll(Iterable<IdentifiedObject<T>> items) async {
    await Future.delayed(Duration.zero);
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
    await Future.delayed(Duration.zero);
    final updatedItems = <T>[];
    final Map<String, T> updates = {};

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
    await Future.delayed(Duration.zero);
    bool changed = false;
    final List<String> actuallyDeletedIds = []; // Keep track of IDs actually deleted
    for (final id in ids) {
      final itemPath = _fullItemPath(id);
      final removedItem = _items.remove(itemPath);
      if (removedItem != null) {
        changed = true;
        actuallyDeletedIds.add(id); // Add to list for notification *after* loop
      }
    }

    // Notify deletions after all removals are done
    for (final id in actuallyDeletedIds) {
      _notifyItemDelete(id);
    }

    if (changed) {
      _notifyQueryUpdate();
    }
  }

  // --- Helper Methods for Stream Notifications ---

  void _notifyItemUpdate(String id, T item) {
    // If a stream exists for this item, add the updated item.
    // If not, create a new BehaviorSubject seeded with the item.
    final subject = _itemStreamControllers.putIfAbsent(id, () => BehaviorSubject<T>());
    subject.add(item);
  }

  void _notifyItemDelete(String id) {
    // Close the stream when item is deleted (consistent with other implementations)
    final subject = _itemStreamControllers[id];
    if (subject != null) {
      subject.close();
      _itemStreamControllers.remove(id); // Remove after closing
    }
  }

  void _notifyQueryUpdate() {
    _queryStreamController.add(List<T>.unmodifiable(_items.values));
  }

  /// Closes all stream controllers. Call this when the repository is disposed.
  @override
  void dispose() {
    // Close all individual item subjects
    for (var subject in _itemStreamControllers.values) {
      subject.close();
    }
    _itemStreamControllers.clear();
    // Close the main query subject
    _queryStreamController.close();
  }
}
