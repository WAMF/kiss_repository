import 'package:example/models/product_model.dart';
import 'package:example/utils/product_edit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final product = ProductModel(
    id: 'p1',
    name: 'Widget',
    price: 9.5,
    description: 'A widget',
    created: DateTime(2026, 8, 9),
  );

  group('validateProductEdit', () {
    test('accepts a valid name and price and returns the parsed price', () {
      final result = validateProductEdit(name: 'Widget', priceText: '12.75');
      expect(result.error, isNull);
      expect(result.price, 12.75);
    });

    test('accepts a price of zero', () {
      final result = validateProductEdit(name: 'Widget', priceText: '0');
      expect(result.error, isNull);
      expect(result.price, 0);
    });

    test('rejects an empty name', () {
      final result = validateProductEdit(name: '', priceText: '12.75');
      expect(result.error, 'Name and price are required');
      expect(result.price, isNull);
    });

    test('rejects an empty price', () {
      final result = validateProductEdit(name: 'Widget', priceText: '');
      expect(result.error, 'Name and price are required');
      expect(result.price, isNull);
    });

    test('reports the missing-field error before the invalid-price error', () {
      // Both fields are wrong. The first message must win, as it did before.
      final result = validateProductEdit(name: '', priceText: 'abc');
      expect(result.error, 'Name and price are required');
    });

    test('rejects a price that is not a number', () {
      final result = validateProductEdit(name: 'Widget', priceText: 'abc');
      expect(result.error, 'Please enter a valid price');
      expect(result.price, isNull);
    });

    test('rejects a negative price', () {
      final result = validateProductEdit(name: 'Widget', priceText: '-1');
      expect(result.error, 'Please enter a valid price');
      expect(result.price, isNull);
    });
  });

  group('productEditChangesProduct', () {
    test('is false when nothing changed', () {
      expect(
        productEditChangesProduct(
          product,
          name: 'Widget',
          price: 9.5,
          description: 'A widget',
        ),
        isFalse,
      );
    });

    test('is true when only the name changed', () {
      expect(
        productEditChangesProduct(
          product,
          name: 'Gadget',
          price: 9.5,
          description: 'A widget',
        ),
        isTrue,
      );
    });

    test('is true when only the price changed', () {
      expect(
        productEditChangesProduct(
          product,
          name: 'Widget',
          price: 9.75,
          description: 'A widget',
        ),
        isTrue,
      );
    });

    test('is true when only the description changed', () {
      expect(
        productEditChangesProduct(
          product,
          name: 'Widget',
          price: 9.5,
          description: 'Another widget',
        ),
        isTrue,
      );
    });

    test('is true when the description is cleared', () {
      expect(
        productEditChangesProduct(
          product,
          name: 'Widget',
          price: 9.5,
          description: '',
        ),
        isTrue,
      );
    });
  });
}
