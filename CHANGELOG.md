## 0.16.0

- **BREAKING**: JsonFileRepository now generates UUID v4 format IDs instead of sequential numbers
- Fixed thread-safety and persistence issues with ID generation in JsonFileRepository
- Added uuid package dependency for reliable unique ID generation
- Improved test isolation by using temporary directories instead of fixed file paths
- Applied performance optimizations to test files with const constructors

## 0.15.0

- **BREAKING**: Removed `initialItems` parameter from JsonFileRepository constructor
- Simplified JsonFileRepository by removing unnecessary initialization complexity

## 0.14.0

- Added JsonFileRepository implementation for persistent storage
- JsonFileRepository saves data to JSON files and survives application restarts
- Reuses InMemoryFilterQuery for consistent filtering behavior
- Added comprehensive test suite for both InMemoryRepository and JsonFileRepository
- Added tests for batch operations with 50+ items to ensure scalability

## 0.13.0

- Added support for initial items in InMemoryRepository constructor
- Repository can now be initialized with pre-populated data

## 0.12.0

- fixed silent error when not found on deletion
- cleaned code with linter
- added doc comments

## 0.11.0

- Added comprehensive integration tests for InMemoryRepository using factory pattern
- Extracted shared test logic to dedicated [kiss_repository_tests](https://github.com/WAMF/kiss_repository_tests) package

## 0.10.0

- Throw exception when getting item with non existent ID
- Don't throw an error when trying to delete non existent item

## 0.9.0

- Update interface to include auto ID generation - but do not implement any specific ID generation
- Fix typo in inteface name for IdentifiedObject

## 0.8.1

- Update documentation

## 0.8.0

- Added in memory reference implementation, added a dispose method to the interface
- Update interface to make ID generation explicitly an external task thats out of scope of this interface.

## 0.7.0

- added `addWithId` to add an item with a specific id.

## 0.6.0

- corrected `deleteAll` to return `void`.

## 0.5.0

- Initial version.

