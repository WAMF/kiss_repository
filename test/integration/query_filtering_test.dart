import 'package:test/test.dart';
import 'package:kiss_repository/kiss_repository.dart';
import 'package:kiss_pocketbase_repository/kiss_pocketbase_repository.dart';

import 'test_helpers.dart';
import 'test_data.dart';

void main() {
  group('Query & Filtering', () {
    setUpAll(() async {
      await IntegrationTestHelpers.setupIntegrationTests();
    });

    tearDownAll(() async {
      await IntegrationTestHelpers.tearDownIntegrationTests();
    });

    setUp(() async {
      await IntegrationTestHelpers.clearTestCollection();

      // Add test data with delays to control PocketBase auto-generated 'created' timestamps
      final repository = IntegrationTestHelpers.repository;

      // Add items in reverse chronological order (oldest first) with delays
      // so PocketBase 'created' field gets auto-generated in correct sequence

      // Oldest (will be created first)
      final david = TestUser(
        id: PocketBaseUtils.generateId(),
        name: 'David Wilson',
        age: 20,
        created: DateTime.now(), // This will be ignored by PocketBase
      );
      await repository.add(IdentifiedObject(david.id, david));
      await Future.delayed(Duration(milliseconds: 10));

      final alice = TestUser(
        id: PocketBaseUtils.generateId(),
        name: 'Alice Smith',
        age: 25,
        created: DateTime.now(), // This will be ignored by PocketBase
      );
      await repository.add(IdentifiedObject(alice.id, alice));
      await Future.delayed(Duration(milliseconds: 10));

      final bob = TestUser(
        id: PocketBaseUtils.generateId(),
        name: 'Bob Johnson',
        age: 30,
        created: DateTime.now(), // This will be ignored by PocketBase
      );
      await repository.add(IdentifiedObject(bob.id, bob));
      await Future.delayed(Duration(milliseconds: 10));

      final aliceJones = TestUser(
        id: PocketBaseUtils.generateId(),
        name: 'Alice Jones',
        age: 28,
        created: DateTime.now(), // This will be ignored by PocketBase
      );
      await repository.add(IdentifiedObject(aliceJones.id, aliceJones));
      await Future.delayed(Duration(milliseconds: 10));

      // Newest (will be created last)
      final charlie = TestUser(
        id: PocketBaseUtils.generateId(),
        name: 'Charlie Brown',
        age: 35,
        created: DateTime.now(), // This will be ignored by PocketBase
      );
      await repository.add(IdentifiedObject(charlie.id, charlie));
    });

    test('should query all items with AllQuery (default)', () async {
      final repository = IntegrationTestHelpers.repository;
      final allUsers = await repository.query();

      expect(allUsers.length, 5);

      // Should be sorted by creation date descending (newest first)
      // Creation order was: David → Alice Smith → Bob → Alice Jones → Charlie
      // So with -created sorting: Charlie → Alice Jones → Bob → Alice Smith → David
      expect(allUsers[0].name, 'Charlie Brown'); // newest (created last)
      expect(allUsers[1].name, 'Alice Jones');
      expect(allUsers[2].name, 'Bob Johnson');
      expect(allUsers[3].name, 'Alice Smith');
      expect(allUsers[4].name, 'David Wilson'); // oldest (created first)
    });

    test('should return empty list when querying empty collection', () async {
      await IntegrationTestHelpers.clearTestCollection();

      final repository = IntegrationTestHelpers.repository;
      final emptyResults = await repository.query();
      expect(emptyResults, isEmpty);
    });

    test('should query by minimum age', () async {
      final repository = IntegrationTestHelpers.repository;
      final adults = await repository.query(query: QueryByAge(30));

      expect(adults.length, 2);

      // Should find Bob (30) and Charlie (35)
      final names = adults.map((u) => u.name).toSet();
      expect(names, contains('Bob Johnson'));
      expect(names, contains('Charlie Brown'));

      // Verify ages
      for (final user in adults) {
        expect(user.age, greaterThanOrEqualTo(30));
      }
    });

    test('should query by name prefix', () async {
      final repository = IntegrationTestHelpers.repository;
      final aliceUsers = await repository.query(query: QueryByName('Alice'));

      expect(aliceUsers.length, 2);

      final names = aliceUsers.map((u) => u.name).toList();
      expect(names, contains('Alice Smith'));
      expect(names, contains('Alice Jones'));
    });

    test('should query young users by maximum age', () async {
      final repository = IntegrationTestHelpers.repository;
      final youngUsers = await repository.query(query: QueryByMaxAge(27));

      expect(youngUsers.length, 2);

      // Should include Alice Smith (25) and David Wilson (20)
      final names = youngUsers.map((u) => u.name).toSet();
      expect(names, contains('Alice Smith'));
      expect(names, contains('David Wilson'));
      expect(names, isNot(contains('Alice Jones'))); // age 28
      expect(names, isNot(contains('Bob Johnson'))); // age 30
      expect(names, isNot(contains('Charlie Brown'))); // age 35
    });

    test('should handle query with no results', () async {
      final repository = IntegrationTestHelpers.repository;
      final noResults = await repository.query(query: QueryByAge(100));
      expect(noResults, isEmpty);
    });

    test('should query all items when using AllQuery explicitly', () async {
      final repository = IntegrationTestHelpers.repository;
      final allUsers = await repository.query(query: AllQuery());
      expect(allUsers.length, 5);

      final names = allUsers.map((u) => u.name).toSet();
      expect(names, contains('Alice Smith'));
      expect(names, contains('Bob Johnson'));
      expect(names, contains('Charlie Brown'));
      expect(names, contains('David Wilson'));
      expect(names, contains('Alice Jones'));
    });
  });
}
