/// Test object for integration tests
class TestObject {
  final String id;
  final String name;
  final DateTime created;

  const TestObject({required this.id, required this.name, required this.created});

  /// Create a new TestObject without an ID (for adding to repository)
  TestObject.create({required this.name, required this.created}) : id = '';

  /// Create a copy with updated fields
  TestObject copyWith({String? id, String? name, DateTime? created}) {
    return TestObject(id: id ?? this.id, name: name ?? this.name, created: created ?? this.created);
  }

  @override
  String toString() {
    return 'TestObject(id: $id, name: $name, created: $created)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TestObject && other.id == id && other.name == name && other.created == created;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ created.hashCode;
  }
}
