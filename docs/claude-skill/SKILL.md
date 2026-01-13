---
name: kiss-repository
description: Guide for implementing and using kiss_repository - a lightweight Dart repository pattern for data access with CRUD, streaming, and batch operations
allowed-tools: Read, Grep, Glob
---

# kiss_repository Usage Guide

A lightweight, generic repository pattern implementation for Dart following the KISS principle.

## Core Concepts

### Repository<T>

The abstract base class defining all data operations. Generic type `T` is your domain model.

### IdentifiedObject<T>

Wraps an object with its unique string ID:

```dart
final item = IdentifiedObject('user-123', User(name: 'Alice'));
// item.id == 'user-123'
// item.object == User(name: 'Alice')
```

### Query System

Extend `Query` for domain-specific filters. Implement `QueryBuilder<T>` to translate queries to your implementation.

## Available Implementations

- **InMemoryRepository<T>**: Testing and temporary storage
- **JsonFileRepository<T>**: File-based JSON persistence

## CRUD Operations

### Reading Data

```dart
// Get single item by ID (throws RepositoryException.notFound if missing)
final user = await repository.get('user-123');

// Query multiple items
final users = await repository.query(query: ActiveUsersQuery());

// Get all items
final allUsers = await repository.query();
```

### Creating Data

```dart
// Add with explicit ID
await repository.add(IdentifiedObject('user-123', user));

// Add with auto-generated ID
await repository.addAutoIdentified(
  user,
  updateObjectWithId: (user, id) => user.copyWith(id: id),
);
```

### Updating Data

```dart
// Update with transformer function
final updated = await repository.update('user-123', (current) =>
  current.copyWith(name: 'New Name')
);
```

### Deleting Data

```dart
await repository.delete('user-123');
```

## Batch Operations

```dart
// Add multiple items atomically
await repository.addAll([
  IdentifiedObject('id1', item1),
  IdentifiedObject('id2', item2),
]);

// Update multiple items
await repository.updateAll([
  IdentifiedObject('id1', updatedItem1),
  IdentifiedObject('id2', updatedItem2),
]);

// Delete multiple items
await repository.deleteAll(['id1', 'id2', 'id3']);
```

## Streaming (Real-time Updates)

```dart
// Stream single item changes
repository.stream('user-123').listen((user) {
  print('User updated: ${user.name}');
});

// Stream query results
repository.streamQuery(query: ActiveUsersQuery()).listen((users) {
  print('Active users: ${users.length}');
});
```

Streams emit immediately with current data (BehaviorSubject-like behavior).

## Query Implementation

### Define Custom Query

```dart
class UsersByRoleQuery extends Query {
  const UsersByRoleQuery(this.role);
  final String role;
}
```

### Implement QueryBuilder

```dart
class UserQueryBuilder implements QueryBuilder<InMemoryFilterQuery<User>> {
  @override
  InMemoryFilterQuery<User> build(Query query) {
    if (query is UsersByRoleQuery) {
      return InMemoryFilterQuery<User>((user) => user.role == query.role);
    }
    return InMemoryFilterQuery<User>((user) => true);
  }
}
```

## Error Handling

```dart
try {
  final user = await repository.get('non-existent');
} on RepositoryException catch (e) {
  switch (e.code) {
    case RepositoryErrorCode.notFound:
      // Item doesn't exist
    case RepositoryErrorCode.alreadyExists:
      // ID already in use (on add)
    case RepositoryErrorCode.unknown:
      // Other error
  }
}
```

## Creating a Repository

### InMemoryRepository

```dart
final repository = InMemoryRepository<User>(
  queryBuilder: UserQueryBuilder(),
  path: 'users',
  initialItems: [
    IdentifiedObject('user-1', User(name: 'Alice')),
  ],
);
```

### JsonFileRepository

```dart
final repository = JsonFileRepository<User>(
  queryBuilder: UserQueryBuilder(),
  path: 'users',
  file: File('users.json'),
  fromJson: User.fromJson,
  toJson: (user) => user.toJson(),
);
```

## Resource Management

Always dispose repositories when done:

```dart
repository.dispose();
```

This cleans up all internal streams and resources.

## Best Practices

1. Generate IDs outside the repository or use `addAutoIdentified`
2. Use `InMemoryRepository` for unit tests
3. Use `JsonFileRepository` for integration tests
4. Always call `dispose()` when done
5. Handle `RepositoryException` for error cases
6. Use streaming for real-time UI updates
7. Use batch operations for multiple items of same type
