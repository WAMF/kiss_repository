# Generic Repository Interface

A lightweight, flexible repository pattern implementation for Dart applications following the KISS (Keep It Simple, Stupid) principle. This package provides a generic interface for data access operations, allowing easy swapping between different storage implementations while maintaining a consistent API.

## Features

- Generic repository interface supporting any data type
- Consistent API for both single and batch operations
- Support for both one-time queries and streaming data
- Error handling with typed exceptions
- Minimal and flexible query system
- Easy to implement and extend

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  kiss_repository: ^1.0.0
```

## Usage

### Basic Implementation

This package just defines the interface. You need to implement it for your specific data type:
We provide a Firebase implementation in another package. If your just looking for a working repository, its probably best to use that.

### Available Operations

The repository interface provides the following operations:

#### Read Operations
- `get(String id)`: Fetch a single item by ID
- `stream(String id)`: Stream updates for a single item
- `query({Query query})`: Fetch multiple items based on a query
- `streamQuery({Query query})`: Stream updates for multiple items

#### Single Operations
- `add(T item)`: Add a new item
- `update(String id, T Function(T current) updater)`: Update an existing item
- `delete(String id)`: Delete an item by ID

#### Batch Operations
- `addAll(Iterable<T> items)`: Add multiple items
- `updateAll(Iterable<IdentifedObject<T>> items)`: Update multiple items
- `deleteAll(Iterable<String> ids)`: Delete multiple items

### Error Handling

The package includes a `RepositoryException` class for error handling:

```dart
try {
  final user = await userRepository.get('non-existing-id');
} on RepositoryException catch (e) {
  if (e.code == RepositoryErrorCode.notFound) {
    // Handle not found case
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

// Usage
final admins = await userRepository.query(
  query: UserQuery(role: 'admin')
);
```

You will need to implement a `QueryBuilder` for your specific implementation.

## Best Practices

1. Keep repository implementations focused on data access
2. Handle errors appropriately using `RepositoryException`
3. Use streaming methods when real-time updates are needed
4. Implement custom queries by extending the `Query` class
5. Use batch operations when performing multiple operations of the same type

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.