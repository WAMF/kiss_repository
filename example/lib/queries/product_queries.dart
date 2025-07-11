import 'package:kiss_repository/kiss_repository.dart';
import 'package:meta/meta.dart';

@immutable
class QueryByName extends Query {
  const QueryByName(this.searchTerm);
  final String searchTerm;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueryByName &&
          runtimeType == other.runtimeType &&
          searchTerm == other.searchTerm;

  @override
  int get hashCode => searchTerm.hashCode;

  @override
  String toString() => 'QueryByName(searchTerm: $searchTerm)';
}

@immutable
class QueryByPriceGreaterThan extends Query {
  const QueryByPriceGreaterThan(this.threshold);
  final double threshold;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueryByPriceGreaterThan &&
          runtimeType == other.runtimeType &&
          threshold == other.threshold;

  @override
  int get hashCode => threshold.hashCode;

  @override
  String toString() => 'QueryByPriceGreaterThan(threshold: $threshold)';
}

@immutable
class QueryByPriceLessThan extends Query {
  const QueryByPriceLessThan(this.threshold);
  final double threshold;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueryByPriceLessThan &&
          runtimeType == other.runtimeType &&
          threshold == other.threshold;

  @override
  int get hashCode => threshold.hashCode;

  @override
  String toString() => 'QueryByPriceLessThan(threshold: $threshold)';
}

@immutable
class QueryByCreatedAfter extends Query {
  const QueryByCreatedAfter(this.dateTime);
  final DateTime dateTime;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueryByCreatedAfter &&
          runtimeType == other.runtimeType &&
          dateTime == other.dateTime;

  @override
  int get hashCode => dateTime.hashCode;

  @override
  String toString() => 'QueryByCreatedAfter(dateTime: $dateTime)';
}

@immutable
class QueryByCreatedBefore extends Query {
  const QueryByCreatedBefore(this.dateTime);
  final DateTime dateTime;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueryByCreatedBefore &&
          runtimeType == other.runtimeType &&
          dateTime == other.dateTime;

  @override
  int get hashCode => dateTime.hashCode;

  @override
  String toString() => 'QueryByCreatedBefore(dateTime: $dateTime)';
}
