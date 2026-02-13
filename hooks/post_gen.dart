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
    // Find the project root by looking for pubspec.yaml
    final projectRoot = _findProjectRoot(Directory.current);
    if (projectRoot == null) {
      progress.fail('Could not find project root (no pubspec.yaml found)');
      return;
    }

    // Read the package name from pubspec.yaml
    final packageName = _getPackageName(projectRoot);
    if (packageName == null) {
      progress.fail('Could not read package name from pubspec.yaml');
      return;
    }

    // Find app_page.dart
    final appPageFile = File('${projectRoot.path}/lib/app/view/app_page.dart');
    if (!appPageFile.existsSync()) {
      progress.fail('app_page.dart not found at ${appPageFile.path}');
      return;
    }

    // Calculate the feature's relative path from lib/
    final featurePath = _getFeaturePathFromLib(
      projectRoot: projectRoot,
      outputDir: Directory.current,
      snakeName: snakeName,
    );
    if (featurePath == null) {
      progress.fail('Could not determine feature path relative to lib/');
      return;
    }

    var content = appPageFile.readAsStringSync();

    // Build the import statements
    final cubitImport =
        "import 'package:$packageName/$featurePath/presentation/cubit/cubit.dart';";
    final repoImplImport =
        "import 'package:$packageName/$featurePath/data/repositories/${snakeName}_repository_impl.dart';";

    // Build the BlocProvider entry
    final providerEntry = '''
        BlocProvider(
          create: (context) => ${pascalName}Cubit(
            repository: ${pascalName}RepositoryImpl(),
          ),
        ),''';

    // Check if already registered (avoid duplicates)
    if (content.contains('${pascalName}Cubit')) {
      progress.complete('${pascalName}Cubit already registered in app_page.dart');
      return;
    }

    // Add imports (before the first class declaration)
    content = _addImports(content, [repoImplImport, cubitImport]);

    // Add BlocProvider to the providers list
    content = _addBlocProvider(content, providerEntry);

    // Write the updated file
    appPageFile.writeAsStringSync(content);

    // Run dart format on the file
    await Process.run('dart', ['format', appPageFile.path]);

    progress.complete(
      '${pascalName}Cubit registered in app_page.dart',
    );
  } catch (e) {
    progress.fail('Failed to update app_page.dart: $e');
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
    if (parent.path == dir.path) return null; // reached filesystem root
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

/// Determines the feature's path relative to lib/
/// e.g., if output is lib/features/customer/ and feature is order_mgmt,
/// returns "features/customer/order_mgmt"
String? _getFeaturePathFromLib({
  required Directory projectRoot,
  required Directory outputDir,
  required String snakeName,
}) {
  final libPath = '${projectRoot.path}/lib';
  // The feature will be generated at outputDir/snakeName/
  final featureAbsPath = '${outputDir.path}/$snakeName';

  if (!featureAbsPath.startsWith(libPath)) {
    // Output is outside lib/ — try to resolve anyway
    return null;
  }

  // Strip the lib/ prefix to get the relative path
  return featureAbsPath.substring(libPath.length + 1); // +1 for the /
}

/// Inserts import statements before the first class declaration
String _addImports(String content, List<String> imports) {
  // Find the last existing import line
  final lines = content.split('\n');
  var lastImportIndex = -1;

  for (var i = 0; i < lines.length; i++) {
    if (lines[i].trimLeft().startsWith('import ')) {
      lastImportIndex = i;
    }
  }

  if (lastImportIndex == -1) {
    // No imports found, add at the top
    return '${imports.join('\n')}\n$content';
  }

  // Insert after the last import
  for (final imp in imports) {
    lines.insert(lastImportIndex + 1, imp);
    lastImportIndex++;
  }

  return lines.join('\n');
}

/// Inserts a BlocProvider entry into the MultiBlocProvider's providers list
String _addBlocProvider(String content, String providerEntry) {
  // Find the closing of the providers list: "],\n      child:"
  // We insert the new provider just before the closing ]
  final providersClosePattern = RegExp(r'(\s*)\],\s*\n(\s*)child:');
  final match = providersClosePattern.firstMatch(content);

  if (match != null) {
    final insertPoint = match.start;
    return '${content.substring(0, insertPoint)}\n$providerEntry\n${content.substring(insertPoint)}';
  }

  // Fallback: try to find just "], child:" on similar lines
  final fallbackPattern = RegExp(r'\],\s*child:');
  final fallbackMatch = fallbackPattern.firstMatch(content);

  if (fallbackMatch != null) {
    final insertPoint = fallbackMatch.start;
    return '${content.substring(0, insertPoint)}\n$providerEntry\n${content.substring(insertPoint)}';
  }

  return content;
}
