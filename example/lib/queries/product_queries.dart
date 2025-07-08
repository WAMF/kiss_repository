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

class QueryByPriceRange extends Query {
  final double? minPrice;
  final double? maxPrice;

  const QueryByPriceRange({this.minPrice, this.maxPrice});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueryByPriceRange &&
          runtimeType == other.runtimeType &&
          minPrice == other.minPrice &&
          maxPrice == other.maxPrice;

  @override
  int get hashCode => minPrice.hashCode ^ maxPrice.hashCode;

  @override
  String toString() => 'QueryByPriceRange(minPrice: $minPrice, maxPrice: $maxPrice)';
}
