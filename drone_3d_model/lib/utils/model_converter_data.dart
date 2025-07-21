import 'dart:io';
import 'package:path/path.dart' as p;

class ModelConverter {
  static Future<String> convertObjToGltf(String objFilePath, String outputDir) async {
    final String glbFileName = '${p.basenameWithoutExtension(objFilePath)}.glb';
    final String outputGlbPath = p.join(outputDir, glbFileName);

    // Check if obj2gltf is available
    ProcessResult checkResult;
    try {
      checkResult = await Process.run('obj2gltf', ['--version'], runInShell: true);
      if (checkResult.exitCode != 0) {
        throw Exception('obj2gltf command not found or not working. Please ensure it\'s installed and in your system PATH.');
      }
      print('obj2gltf version: ${checkResult.stdout.trim()}');
    } catch (e) {
      print('Error checking obj2gltf: $e');
      rethrow; // Re-throw to propagate the error
    }

    try {
      print('Converting $objFilePath to GLB...');
      // obj2gltf takes --input and --output arguments
      final ProcessResult result = await Process.run(
        'obj2gltf',
        [
          '--input',
          objFilePath,
          '--output',
          outputGlbPath,
          '--binary', // Output GLB binary format
          '--separate', // Keep textures separate (or remove if you want them embedded)
          '--metallicRoughness' // Common PBR material conversion
        ],
        runInShell: true, // Crucial for Windows to find obj2gltf
      );

      if (result.exitCode == 0) {
        print('Conversion successful: $outputGlbPath');
        print('obj2gltf Stdout: ${result.stdout}');
        return outputGlbPath;
      } else {
        print('Conversion failed! Exit code: ${result.exitCode}');
        print('obj2gltf Stderr: ${result.stderr}');
        throw Exception('OBJ to GLTF conversion failed: ${result.stderr}');
      }
    } catch (e) {
      print('Error during OBJ to GLTF conversion: $e');
      rethrow; // Re-throw to propagate the error
    }
  }
}