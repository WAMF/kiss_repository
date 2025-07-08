# Kiss Repository Usage Guide for Claude Code

A simple, generic repository interface for Dart applications following the KISS principle. This guide shows you how to get started quickly with the kiss_repository package.

## Quick Start

### 1. Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  kiss_repository: ^0.11.0
```

Run:
```bash
dart pub get
```

### 2. Basic Setup

```dart
import 'package:kiss_repository/kiss_repository.dart';

// Define your data model
class User {
  final String name;
  final String email;
  final String role;
  
  User({required this.name, required this.email, required this.role});
}

// Create a simple query builder for filtering
class UserQueryBuilder implements QueryBuilder<InMemoryFilterQuery<User>> {
  @override
  InMemoryFilterQuery<User> build(Query query) {
    if (query is UserRoleQuery) {
      return InMemoryFilterQuery<User>((user) => user.role == query.role);
    }
    return InMemoryFilterQuery<User>((user) => true); // Return all
  }
}

// Define custom queries
class UserRoleQuery extends Query {
  final String role;
  const UserRoleQuery(this.role);
}
```

### 3. Initialize Repository

```dart
void main() async {
  // Create the repository with in-memory implementation
  final userRepository = InMemoryRepository<User>(
    queryBuilder: UserQueryBuilder(),
    path: 'users',
  );
  
  // Your app logic here...
  
  // Always dispose when done
  userRepository.dispose();
}
```

## Core Operations

### Adding Items

```dart
// Add a single user (you must provide an ID)
final user = User(name: 'John Doe', email: 'john@example.com', role: 'admin');
final addedUser = await userRepository.add(
  IdentifiedObject('user-1', user)
);

// Add multiple users
final users = [
  IdentifiedObject('user-2', User(name: 'Jane', email: 'jane@example.com', role: 'user')),
  IdentifiedObject('user-3', User(name: 'Bob', email: 'bob@example.com', role: 'admin')),
];
await userRepository.addAll(users);
```

### Reading Items

```dart
// Get a single user
try {
  final user = await userRepository.get('user-1');
  print('Found user: ${user.name}');
} on RepositoryException catch (e) {
  if (e.code == RepositoryErrorCode.notFound) {
    print('User not found');
  }
}

// Query all users
final allUsers = await userRepository.query();

// Query with filter
final admins = await userRepository.query(
  query: UserRoleQuery('admin')
);
```

### Updating Items

```dart
// Update a single user
final updatedUser = await userRepository.update('user-1', (current) {
  return User(
    name: current.name,
    email: 'newemail@example.com', // Change email
    role: current.role,
  );
});

// Update multiple users
final updates = [
  IdentifiedObject('user-2', User(name: 'Jane Smith', email: 'jane.smith@example.com', role: 'admin')),
  IdentifiedObject('user-3', User(name: 'Bob Johnson', email: 'bob.johnson@example.com', role: 'user')),
];
await userRepository.updateAll(updates);
```

### Deleting Items

```dart
// Delete a single user
await userRepository.delete('user-1');

// Delete multiple users
await userRepository.deleteAll(['user-2', 'user-3']);
```

## Streaming Data (Real-time Updates)

```dart
// Stream a single user's updates
userRepository.stream('user-1').listen((user) {
  print('User updated: ${user.name}');
});

// Stream query results
userRepository.streamQuery(query: UserRoleQuery('admin')).listen((admins) {
  print('Admin count: ${admins.length}');
});
```

## Complete Example

```dart
import 'package:kiss_repository/kiss_repository.dart';

class User {
  final String name;
  final String email;
  final String role;
  
  User({required this.name, required this.email, required this.role});
  
  @override
  String toString() => 'User(name: $name, email: $email, role: $role)';
}

class UserRoleQuery extends Query {
  final String role;
  const UserRoleQuery(this.role);
}

class UserQueryBuilder implements QueryBuilder<InMemoryFilterQuery<User>> {
  @override
  InMemoryFilterQuery<User> build(Query query) {
    if (query is UserRoleQuery) {
      return InMemoryFilterQuery<User>((user) => user.role == query.role);
    }
    return InMemoryFilterQuery<User>((user) => true);
  }
}

void main() async {
  // Create repository
  final userRepository = InMemoryRepository<User>(
    queryBuilder: UserQueryBuilder(),
    path: 'users',
  );
  
  try {
    // Add some users
    await userRepository.addAll([
      IdentifiedObject('1', User(name: 'Alice', email: 'alice@example.com', role: 'admin')),
      IdentifiedObject('2', User(name: 'Bob', email: 'bob@example.com', role: 'user')),
      IdentifiedObject('3', User(name: 'Charlie', email: 'charlie@example.com', role: 'admin')),
    ]);
    
    // Query all users
    final allUsers = await userRepository.query();
    print('All users: ${allUsers.length}');
    
    // Query admins only
    final admins = await userRepository.query(query: UserRoleQuery('admin'));
    print('Admins: ${admins.map((u) => u.name).join(', ')}');
    
    // Update a user
    await userRepository.update('2', (current) {
      return User(name: current.name, email: current.email, role: 'admin');
    });
    
    // Stream admin updates
    userRepository.streamQuery(query: UserRoleQuery('admin')).listen((admins) {
      print('Current admins: ${admins.map((u) => u.name).join(', ')}');
    });
    
    // Add another admin to see the stream update
    await Future.delayed(Duration(seconds: 1));
    await userRepository.add(
      IdentifiedObject('4', User(name: 'David', email: 'david@example.com', role: 'admin'))
    );
    
    await Future.delayed(Duration(seconds: 1));
    
  } catch (e) {
    print('Error: $e');
  } finally {
    // Always dispose
    userRepository.dispose();
  }
}
```

## Error Handling

```dart
try {
  final user = await userRepository.get('non-existent');
} on RepositoryException catch (e) {
  switch (e.code) {
    case RepositoryErrorCode.notFound:
      print('User not found');
      break;
    case RepositoryErrorCode.alreadyExists:
      print('User already exists');
      break;
    case RepositoryErrorCode.unknown:
      print('Unknown error: ${e.message}');
      break;
  }
}
```

## Key Points

1. **IDs are required**: You must provide IDs when adding items using `IdentifiedObject<T>`
2. **Always dispose**: Call `repository.dispose()` when you're done to clean up resources
3. **Custom queries**: Extend the `Query` class and implement query builders for filtering
4. **Streaming**: Use `stream()` and `streamQuery()` for real-time updates
5. **Batch operations**: Use `addAll()`, `updateAll()`, `deleteAll()` for better performance

## Available Implementations

- **InMemory**: Built-in, great for testing and simple use cases
- **Firebase**: Available as separate package
- **PocketBase**: Available as separate package  
- **AWS DynamoDB**: Available as separate package

This gets you started with the kiss_repository pattern. For production use, consider using one of the persistent storage implementations like Firebase or PocketBase.
