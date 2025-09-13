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
- **JSON file-based implementation for persistent storage**
- **Dispose method for proper resource cleanup**

## Installation

Add this package using the Dart pub command:

```bash
dart pub add kiss_repository
```

## Usage

### Basic Implementation

This package provides the interface along with two reference implementations:
- **InMemoryRepository** - Perfect for testing and temporary data storage
- **JsonFileRepository** - File-based persistence for testing and simple applications

You can use these implementations directly for testing or simple use cases, or implement the interface for your specific storage needs.

We also provide production-ready implementations in other packages (Firebase, PocketBase, DynamoDB, etc.) for real-world applications.

### Using the Reference Implementations

#### In-Memory Repository (Testing & Temporary Storage)

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

// Create the repository - perfect for unit tests
final repository = InMemoryRepository<MyObject>(
  queryBuilder: MyQueryBuilder(),
  path: 'my_objects',
  initialItems: [
    IdentifiedObject('id1', MyObject(name: 'test1')),
    IdentifiedObject('id2', MyObject(name: 'test2')),
  ],
);

// Use it
final item = MyObject(name: 'test');
final added = await repository.add(IdentifiedObject('id3', item));
final retrieved = await repository.get('id1');

// Don't forget to dispose when done
repository.dispose();
```

#### JSON File Repository (Persistent Testing & Simple Apps)

```dart
import 'dart:io';
import 'package:kiss_repository/kiss_repository.dart';

// Create a file-based repository - great for integration tests
final repository = JsonFileRepository<MyObject>(
  queryBuilder: MyQueryBuilder(),
  path: 'my_objects',
  file: File('test_data.json'),
  fromJson: (json) => MyObject.fromJson(json),
  toJson: (obj) => obj.toJson(),
);

// Data persists across application restarts
final item = MyObject(name: 'test');
final added = await repository.add(IdentifiedObject('id1', item));

// Later, even after restart...
final retrieved = await repository.get('id1'); // Still there!

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
- `add(IdentifiedObject<T> item)`: Add a new item with a specific ID
- `update(String id, T Function(T current) updater)`: Update an existing item
- `delete(String id)`: Delete an item by ID

#### Batch Operations
- `addAll(Iterable<IdentifiedObject<T>> items)`: Add multiple items
- `updateAll(Iterable<IdentifiedObject<T>> items)`: Update multiple items
- `deleteAll(Iterable<String> ids)`: Delete multiple items

#### Resource Management
- `dispose()`: Clean up streams and resources

**Important Note:** ID generation is explicitly out of scope for this interface. You must provide IDs when adding items using `IdentifiedObject<T>`.

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

## 🧪 Testing

