import 'dart:io';

import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

final _separator = Platform.pathSeparator;

/// Returns [path] expressed relative to the directory [from].
String _relativePath(String path, String from) {
  if (!path.startsWith(from)) return path;
  var rest = path.substring(from.length);
  while (rest.startsWith(_separator)) {
    rest = rest.substring(1);
  }
  return rest;
}

/// Returns every checked-in `pubspec.yaml` under [root].
///
/// Generated and cached directories are skipped, so only the pubspec files
/// of this package and its example app are returned.
List<String> _findPubspecs(Directory root) {
  const skipped = {'.git', '.dart_tool', 'build', '.symlinks', 'Pods'};
  final found = <String>[];
  for (final entity in root.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    if (entity.uri.pathSegments.last != 'pubspec.yaml') continue;
    final relative = _relativePath(entity.path, root.path);
    if (relative.split(_separator).any(skipped.contains)) continue;
    found.add(relative);
  }
  return found;
}

/// Whether a hosted version constraint declares an upper bound.
///
/// A caret constraint (`^1.2.3`) always implies an upper bound. Any other
/// constraint needs an explicit `<` to be bounded. `any` and an empty
/// constraint are therefore unbounded.
bool _isBounded(String constraint) {
  final value = constraint.trim();
  if (value.isEmpty || value == 'any') return false;
  if (value.startsWith('^')) return true;
  return value.contains('<');
}

/// Describes each hosted dependency in [pubspecPath] with no upper bound.
///
/// Entries described by a map (`sdk:`, `path:`, `git:`) are not hosted
/// version constraints, so they are skipped.
List<String> _unboundedIn(String pubspecPath) {
  final document = loadYaml(File(pubspecPath).readAsStringSync());
  if (document is! YamlMap) return const [];

  final offenders = <String>[];
  for (final section in ['dependencies', 'dev_dependencies']) {
    final entries = document[section];
    if (entries is! YamlMap) continue;
    entries.forEach((name, constraint) {
      if (constraint is YamlMap) return;
      final text = constraint?.toString() ?? '';
      if (_isBounded(text)) return;
      offenders.add('$pubspecPath -> $name: $text');
    });
  }
  return offenders;
}

void main() {
  group('pubspec dependency constraints', () {
    final root = Directory.current;

    test('both checked-in pubspec files are discovered', () {
      final paths = _findPubspecs(root);

      expect(paths, contains('pubspec.yaml'));
      expect(
        paths,
        contains('example${_separator}pubspec.yaml'),
        reason: 'The example app pubspec must be covered by this guard.',
      );
    });

    test('no hosted dependency uses an unbounded version constraint', () {
      final offenders = [
        for (final pubspec in _findPubspecs(root)) ..._unboundedIn(pubspec),
      ];

      expect(
        offenders,
        isEmpty,
        reason: 'An unbounded constraint lets a build resolve a future '
            'major release with breaking changes. Pin each dependency to a '
            'caret range that matches the tested version. Offenders: '
            '${offenders.join(', ')}',
      );
    });

    test('example pins pocketbase to the version the sibling expects', () {
      final pubspec = File('example${_separator}pubspec.yaml');
      final document = loadYaml(pubspec.readAsStringSync()) as YamlMap;
      final dependencies = document['dependencies'] as YamlMap;

      expect(dependencies['pocketbase'], '^0.22.0');
    });

    test('bounded and unbounded constraints are told apart', () {
      expect(_isBounded('^0.22.0'), isTrue);
      expect(_isBounded('>=1.0.0 <2.0.0'), isTrue);
      expect(_isBounded('  ^1.2.3  '), isTrue);

      expect(_isBounded('any'), isFalse);
      expect(_isBounded(''), isFalse);
      expect(_isBounded('>=1.0.0'), isFalse);
    });
  });
}
