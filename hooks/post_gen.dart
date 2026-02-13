import 'dart:io';
import 'package:mason/mason.dart';

Future<void> run(HookContext context) async {
  final featureName = (context.vars['feature_name'] as String);
  final snakeName = featureName.snakeCase;
  final pascalName = featureName.pascalCase;

  final progress = context.logger.progress(
    'Registering ${pascalName}Cubit in app_page.dart',
  );

  try {
    // In mason hooks, Directory.current is the --output-dir target
    // (the directory where files are being generated into).
    // We need to find the project root by walking up to find pubspec.yaml.
    final outputDir = Directory.current;

    context.logger.info('Hook working directory: ${outputDir.path}');

    // Find the project root by looking for pubspec.yaml
    final projectRoot = _findProjectRoot(outputDir);
    if (projectRoot == null) {
      progress.fail('Could not find project root (no pubspec.yaml found)');
      return;
    }

    context.logger.info('Project root: ${projectRoot.path}');

    // Read the package name from pubspec.yaml
    final packageName = _getPackageName(projectRoot);
    if (packageName == null) {
      progress.fail('Could not read package name from pubspec.yaml');
      return;
    }

    context.logger.info('Package name: $packageName');

    // Find app_page.dart
    final appPageFile = File('${projectRoot.path}/lib/app/view/app_page.dart');
    if (!appPageFile.existsSync()) {
      progress.fail('app_page.dart not found at ${appPageFile.path}');
      return;
    }

    // Calculate the feature's relative path from lib/
    final libPath = '${projectRoot.path}/lib';
    final featureAbsPath = '${outputDir.path}/$snakeName';

    context.logger.info('Feature abs path: $featureAbsPath');
    context.logger.info('Lib path: $libPath');

    // The output dir might be the project root if mason is run from there,
    // or it could be the actual output-dir. We need to figure out the
    // correct path. Let's search for the generated cubit file to confirm.
    String? featurePath;

    // First, try direct calculation from outputDir
    if (featureAbsPath.startsWith(libPath)) {
      featurePath = featureAbsPath.substring(libPath.length + 1);
    }

    // If that didn't work, search for the generated file
    if (featurePath == null) {
      final foundPath = _findGeneratedFeature(projectRoot, snakeName);
      if (foundPath != null) {
        featurePath = foundPath;
      }
    }

    if (featurePath == null) {
      progress.fail(
        'Could not determine feature path relative to lib/. '
        'Output dir: ${outputDir.path}, Feature: $snakeName',
      );
      return;
    }

    context.logger.info('Feature path from lib: $featurePath');

    var content = appPageFile.readAsStringSync();

    // Build the import statements
    final cubitImport =
        "import 'package:$packageName/$featurePath/presentation/cubit/cubit.dart';";
    final repoImplImport =
        "import 'package:$packageName/$featurePath/data/repositories/${snakeName}_repository_impl.dart';";

    // Build the BlocProvider entry
    final providerEntry =
        '        BlocProvider(\n'
        '          create: (context) => ${pascalName}Cubit(\n'
        '            repository: ${pascalName}RepositoryImpl(),\n'
        '          ),\n'
        '        ),';

    // Check if already registered (avoid duplicates)
    if (content.contains('${pascalName}Cubit')) {
      progress.complete(
        '${pascalName}Cubit already registered in app_page.dart',
      );
      return;
    }

    // Add imports (after the last existing import)
    content = _addImports(content, [repoImplImport, cubitImport]);

    // Add BlocProvider to the providers list (before the closing ])
    content = _addBlocProvider(content, providerEntry);

    // Write the updated file
    appPageFile.writeAsStringSync(content);

    // Run dart format on the file
    await Process.run('dart', ['format', appPageFile.path]);

    progress.complete('${pascalName}Cubit registered in app_page.dart');
  } catch (e, stackTrace) {
    progress.fail('Failed to update app_page.dart: $e');
    context.logger.err(stackTrace.toString());
  }
}

/// Walks up the directory tree to find the project root (contains pubspec.yaml)
Directory? _findProjectRoot(Directory start) {
  var dir = start;
  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) return null;
    dir = parent;
  }
}

/// Reads the package name from pubspec.yaml
String? _getPackageName(Directory projectRoot) {
  final pubspec = File('${projectRoot.path}/pubspec.yaml');
  if (!pubspec.existsSync()) return null;

  final lines = pubspec.readAsLinesSync();
  for (final line in lines) {
    final match = RegExp(r'^name:\s*(.+)$').firstMatch(line.trim());
    if (match != null) {
      return match.group(1)!.trim();
    }
  }
  return null;
}

/// Searches for the generated feature directory under lib/
/// Returns the path relative to lib/ (e.g., "features/customer/order_management")
String? _findGeneratedFeature(Directory projectRoot, String snakeName) {
  final libDir = Directory('${projectRoot.path}/lib');
  if (!libDir.existsSync()) return null;

  // Recursively search for a directory named snakeName that contains
  // the expected cubit file
  return _searchForFeature(libDir, snakeName, libDir.path);
}

String? _searchForFeature(Directory dir, String snakeName, String libPath) {
  try {
    for (final entity in dir.listSync()) {
      if (entity is Directory) {
        final dirName = entity.path.split(Platform.pathSeparator).last;
        if (dirName == snakeName) {
          // Verify it's our generated feature by checking for cubit.dart
          final cubitFile = File('${entity.path}/presentation/cubit/cubit.dart');
          if (cubitFile.existsSync()) {
            return entity.path.substring(libPath.length + 1);
          }
        }
        // Keep searching subdirectories
        final result = _searchForFeature(entity, snakeName, libPath);
        if (result != null) return result;
      }
    }
  } catch (_) {
    // Permission errors, etc.
  }
  return null;
}

/// Inserts import statements after the last existing import
String _addImports(String content, List<String> imports) {
  final lines = content.split('\n');
  var lastImportIndex = -1;

  for (var i = 0; i < lines.length; i++) {
    if (lines[i].trimLeft().startsWith('import ')) {
      lastImportIndex = i;
    }
  }

  if (lastImportIndex == -1) {
    return '${imports.join('\n')}\n$content';
  }

  for (final imp in imports) {
    lines.insert(lastImportIndex + 1, imp);
    lastImportIndex++;
  }

  return lines.join('\n');
}

/// Inserts a BlocProvider entry into the MultiBlocProvider's providers list.
/// Finds the `],` that closes the providers list and inserts before it.
String _addBlocProvider(String content, String providerEntry) {
  // Strategy: find the `providers: [` line, then find its matching `],`
  // and insert before it.

  final lines = content.split('\n');
  var providersStartIndex = -1;
  var bracketDepth = 0;
  var closingBracketIndex = -1;

  // Find the "providers: [" line
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].contains('providers:') && lines[i].contains('[')) {
      providersStartIndex = i;
      break;
    }
  }

  if (providersStartIndex == -1) return content;

  // Count brackets to find the matching ]
  for (var i = providersStartIndex; i < lines.length; i++) {
    for (final char in lines[i].runes) {
      if (char == '['.runes.first) bracketDepth++;
      if (char == ']'.runes.first) {
        bracketDepth--;
        if (bracketDepth == 0) {
          closingBracketIndex = i;
          break;
        }
      }
    }
    if (closingBracketIndex != -1) break;
  }

  if (closingBracketIndex == -1) return content;

  // Insert the provider entry before the closing ]
  final providerLines = providerEntry.split('\n');
  for (var i = providerLines.length - 1; i >= 0; i--) {
    lines.insert(closingBracketIndex, providerLines[i]);
  }

  return lines.join('\n');
}
