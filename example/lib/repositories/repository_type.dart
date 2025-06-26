enum RepositoryType {
  inMemory('In-Memory'),
  firebase('Firebase'),
  pocketbase('PocketBase'),
  drift('Drift (SQLite)');

  const RepositoryType(this.displayName);
  final String displayName;
}
