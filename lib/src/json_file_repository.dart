import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:kiss_repository/src/in_memory_repository.dart';
import 'package:kiss_repository/src/repository.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

String _generateId() {
  return _uuid.v4();
}

/// A file-based JSON implementation of the [Repository] interface.
///
/// This repository stores items in a JSON file on disk. It supports basic CRUD
/// operations and streams for real-time updates.
///
/// The repository provides:
/// - Basic CRUD operations (create, read, update, delete)
/// - Real-time streaming of individual items and query results
/// - Batch operations for multiple items
/// - Query system with custom filters
/// - Persistent storage to JSON file
/// - Automatic cleanup of resources
///
/// Example usage:
/// ```dart
/// final repository = JsonFileRepository<MyObject>(
///   queryBuilder: MyQueryBuilder(),
///   path: 'my_objects',
///   file: File('data.json'),
///   fromJson: (json) => MyObject.fromJson(json),
///   toJson: (obj) => obj.toJson(),
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
class JsonFileRepository<T> implements Repository<T> {
  /// Creates a new JSON file repository.
  ///
  /// [queryBuilder] - Builder for creating custom filter queries
  /// [path] - The path/namespace for this repository
  /// [file] - The file to persist data to
  /// [fromJson] - Function to deserialize objects from JSON
  /// [toJson] - Function to serialize objects to JSON
  JsonFileRepository({
    required QueryBuilder<InMemoryFilterQuery<T>> queryBuilder,
    required String path,
    required File file,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
  })  : _queryBuilder = queryBuilder,
        _path = path,
        _file = file,
        _fromJson = fromJson,
        _toJson = toJson {
    _loadFromFile();
  }
  
  final QueryBuilder<InMemoryFilterQuery<T>> _queryBuilder;
  final String _path;
  final File _file;
  final T Function(Map<String, dynamic>) _fromJson;
  final Map<String, dynamic> Function(T) _toJson;
  final Map<String, T> _items = {};

  final Map<String, BehaviorSubject<T>> _itemStreamControllers = {};

  final BehaviorSubject<List<T>> _queryStreamController =
      BehaviorSubject<List<T>>.seeded(
    const [],
  );

  @override
  String? get path => _path;

  String _fullItemPath(String id) => '$_path/$id';

  void _loadFromFile() {
    if (_file.existsSync()) {
      try {
        final content = _file.readAsStringSync();
        if (content.isNotEmpty) {
          (jsonDecode(content) as Map<String, dynamic>).forEach((key, value) {
            if (value is Map<String, dynamic>) {
              _items[key] = _fromJson(value);
            }
          });
          if (_items.isNotEmpty) {
            _queryStreamController
              .add(List<T>.unmodifiable(_items.values));
          }
        }
      } catch (e) {
        throw RepositoryException(
          message: 'Failed to load data from file: $e',
        );
      }
    }
  }

  Future<void> _saveToFile() async {
    try {
      final json = <String, dynamic>{};
      _items.forEach((key, value) {
        json[key] = _toJson(value);
      });
      await _file.writeAsString(jsonEncode(json));
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to save data to file: $e',
      );
    }
  }

  @override
  Future<T> get(String id) async {
    final item = _items[_fullItemPath(id)];
    if (item == null) {
      throw RepositoryException.notFound(id);
    }
    return item;
  }

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
    final itemPath = _fullItemPath(item.id);
    if (_items.containsKey(itemPath)) {
      throw RepositoryException.alreadyExists(item.id);
    }
    _items[itemPath] = item.object;
    await _saveToFile();
    _notifyItemUpdate(item.id, item.object);
    _notifyQueryUpdate();
    return item.object;
  }

  @override
  Future<T> update(String id, T Function(T current) updater) async {
    final itemPath = _fullItemPath(id);
    final currentItem = _items[itemPath];
    if (currentItem == null) {
      throw RepositoryException.notFound(id);
    }
    final updatedItem = updater(currentItem);
    _items[itemPath] = updatedItem;
    await _saveToFile();
    _notifyItemUpdate(id, updatedItem);
    _notifyQueryUpdate();
    return updatedItem;
  }

  @override
  Future<void> delete(String id) async {
    final itemPath = _fullItemPath(id);
    final removedItem = _items.remove(itemPath);
    if (removedItem == null) {
      throw RepositoryException.notFound(id);
    }
    await _saveToFile();
    _notifyItemDelete(id);
    _notifyQueryUpdate();
  }

  @override
  Future<Iterable<T>> addAll(Iterable<IdentifiedObject<T>> items) async {
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
    await _saveToFile();
    for (var i = 0; i < ids.length; i++) {
      _notifyItemUpdate(ids[i], addedItems[i]);
    }
    _notifyQueryUpdate();
    return addedItems;
  }

  @override
  Future<Iterable<T>> updateAll(Iterable<IdentifiedObject<T>> items) async {
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
      await _saveToFile();
      _notifyQueryUpdate();
    }
    return updatedItems;
  }

  @override
  Future<void> deleteAll(Iterable<String> ids) async {
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
      await _saveToFile();
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

  @override
  void dispose() {
    for (final subject in _itemStreamControllers.values) {
      subject.close();
    }
    _itemStreamControllers.clear();
    _queryStreamController.close();
  }
}
