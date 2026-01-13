# kiss_repository API Reference

## Repository<T>

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `path` | `String?` | Logical path/namespace for this repository |

### Read Operations

| Method | Signature | Description |
|--------|-----------|-------------|
| `get` | `Future<T> get(String id)` | Get item by ID. Throws `RepositoryException.notFound` if missing |
| `stream` | `Stream<T> stream(String id)` | Stream item updates. Emits immediately, closes on delete |
| `query` | `Future<List<T>> query({Query query})` | Get items matching query. Defaults to all items |
| `streamQuery` | `Stream<List<T>> streamQuery({Query query})` | Stream query results with real-time updates |

### Write Operations

| Method | Signature | Description |
|--------|-----------|-------------|
| `add` | `Future<T> add(IdentifiedObject<T> item)` | Add new item. Throws `RepositoryException.alreadyExists` if ID exists |
| `update` | `Future<T> update(String id, T Function(T) updater)` | Update existing item. Throws `RepositoryException.notFound` if missing |
| `delete` | `Future<void> delete(String id)` | Delete item. Throws `RepositoryException.notFound` if missing |

### Batch Operations

| Method | Signature | Description |
|--------|-----------|-------------|
| `addAll` | `Future<Iterable<T>> addAll(Iterable<IdentifiedObject<T>> items)` | Add multiple items atomically |
| `updateAll` | `Future<Iterable<T>> updateAll(Iterable<IdentifiedObject<T>> items)` | Update multiple items |
| `deleteAll` | `Future<void> deleteAll(Iterable<String> ids)` | Delete multiple items (ignores missing) |

### ID Generation

| Method | Signature | Description |
|--------|-----------|-------------|
| `autoIdentify` | `IdentifiedObject<T> autoIdentify(T object, {T Function(T, String)? updateObjectWithId})` | Generate unique ID for object |
| `addAutoIdentified` | `Future<T> addAutoIdentified(T object, {T Function(T, String)? updateObjectWithId})` | Generate ID and add in one call |

### Lifecycle

| Method | Signature | Description |
|--------|-----------|-------------|
| `dispose` | `void dispose()` | Clean up streams and resources |

## IdentifiedObject<T>

| Member | Type | Description |
|--------|------|-------------|
| `id` | `String` | Unique identifier |
| `object` | `T` | The wrapped object |

Constructor: `IdentifiedObject(String id, T object)`

## Query Classes

| Class | Description |
|-------|-------------|
| `Query` | Base class for all queries. Extend for custom filters |
| `AllQuery` | Default query matching all items |
| `InMemoryFilterQuery<T>` | Filter using predicate function `bool Function(T)` |

## QueryBuilder<T>

| Method | Signature | Description |
|--------|-----------|-------------|
| `build` | `T build(Query query)` | Convert generic Query to implementation-specific query |

## RepositoryException

| Member | Type | Description |
|--------|------|-------------|
| `message` | `String` | Error description |
| `code` | `RepositoryErrorCode` | Error type |

Factory constructors:
- `RepositoryException.notFound(String id)`
- `RepositoryException.alreadyExists(String id)`

## RepositoryErrorCode

| Value | Description |
|-------|-------------|
| `notFound` | Item does not exist |
| `alreadyExists` | ID already in use |
| `unknown` | Other error |
