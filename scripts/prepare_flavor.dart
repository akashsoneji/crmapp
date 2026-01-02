import 'dart:io';

/// Prepares client-specific assets for Flutter build
/// Usage: dart run scripts/prepare_flavor.dart {flavor}
/// Example: dart run scripts/prepare_flavor.dart afx
void main(List<String> args) async {
  if (args.isEmpty) {
    print('❌ Error: Please specify a flavor');
    print('Usage: dart run scripts/prepare_flavor.dart {flavor}');
    print('Example: dart run scripts/prepare_flavor.dart afx');
    exit(1);
  }

  final flavor = args[0];
  print('🚀 Preparing $flavor flavor...\n');

  try {
    // Step 1: Copy client assets to Flutter assets folder
    await copyClientAssets(flavor);

    // Step 2: Update pubspec.yaml to include client assets
    await updatePubspec(flavor);

    // Step 3: Generate native splash resources
    await generateNativeSplash(flavor);

    // Step 4: Generate launcher icons
    await generateLauncherIcons(flavor);

    print('\n✅ Successfully prepared $flavor flavor!');
    print(
      '📦 You can now build with: flutter build apk --flavor $flavor -t lib/main_$flavor.dart',
    );
  } catch (e) {
    print('\n❌ Error preparing flavor: $e');
    exit(1);
  }
}

/// Copy client assets from clients/{flavor}/assets to assets/clients/{flavor}
Future<void> copyClientAssets(String flavor) async {
  print('📂 Copying client assets...');

  final sourceDir = Directory('lib/clients/$flavor/assets');
  final targetDir = Directory('assets/clients/$flavor');

  if (!await sourceDir.exists()) {
    throw Exception('Client assets directory not found: ${sourceDir.path}');
  }

  // Create target directory
  if (await targetDir.exists()) {
    await targetDir.delete(recursive: true);
  }
  await targetDir.create(recursive: true);

  // Copy all files
  await for (final entity in sourceDir.list(recursive: true)) {
    if (entity is File) {
      final relativePath = entity.path.replaceFirst(sourceDir.path, '');
      final targetPath = '${targetDir.path}$relativePath';
      final targetFile = File(targetPath);

      await targetFile.parent.create(recursive: true);
      await entity.copy(targetPath);
      print('  ✓ Copied: $relativePath');
    }
  }
}

/// Update pubspec.yaml to include client assets
Future<void> updatePubspec(String flavor) async {
  print('\n📝 Updating pubspec.yaml...');

  final pubspecFile = File('pubspec.yaml');
  if (!await pubspecFile.exists()) {
    throw Exception('pubspec.yaml not found');
  }

  var content = await pubspecFile.readAsString();

  // Check if client assets are already included
  final assetPath = '    - assets/clients/$flavor/';
  if (!content.contains(assetPath)) {
    // Find the assets section and add the client assets
    final assetsIndex = content.indexOf('  assets:');
    if (assetsIndex != -1) {
      final insertIndex = content.indexOf('\n', assetsIndex) + 1;
      content =
          content.substring(0, insertIndex) +
          assetPath +
          '\n' +
          content.substring(insertIndex);

      await pubspecFile.writeAsString(content);
      print('  ✓ Added client assets to pubspec.yaml');
    } else {
      print('  ⚠️  Warning: Could not find assets section in pubspec.yaml');
    }
  } else {
    print('  ✓ Client assets already in pubspec.yaml');
  }
}

