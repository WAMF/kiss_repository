# Generic Repository Interface

A lightweight, flexible repository pattern implementation for Dart applications following the KISS (Keep It Simple, Stupid) principle. This package provides a generic interface for data access operations, allowing easy swapping between different storage implementations while maintaining a consistent API.

## Features

- Generic repository interface supporting any data type
- Consistent API for both single and batch operations
- Support for both one-time queries and streaming data
- Error handling with typed exceptions
- Minimal and flexible query system
- Easy to implement and extend
- **In-memory reference implementation included**
- **Dispose method for proper resource cleanup**

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  kiss_repository: ^0.9.0
```

## Usage

### Basic Implementation

This package provides both the interface and an in-memory reference implementation. You can use the in-memory implementation directly for testing or simple use cases, or implement the interface for your specific storage needs.

We also provide a Firebase implementation in another package. If you're just looking for a working repository, it's probably best to use that.

### Using the In-Memory Implementation

```dart
import 'package:kiss_repository/kiss_repository.dart';

// Define your query builder
class MyQueryBuilder implements QueryBuilder<InMemoryFilterQuery<MyObject>> {
  @override
  InMemoryFilterQuery<MyObject> build(Query query) {
    if (query is MyCustomQuery) {
      return InMemoryFilterQuery<MyObject>((item) => item.field == query.value);
    }
    return InMemoryFilterQuery<MyObject>((item) => true);
  }
}

// Create the repository
final repository = InMemoryRepository<MyObject>(
  queryBuilder: MyQueryBuilder(),
  path: 'my_objects',
);

// Use it
final item = MyObject(name: 'test');
final added = await repository.add(IdentifedObject('id1', item));
final retrieved = await repository.get('id1');

// Don't forget to dispose when done
repository.dispose();
```

### Available Operations

The repository interface provides the following operations:

#### Read Operations
- `get(String id)`: Fetch a single item by ID
- `stream(String id)`: Stream updates for a single item
- `query({Query query})`: Fetch multiple items based on a query
- `streamQuery({Query query})`: Stream updates for multiple items

#### Single Operations
- `add(IdentifedObject<T> item)`: Add a new item with a specific ID
- `update(String id, T Function(T current) updater)`: Update an existing item
- `delete(String id)`: Delete an item by ID

#### Batch Operations
- `addAll(Iterable<IdentifedObject<T>> items)`: Add multiple items
- `updateAll(Iterable<IdentifedObject<T>> items)`: Update multiple items
- `deleteAll(Iterable<String> ids)`: Delete multiple items

#### Resource Management
- `dispose()`: Clean up streams and resources

**Important Note:** ID generation is explicitly out of scope for this interface. You must provide IDs when adding items using `IdentifedObject<T>`.

### Error Handling

The package includes a `RepositoryException` class for error handling:

```dart
try {
  final user = await userRepository.get('non-existing-id');
} on RepositoryException catch (e) {
  if (e.code == RepositoryErrorCode.notFound) {
    // Handle not found case
  } else if (e.code == RepositoryErrorCode.alreadyExists) {
    // Handle duplicate ID case
  }
}
```

### Query System

The package includes a simple query system that can be extended for specific needs:

```dart
class UserQuery extends Query {
  final String? role;
  
  const UserQuery({this.role});
}

// For in-memory implementation
class UserFilterQuery extends InMemoryFilterQuery<User> {
  UserFilterQuery(String role) : super((user) => user.role == role);
}

class UserQueryBuilder implements QueryBuilder<InMemoryFilterQuery<User>> {
  @override
  InMemoryFilterQuery<User> build(Query query) {
    if (query is UserQuery && query.role != null) {
      return UserFilterQuery(query.role!);
    }
    return InMemoryFilterQuery<User>((user) => true);
  }
}

// Usage
final admins = await userRepository.query(
  query: UserQuery(role: 'admin')
);
```

### Streaming Data

Both single items and query results support real-time streaming:

```dart
// Stream updates for a single item
repository.stream('user-id').listen((user) {
  print('User updated: ${user.name}');
});

// Stream query results
repository.streamQuery(query: UserQuery(role: 'admin')).listen((admins) {
  print('Admin users: ${admins.length}');
});
```

## Best Practices

1. Keep repository implementations focused on data access
2. Handle errors appropriately using `RepositoryException`
3. Use streaming methods when real-time updates are needed
4. Implement custom queries by extending the `Query` class
5. Use batch operations when performing multiple operations of the same type
6. **Always call `dispose()` when done with a repository to clean up resources**
7. **Handle ID generation outside the repository - the interface expects you to provide IDs**

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
