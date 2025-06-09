import 'package:kiss_repository/kiss_repository.dart';

class QueryByName extends Query {
  final String namePrefix;
  const QueryByName(this.namePrefix);
}

class QueryByCreatedAfter extends Query {
  final DateTime date;
  const QueryByCreatedAfter(this.date);
}

class QueryByCreatedBefore extends Query {
  final DateTime date;
  const QueryByCreatedBefore(this.date);
}

class QueryByExpiresAfter extends Query {
  final DateTime date;
  const QueryByExpiresAfter(this.date);
}

class QueryByExpiresBefore extends Query {
  final DateTime date;
  const QueryByExpiresBefore(this.date);
}

class TestObjectQueryBuilder implements QueryBuilder<String> {
  @override
  String build(Query query) {
    if (query is QueryByName) {
      return 'name ~ "${query.namePrefix}"';
    }

    if (query is QueryByCreatedAfter) {
      return 'created >= "${query.date.toIso8601String()}"';
    }

    if (query is QueryByCreatedBefore) {
      return 'created <= "${query.date.toIso8601String()}"';
    }

    if (query is QueryByExpiresAfter) {
      return 'expires >= "${query.date.toIso8601String()}"';
    }

    if (query is QueryByExpiresBefore) {
      return 'expires <= "${query.date.toIso8601String()}"';
    }

    return '';
  }
}
