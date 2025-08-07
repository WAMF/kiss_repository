import 'package:kiss_repository/src/in_memory_repository.dart';
import 'package:kiss_repository/src/repository.dart';

import 'shared_repository_tests.dart';

class TestQueryBuilder extends QueryBuilder<InMemoryFilterQuery<TestObject>> {
  @override
  InMemoryFilterQuery<TestObject> build(Query query) {
    if (query is AllQuery) {
      return InMemoryFilterQuery<TestObject>((item) => true);
    }
    throw UnimplementedError('Query type not supported: $query');
  }
}

void main() {
  runRepositoryTests(
    'InMemoryRepository',
    () => InMemoryRepository<TestObject>(
      queryBuilder: TestQueryBuilder(),
      path: 'test_objects',
    ),
    null,
  );
}
