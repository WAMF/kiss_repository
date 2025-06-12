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

class QueryByPriceGreaterThan extends Query {
  final double price;
  const QueryByPriceGreaterThan(this.price);
}

class QueryByPriceLessThan extends Query {
  final double price;
  const QueryByPriceLessThan(this.price);
}

class ProductModelQueryBuilder implements QueryBuilder<String> {
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

    if (query is QueryByPriceGreaterThan) {
      return 'price > ${query.price}';
    }

    if (query is QueryByPriceLessThan) {
      return 'price < ${query.price}';
    }

    return '';
  }
}
