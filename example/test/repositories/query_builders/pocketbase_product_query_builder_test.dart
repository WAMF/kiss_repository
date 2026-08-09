import 'package:example/queries/product_queries.dart';
import 'package:example/repositories/query_builders/pocketbase_product_query_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiss_repository/kiss_repository.dart';
// ignore: depend_on_referenced_packages
import 'package:pocketbase/pocketbase.dart';

void main() {
  // `filter` only formats a string. It makes no request, so no server is
  // needed and this URL is never contacted.
  final client = PocketBase('http://localhost:8090');
  final builder = PocketBaseProductQueryBuilder(client);

  group('PocketBaseProductQueryBuilder', () {
    test('quotes a plain search term', () {
      expect(builder.build(const QueryByName('laptop')), "name ~ 'laptop'");
    });

    test('escapes a single quote in a search term', () {
      // A legitimate value, not an attack. It must survive unchanged in
      // meaning, and it must stay inside one quoted literal.
      expect(
        builder.build(const QueryByName("O'Brien")),
        r"name ~ 'O\'Brien'",
      );
    });

    test('a crafted search term cannot add a filter clause (#25)', () {
      // Before this builder bound its values, the term below closed the quoted
      // literal and appended `|| name != ''`, which matches every record and
      // defeats the intended filter. The escaped quote keeps it one literal.
      const payload = "x' || name != '";
      final filter = builder.build(const QueryByName(payload));

      expect(filter, r"name ~ 'x\' || name != \''");

      // The interpolated builder produced exactly this, which is the breakout.
      expect(filter, isNot("name ~ 'x' || name != ''"));

      // No `||` survives outside a quoted literal.
      expect(_unquotedPart(filter), isNot(contains('||')));
    });

    test('a crafted search term cannot comment out the rest of the filter', () {
      const payload = "x' && 1=1 || '";
      final filter = builder.build(const QueryByName(payload));

      expect(filter, r"name ~ 'x\' && 1=1 || \''");
      expect(_unquotedPart(filter), isNot(contains('&&')));
    });

    test('leaves a numeric threshold unquoted', () {
      expect(
        builder.build(const QueryByPriceGreaterThan(9.99)),
        'price > 9.99',
      );
      expect(builder.build(const QueryByPriceLessThan(20.5)), 'price < 20.5');
    });

    test('keeps the ISO 8601 date format used before parameterization', () {
      final when = DateTime.utc(2026, 8, 8, 12, 30, 45);
      final iso = when.toIso8601String();

      expect(
        builder.build(QueryByCreatedAfter(when)),
        "created > '$iso'",
      );
      expect(
        builder.build(QueryByCreatedBefore(when)),
        "created < '$iso'",
      );
      // The `T` separator must not become a space.
      expect(iso, contains('T'));
    });

    test('returns an empty filter for an unrecognised query', () {
      expect(builder.build(const _UnknownQuery()), isEmpty);
    });
  });
}

/// Returns [filter] with every single-quoted literal removed, so a test can
/// assert that no filter syntax leaked outside a literal.
///
/// An escaped quote (`\'`) does not end a literal.
String _unquotedPart(String filter) {
  final outside = StringBuffer();
  var inLiteral = false;

  for (var i = 0; i < filter.length; i++) {
    final char = filter[i];

    if (char == r'\' && i + 1 < filter.length) {
      i++; // Skip the escaped character.
      continue;
    }

    if (char == "'") {
      inLiteral = !inLiteral;
      continue;
    }

    if (!inLiteral) {
      outside.write(char);
    }
  }

  return outside.toString();
}

class _UnknownQuery extends Query {
  const _UnknownQuery();
}
