class TestObject {
  final String id;
  final String name;
  final DateTime created;
  final DateTime expires;

  const TestObject({required this.id, required this.name, required this.created, required this.expires});

  /// Create a new TestObject without an ID (for adding to repository)
  TestObject.create({required this.name, DateTime? expires})
      : id = '',
        created = DateTime.now(),
        expires = expires ?? DateTime.now().add(Duration(days: 30));

  TestObject copyWith({String? id, String? name, DateTime? created, DateTime? expires}) {
    return TestObject(
      id: id ?? this.id,
      name: name ?? this.name,
      created: created ?? this.created,
      expires: expires ?? this.expires,
    );
  }

  @override
  String toString() {
    return 'TestObject(id: $id, name: $name, created: $created, expires: $expires)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TestObject &&
        other.id == id &&
        other.name == name &&
        other.created == created &&
        other.expires == expires;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ created.hashCode ^ expires.hashCode;
  }
}
