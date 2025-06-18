class ProductModel {
  final String id;
  final String name;
  final double price;
  final String description;
  final DateTime created;

  const ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.created,
  });

  /// Create a new ProductModel without an ID (for adding to repository)
  ProductModel.create({
    required this.name,
    required this.price,
    this.description = '',
  })  : id = '',
        created = DateTime.now();

  ProductModel copyWith({
    String? id,
    String? name,
    double? price,
    String? description,
    DateTime? created,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      created: created ?? this.created,
    );
  }

  @override
  String toString() => 'ProductModel(id: $id, name: $name, price: $price, description: $description, created: $created)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductModel &&
        other.id == id &&
        other.name == name &&
        other.price == price &&
        other.description == description &&
        other.created == created;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ price.hashCode ^ description.hashCode ^ created.hashCode;
  }
}
