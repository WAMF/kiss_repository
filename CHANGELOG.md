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

