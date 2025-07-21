// lib/widgets/batch_file_runner_logic.dart - CORRECTED STATE CLASS NAME
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:typed_data';
import 'dart:async';
import 'package:file_selector/file_selector.dart';
import 'dart:convert';

class BatchFileRunnerLogic extends StatefulWidget {
  final Function(String newText, {String? modelPath}) onOutputGenerated;

  const BatchFileRunnerLogic({
    super.key,
    required this.onOutputGenerated,
  });

  @override
  // THIS LINE IS CHANGED: from _BatchFileRunnerState() to _BatchFileRunnerLogicState()
  State<BatchFileRunnerLogic> createState() => _BatchFileRunnerLogicState();
}

class _BatchFileRunnerLogicState extends State<BatchFileRunnerLogic> { // This is the correct class name
  bool _isExecuting = false;
  final TextEditingController _inputPathController = TextEditingController();
  final String _assetBatchFilePath = 'assets/run_odm.bat';

  @override
  void dispose() {
    _inputPathController.dispose();
    super.dispose();
  }

  Future<void> _pickDirectory() async {
    try {
      final String? directoryPath = await getDirectoryPath();
      if (directoryPath != null) {
        _inputPathController.text = directoryPath;
        widget.onOutputGenerated("Selected folder: $directoryPath");
      }
    } catch (e) {
      debugPrint("ERROR: Failed to pick directory - $e");
      widget.onOutputGenerated("ERROR: Failed to pick directory.");
    }
  }

  Future<void> _executeBatchFile() async {
    final String dataPath = _inputPathController.text.trim();
    String? generatedModelPath; // To store the found model path

    if (dataPath.isEmpty) {
      widget.onOutputGenerated("ERROR: No data path provided. Script will not run.");
      debugPrint("ERROR: No data path provided. Script will not run.");
      return;
    }

    widget.onOutputGenerated("Starting ODM process for: $dataPath\n", modelPath: null); // Clear output and reset model display

    setState(() {
      _isExecuting = true;
    });

    Process? process;
    StringBuffer outputBuffer = StringBuffer(); // To collect all output

    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String tempFilePath = p.join(appDocDir.path, 'run_odm_temp.bat');
      final File tempFile = File(tempFilePath);

      final ByteData data = await rootBundle.load(_assetBatchFilePath);
      final List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await tempFile.writeAsBytes(bytes);
      debugPrint("Batch file copied to: $tempFilePath");
      outputBuffer.writeln("Batch file copied to: $tempFilePath");

      debugPrint("Starting process: cmd.exe /c \"$tempFilePath\" \"$dataPath\"");
      outputBuffer.writeln("Starting process: cmd.exe /c \"$tempFilePath\" \"$dataPath\"");

      process = await Process.start(
        'cmd.exe',
        ['/c', tempFilePath, dataPath], // Process.start handles quoting for dataPath as a separate arg
        runInShell: true,
      );

      // Listen to stdout and stderr, append to buffer, and report periodically
      process.stdout.transform(utf8.decoder).listen((data) {
        debugPrint('ODM STDOUT: $data');
        outputBuffer.writeln('ODM STDOUT: $data');
        widget.onOutputGenerated(outputBuffer.toString()); // Update UI with current output
      });

      process.stderr.transform(utf8.decoder).listen((data) {
        debugPrint('ODM STDERR: $data');
        outputBuffer.writeln('ODM STDERR: $data');
        widget.onOutputGenerated(outputBuffer.toString()); // Update UI with current output
      });

      debugPrint("Waiting for process to exit...");
      outputBuffer.writeln("Waiting for process to exit...");

      final int exitCode = await process.exitCode;
      debugPrint("Process exited with code: $exitCode");
      outputBuffer.writeln("Process exited with code: $exitCode");

      await tempFile.delete(); // Clean up the temporary batch file

      if (exitCode == 0) {
        outputBuffer.writeln("Script completed successfully!");
        debugPrint("Script completed successfully!");

        // --- Logic to find the generated 3D model ---
        // Path: [dataPath]/odm_texturing/
        // OBJ Filename: odm_textured_model_geo.obj
        // MTL Filename: odm_textured_model.mtl (different from OBJ base name)
        final String odmTexturingDir = p.join(dataPath, 'odm_texturing');
        final String expectedObjFileName = 'odm_textured_model_geo.obj'; // The OBJ file name
        final String expectedMtlFileName = 'odm_textured_model.mtl';     // The MTL file name

        final String potentialObjPath = p.join(odmTexturingDir, expectedObjFileName);
        final File objFile = File(potentialObjPath);

        if (await objFile.exists()) {
          // Explicitly check for the MTL file with its specific name
          final String potentialMtlPath = p.join(odmTexturingDir, expectedMtlFileName);
          final File mtlFile = File(potentialMtlPath);

          if (await mtlFile.exists()) {
            generatedModelPath = objFile.path; // Store the found OBJ path
            outputBuffer.writeln("Found 3D model (OBJ: $expectedObjFileName + MTL: $expectedMtlFileName) at: $generatedModelPath");
            debugPrint("Found 3D model (OBJ: $expectedObjFileName + MTL: $expectedMtlFileName) at: $generatedModelPath");
          } else {
            outputBuffer.writeln("WARNING: Found OBJ at ${objFile.path}, but MTL file not found alongside it at: ${mtlFile.path}. Textures may not load.");
            debugPrint("WARNING: Found OBJ, but MTL file not found alongside it at: ${mtlFile.path}. Textures may not load.");
            generatedModelPath = objFile.path; // Still provide OBJ path, but warn
          }
        } else {
          outputBuffer.writeln("WARNING: 3D model (OBJ) not found at expected path: $potentialObjPath.");
          debugPrint("WARNING: 3D model (OBJ) not found at expected path: $potentialObjPath.");
        }
        // -----------------------------------------------------

      } else {
        outputBuffer.writeln("Script failed with exit code: $exitCode");
        debugPrint("Script failed with code: $exitCode");
      }

      widget.onOutputGenerated(outputBuffer.toString(), modelPath: generatedModelPath); // Send final output and model path

    } on ProcessException catch (e) {
      outputBuffer.writeln("Error: Could not start process - ${e.message}");
      debugPrint("Error: Could not start process - ${e.message}");
      widget.onOutputGenerated(outputBuffer.toString());
    } catch (e) {
      outputBuffer.writeln("An unexpected error occurred: $e");
      debugPrint("An unexpected error occurred: $e");
      widget.onOutputGenerated(outputBuffer.toString());
    } finally {
      setState(() {
        _isExecuting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _inputPathController,
          decoration: InputDecoration(
            labelText: 'Enter or select data folder path',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.folder_open),
              onPressed: _isExecuting ? null : _pickDirectory,
            ),
          ),
          enabled: !_isExecuting,
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _isExecuting ? null : _executeBatchFile,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15),
            textStyle: const TextStyle(fontSize: 18),
          ),
          child: _isExecuting
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Run OpenDroneMap'),
        ),
      ],
    );
  }
}