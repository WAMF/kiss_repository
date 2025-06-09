abstract class RepositoryInitializer {
  /// Initialize the repository with the given configuration
  Future<void> init(Map<String, dynamic>? config);

  /// Check if the repository is already initialized
  bool get isInitialized;

  /// Get a human-readable status message
  String get statusMessage;
}
