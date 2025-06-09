enum RepositoryType {
  inMemory('In-Memory'),
  firebase('Firebase'),
  pocketbase('PocketBase');

  const RepositoryType(this.displayName);
  final String displayName;
}
