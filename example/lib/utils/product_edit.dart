import 'package:example/models/product_model.dart';

/// The outcome of validating the product edit dialog input.
///
/// Exactly one field is set. `price` holds the parsed price when the input is
/// valid. `error` holds the message to show the user when it is not.
typedef ProductEditValidation = ({double? price, String? error});

/// Validates the name and price that the product edit dialog collected.
///
/// The price is parsed once, so the caller does not parse it again.
ProductEditValidation validateProductEdit({
  required String name,
  required String priceText,
}) {
  if (name.isEmpty || priceText.isEmpty) {
    return (price: null, error: 'Name and price are required');
  }

  final price = double.tryParse(priceText);
  if (price == null || price < 0) {
    return (price: null, error: 'Please enter a valid price');
  }

  return (price: price, error: null);
}

/// True when the edited values change at least one field of [product].
bool productEditChangesProduct(
  ProductModel product, {
  required String name,
  required double price,
  required String description,
}) {
  return name != product.name ||
      price != product.price ||
      description != product.description;
}
