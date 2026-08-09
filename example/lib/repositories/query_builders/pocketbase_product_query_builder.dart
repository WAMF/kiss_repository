import 'package:example/queries/product_queries.dart';
import 'package:kiss_repository/kiss_repository.dart';
// ignore: depend_on_referenced_packages
import 'package:pocketbase/pocketbase.dart';

/// Builds PocketBase filter strings for the example's [Query] types.
///
/// Values are bound through [PocketBase.filter] placeholders (`{:name}`)
/// instead of being interpolated into the filter string. `filter` escapes a
/// single quote inside a value, so a value cannot close the quoted literal and
/// append filter syntax of its own.
///
/// Copy this pattern, not string interpolation, when you write a query builder
/// for a collection of your own. A search term usually comes from a user.
class PocketBaseProductQueryBuilder implements QueryBuilder<String> {
  PocketBaseProductQueryBuilder(this._client);

  final PocketBase _client;

  @override
  String build(Query query) {
    if (query is QueryByName) {
      return _client.filter(
        'name ~ {:searchTerm}',
        <String, dynamic>{'searchTerm': query.searchTerm},
      );
    }

    if (query is QueryByPriceGreaterThan) {
      return _client.filter(
        'price > {:threshold}',
        <String, dynamic>{'threshold': query.threshold},
      );
    }

    if (query is QueryByPriceLessThan) {
      return _client.filter(
        'price < {:threshold}',
        <String, dynamic>{'threshold': query.threshold},
      );
    }

    // The date is passed as a pre-formatted string so the emitted format stays
    // the same as before this builder was parameterized. Passing a `DateTime`
    // would make `filter` emit a space instead of the `T` separator.
    if (query is QueryByCreatedAfter) {
      return _client.filter(
        'created > {:date}',
        <String, dynamic>{'date': query.dateTime.toIso8601String()},
      );
    }

    if (query is QueryByCreatedBefore) {
      return _client.filter(
        'created < {:date}',
        <String, dynamic>{'date': query.dateTime.toIso8601String()},
      );
    }

    // Default: return all products
    return '';
  }
}
