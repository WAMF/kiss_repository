import 'package:kiss_repository/kiss_repository.dart';

class QueryByName extends Query {
  final String searchTerm;

  const QueryByName(this.searchTerm);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueryByName && runtimeType == other.runtimeType && searchTerm == other.searchTerm;

  @override
  int get hashCode => searchTerm.hashCode;

  @override
  String toString() => 'QueryByName(searchTerm: $searchTerm)';
}

class QueryByPriceGreaterThan extends Query {
  final double threshold;

  const QueryByPriceGreaterThan(this.threshold);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueryByPriceGreaterThan && runtimeType == other.runtimeType && threshold == other.threshold;

  @override
  int get hashCode => threshold.hashCode;

  @override
  String toString() => 'QueryByPriceGreaterThan(threshold: $threshold)';
}

class QueryByPriceLessThan extends Query {
  final double threshold;

  const QueryByPriceLessThan(this.threshold);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueryByPriceLessThan && runtimeType == other.runtimeType && threshold == other.threshold;

  @override
  int get hashCode => threshold.hashCode;

  @override
  String toString() => 'QueryByPriceLessThan(threshold: $threshold)';
}

class QueryByCreatedAfter extends Query {
  final DateTime dateTime;

  const QueryByCreatedAfter(this.dateTime);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueryByCreatedAfter && runtimeType == other.runtimeType && dateTime == other.dateTime;

  @override
  int get hashCode => dateTime.hashCode;

  @override
  String toString() => 'QueryByCreatedAfter(dateTime: $dateTime)';
}

class QueryByCreatedBefore extends Query {
  final DateTime dateTime;

  const QueryByCreatedBefore(this.dateTime);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueryByCreatedBefore && runtimeType == other.runtimeType && dateTime == other.dateTime;

  @override
  int get hashCode => dateTime.hashCode;

  @override
  String toString() => 'QueryByCreatedBefore(dateTime: $dateTime)';
}
