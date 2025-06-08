// /// Shared test data for repository contract tests

// class TestObject {
//   final String id;
//   final String name;

//   TestObject({
//     required this.id,
//     required this.name,
//   });

//   /// Create a TestObject without an ID (for adding to repository)
//   TestObject.create({
//     required this.name,
//   }) : id = '';

//   /// Create a copy with updated fields
//   TestObject copyWith({
//     String? id,
//     String? name,
//   }) {
//     return TestObject(
//       id: id ?? this.id,
//       name: name ?? this.name,
//     );
//   }

//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is TestObject && runtimeType == other.runtimeType && id == other.id && name == other.name;

//   @override
//   int get hashCode => Object.hash(id, name);

//   @override
//   String toString() => 'TestObject(id: $id, name: $name)';
// }