/// Generate native splash screen resources for Android
Future<void> generateNativeSplash(String flavor) async {
  print('\n🎨 Generating native splash resources...');

  // Read client config to get splash color
  final configFile = File('lib/clients/$flavor/config.dart');
  if (!await configFile.exists()) {
    print('  ⚠️  Warning: Client config not found, skipping splash generation');
    return;
  }

  final configContent = await configFile.readAsString();

  // Extract primary color (simple regex - could be improved)
  final colorMatch = RegExp(
    r'primaryColor:\s*const\s*Color\(0x([A-Fa-f0-9]{8})\)',
  ).firstMatch(configContent);
  if (colorMatch == null) {
    print('  ⚠️  Warning: Could not extract primary color from config');
    return;
  }

  final colorHex =
      '#${colorMatch.group(1)!.substring(2)}'; // Remove alpha channel

  // Create drawable folder if it doesn't exist
  final drawableDir = Directory('android/app/src/$flavor/res/drawable');
  await drawableDir.create(recursive: true);

  final drawableV21Dir = Directory('android/app/src/$flavor/res/drawable-v21');
  await drawableV21Dir.create(recursive: true);

  // Create launch_background.xml
  final launchBackgroundXml = '''<?xml version="1.0" encoding="utf-8"?>
<!-- Modify this file to customize your launch splash screen -->
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/my_splash_color" />

    <!-- You can insert your own image assets here -->
    <!-- <item>
        <bitmap
            android:gravity="center"
            android:src="@mipmap/launch_image" />
    </item> -->
</layer-list>
''';

  await File(
    '${drawableDir.path}/launch_background.xml',
  ).writeAsString(launchBackgroundXml);
  await File(
    '${drawableV21Dir.path}/launch_background.xml',
  ).writeAsString(launchBackgroundXml);

  // Create values folder and colors.xml
  final valuesDir = Directory('android/app/src/$flavor/res/values');
  await valuesDir.create(recursive: true);

  // Extract colors from config
  final primaryColorMatch = RegExp(
    r'primaryColor:\s*const\s*Color\(0x([A-Fa-f0-9]{8})\)',
  ).firstMatch(configContent);
  final secondaryColorMatch = RegExp(
    r'secondaryColor:\s*const\s*Color\(0x([A-Fa-f0-9]{8})\)',
  ).firstMatch(configContent);
  final accentColorMatch = RegExp(
    r'accentColor:\s*const\s*Color\(0x([A-Fa-f0-9]{8})\)',
  ).firstMatch(configContent);

  final primaryColorHex =
      primaryColorMatch != null
          ? '#${primaryColorMatch.group(1)!.substring(2)}'
          : colorHex;
  final secondaryColorHex =
      secondaryColorMatch != null
          ? '#${secondaryColorMatch.group(1)!.substring(2)}'
          : '#FFFFFF';
  final accentColorHex =
      accentColorMatch != null
          ? '#${accentColorMatch.group(1)!.substring(2)}'
          : primaryColorHex;

  // Create colors.xml
  final colorsXml = '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="primary_color">$primaryColorHex</color>
    <color name="secondary_color">$secondaryColorHex</color>
    <color name="accent_color">$accentColorHex</color>
    <color name="my_splash_color">$primaryColorHex</color> <!-- $flavor -->
</resources>
''';

  await File('${valuesDir.path}/colors.xml').writeAsString(colorsXml);

  print('  ✓ Created launch_background.xml');
  print('  ✓ Created colors.xml');
  print('  ✓ Splash color: $colorHex');
}

/// Generate launcher icons using flutter_launcher_icons package
Future<void> generateLauncherIcons(String flavor) async {
  print('\n🎨 Generating launcher icons...');

  // Check if launcher icons config exists
  final configFile = File('lib/clients/$flavor/launcher_icons.yaml');
  if (!await configFile.exists()) {
    print(
      '  ⚠️  Warning: Launcher icons config not found, skipping icon generation',
    );
    return;
  }

  // Run flutter_launcher_icons command
  print('  ⏳ Running dart run flutter_launcher_icons...');
  final result = await Process.run('dart', [
    'run',
    'flutter_launcher_icons',
    '-f',
    'lib/clients/$flavor/launcher_icons.yaml',
  ], workingDirectory: Directory.current.path);

  if (result.exitCode == 0) {
    print('  ✓ Launcher icons generated successfully');
  } else {
    print('  ⚠️  Warning: Launcher icon generation failed');
    print('  Error: ${result.stderr}');
  }
}