This package includes comprehensive tests that are available as a separate package: **[kiss_repository_tests](https://pub.dev/packages/kiss_repository_tests)**

### Testing Benefits of Included Implementations

The package includes two implementations that are particularly useful for testing:

#### InMemoryRepository - Unit Testing
- **Zero dependencies**: No external services or files needed
- **Fast execution**: Everything runs in memory
- **Predictable behavior**: No network latency or disk I/O
- **Easy setup**: Initialize with test data using `initialItems`
- **Perfect isolation**: Each test gets a fresh instance

```dart
test('should update user role', () async {
  final repository = InMemoryRepository<User>(
    queryBuilder: UserQueryBuilder(),
    path: 'users',
    initialItems: [
      IdentifiedObject('user1', User(name: 'Alice', role: 'viewer')),
    ],
  );

  await repository.update('user1', (user) => user.copyWith(role: 'admin'));
  final updated = await repository.get('user1');
  expect(updated.role, equals('admin'));
});
```

#### JsonFileRepository - Integration Testing
- **Persistent state**: Test data survives between test runs
- **Real file I/O**: Tests actual persistence logic
- **Easy debugging**: Inspect JSON files to see exact data
- **Migration testing**: Test data format changes and upgrades
- **Production-like**: Closer to real storage implementations

```dart
test('should persist data across repository instances', () async {
  final file = File('test_users.json');

  // First instance - write data
  var repository = JsonFileRepository<User>(
    queryBuilder: UserQueryBuilder(),
    path: 'users',
    file: file,
    fromJson: User.fromJson,
    toJson: (user) => user.toJson(),
  );
  await repository.add(IdentifiedObject('user1', User(name: 'Bob')));
  repository.dispose();

  // Second instance - read persisted data
  repository = JsonFileRepository<User>(
    queryBuilder: UserQueryBuilder(),
    path: 'users',
    file: file,
    fromJson: User.fromJson,
    toJson: (user) => user.toJson(),
  );
  final user = await repository.get('user1');
  expect(user.name, equals('Bob'));

  // Cleanup
  file.deleteSync();
});
```

### Using the Test Suite

All repository implementations should use the shared test suite to ensure consistency and completeness. Add the test packages to your project:

```bash
dart pub add --dev kiss_repository_tests test
```

### Running Tests for Your Implementation

```dart
import 'package:kiss_repository_tests/kiss_repository_tests.dart';

void main() {
  runRepositoryTests(
    implementationName: 'MyImplementation',
    factoryProvider: () => MyRepositoryFactory(),
    cleanup: () {},
  );
}
```

The test suite covers:
- ✅ **ID Management** - Auto-generation and validation
- ✅ **CRUD Operations** - Create, Read, Update, Delete
- ✅ **Batch Operations** - Multi-item operations
- ✅ **Query System** - Filtering and searching
- ✅ **Streaming** - Real-time updates
- ✅ **Error Handling** - Exception scenarios
- ✅ **Resource Management** - Disposal and cleanup

### Benefits of Shared Tests

- **Consistency**: All implementations behave the same way
- **Completeness**: No missing functionality
- **Reliability**: Battle-tested scenarios
- **Documentation**: Tests serve as living documentation
- **Regression Protection**: Prevents breaking changes

## Development Pattern for New Repository Implementations

When creating a new repository implementation, follow this standardized pattern:

### 1. Environment Setup
Set up a testing environment (emulator, local instance, Docker) with configuration files and setup scripts.

### 2. Test-Driven Development
Write your implementation using TDD with the universal factory pattern:

#### Factory Pattern Implementation
1. **Create a Factory**: Implement `RepositoryFactory` interface from `package:kiss_repository_tests`:
```dart
import 'package:kiss_repository_tests/kiss_repository_tests.dart';

class MyRepositoryFactory implements RepositoryFactory<ProductModel> {
  @override
  Future<Repository<ProductModel>> createRepository() async {
    // Return your repository instance
    return MyRepository<ProductModel>(/* configuration */);
  }

  @override
  Future<void> cleanup() async {
    // Clean up test data between tests
  }

  @override
  void dispose() {
    // Final cleanup
  }
}
```

2. **Run Shared Tests**: Use the factory with `runRepositoryTests`:
```dart
import 'package:kiss_repository_tests/kiss_repository_tests.dart';

void main() {
  runRepositoryTests(
    implementationName: 'MyImplementation',
    factoryProvider: () => MyRepositoryFactory(),
    cleanup: () {},
  );
}
```

3. **Test Organization**:
   - Use `test/integration/` for pure Dart packages
   - Use `integration_test/` for Flutter packages
   - Implement progressively: ID Management → CRUD → Batch → Query → Streaming

### 3. Example Integration
Build a working Flutter app in `example/` demonstrating CRUD, queries, streaming, and batch operations with comprehensive integration tests.

### 4. Documentation
Add your implementation to the comparison table below, documenting capabilities, limitations, and unique features compared to existing implementations.

## 🔄 Available Implementations

| Implementation | Platform | Use Case |
|----------------|----------|----------|
| **InMemoryRepository** (included) | Pure Dart | Unit testing, temporary storage |
| **JsonFileRepository** (included) | Pure Dart | Integration testing, simple persistence |
| **[Firebase Firestore](https://github.com/WAMF/kiss_firebase_repository)** | Flutter | Real-time apps with offline support |
| **[PocketBase](https://github.com/WAMF/kiss_pocketbase_repository)** | Pure Dart | Self-hosted apps |
| **[AWS DynamoDB](https://github.com/WAMF/kiss_dynamodb_repository)** | Pure Dart | Server-side/enterprise apps |
| **[Drift (SQLite)](https://github.com/WAMF/kiss_drift_repository)** | Pure Dart | Local/embedded database apps |


**ID Generation:** Firebase/InMemory/Drift return what you specify, while PocketBase/DynamoDB always return the complete database record.

## 📁 Example Application

A centralized example application is included that demonstrates how to switch between different repository implementations:

- **[Centralized Example](https://github.com/WAMF/kiss_repository/tree/main/example)** - Flutter app that allows switching between Firebase, PocketBase, and DynamoDB implementations

## 🤝 Contributing

1. Make changes to the appropriate repository
2. Run tests for that specific repository
3. Update documentation if needed
4. Submit pull request to the specific repository

## 📄 License

MIT License - see individual repositories for details.
