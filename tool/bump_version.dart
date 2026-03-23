import 'dart:io';

final _pubspecVersionPattern = RegExp(
  r'^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$',
  multiLine: true,
);

void main(List<String> rawArgs) {
  final args = List<String>.from(rawArgs);
  final dryRun = args.remove('--dry-run');

  if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
    _printUsage();
    exit(args.isEmpty ? 1 : 0);
  }

  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    stderr.writeln('Could not find pubspec.yaml in ${Directory.current.path}.');
    exit(1);
  }

  final contents = pubspec.readAsStringSync();
  final match = _pubspecVersionPattern.firstMatch(contents);
  if (match == null) {
    stderr.writeln(
      'Expected a pubspec version like "version: 1.2.3+4", but none was found.',
    );
    exit(1);
  }

  final current = _Version(
    major: int.parse(match.group(1)!),
    minor: int.parse(match.group(2)!),
    patch: int.parse(match.group(3)!),
    build: int.parse(match.group(4)!),
  );

  final command = args.first;
  late final _Version next;

  switch (command) {
    case 'show':
      stdout.writeln(current.pubspecValue);
      return;
    case 'build':
      _assertArgsLength(args, 1);
      next = current.copyWith(build: current.build + 1);
      break;
    case 'patch':
      _assertArgsLength(args, 1);
      next = current.copyWith(
        patch: current.patch + 1,
        build: current.build + 1,
      );
      break;
    case 'minor':
      _assertArgsLength(args, 1);
      next = current.copyWith(
        minor: current.minor + 1,
        patch: 0,
        build: current.build + 1,
      );
      break;
    case 'major':
      _assertArgsLength(args, 1);
      next = current.copyWith(
        major: current.major + 1,
        minor: 0,
        patch: 0,
        build: current.build + 1,
      );
      break;
    case 'set':
      _assertArgsLength(args, 2);
      next = _parseExplicitVersion(args[1], fallbackBuild: current.build + 1);
      break;
    default:
      stderr.writeln('Unknown command "$command".');
      _printUsage();
      exit(1);
  }

  final replacement = 'version: ${next.pubspecValue}';
  final updatedContents = contents.replaceFirst(
    _pubspecVersionPattern,
    replacement,
  );

  stdout.writeln(
    dryRun
        ? 'Dry run: ${current.pubspecValue} -> ${next.pubspecValue}'
        : 'Updated pubspec version: ${current.pubspecValue} -> ${next.pubspecValue}',
  );
  stdout.writeln('iOS CFBundleShortVersionString: ${next.releaseValue}');
  stdout.writeln('iOS CFBundleVersion / Android versionCode: ${next.build}');

  if (!dryRun) {
    pubspec.writeAsStringSync(updatedContents);
  }
}

_Version _parseExplicitVersion(String input, {required int fallbackBuild}) {
  final match = RegExp(r'^(\d+)\.(\d+)\.(\d+)(?:\+(\d+))?$').firstMatch(input);
  if (match == null) {
    stderr.writeln(
      'Expected VERSION to look like 1.2.3 or 1.2.3+45, but received "$input".',
    );
    exit(1);
  }

  return _Version(
    major: int.parse(match.group(1)!),
    minor: int.parse(match.group(2)!),
    patch: int.parse(match.group(3)!),
    build: match.group(4) == null ? fallbackBuild : int.parse(match.group(4)!),
  );
}

void _assertArgsLength(List<String> args, int expectedLength) {
  if (args.length == expectedLength) {
    return;
  }

  _printUsage();
  exit(1);
}

void _printUsage() {
  stdout.writeln(
    'Usage: dart run tool/bump_version.dart <command> [value] [--dry-run]',
  );
  stdout.writeln('');
  stdout.writeln('Commands:');
  stdout.writeln('  show            Print the current pubspec version.');
  stdout.writeln('  build           Increment only the build number.');
  stdout.writeln('  patch           Increment patch and build numbers.');
  stdout.writeln('  minor           Increment minor and build numbers.');
  stdout.writeln('  major           Increment major and build numbers.');
  stdout.writeln(
    '  set VERSION     Set an explicit version like 1.2.3 or 1.2.3+45.',
  );
}

class _Version {
  const _Version({
    required this.major,
    required this.minor,
    required this.patch,
    required this.build,
  });

  final int major;
  final int minor;
  final int patch;
  final int build;

  String get releaseValue => '$major.$minor.$patch';
  String get pubspecValue => '$releaseValue+$build';

  _Version copyWith({int? major, int? minor, int? patch, int? build}) {
    return _Version(
      major: major ?? this.major,
      minor: minor ?? this.minor,
      patch: patch ?? this.patch,
      build: build ?? this.build,
    );
  }
}
