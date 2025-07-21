import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'dart:io'; // For Process, ProcessResult, File, Directory
import 'dart:typed_data'; // For ByteData <--- ADDED/CONFIRMED
import 'dart:convert'; // For utf8.decoder <--- ADDED
import 'package:flutter/services.dart' show rootBundle; // For rootBundle to read assets
import 'package:path_provider/path_provider.dart'; // For getTemporaryDirectory
import 'package:path/path.dart' as p; // For path manipulation

class OdmResultSelector extends StatefulWidget {
  final ValueChanged<String> onFolderSelected;
  final VoidCallback? onOdmProcessComplete; // <--- NEW: Callback for ODM completion

  const OdmResultSelector({
    super.key,
    required this.onFolderSelected,
    this.onOdmProcessComplete, // <--- NEW: Initialize in constructor
  });

  @override
  State<OdmResultSelector> createState() => _OdmResultSelectorState();
}

class _OdmResultSelectorState extends State<OdmResultSelector> {
  final TextEditingController _folderPathController = TextEditingController();
  bool _isProcessing = false;
  String _progressMessage = '';
  String _odmProcessOutput = ''; // New: To show real-time process output

  @override
  void dispose() {
    _folderPathController.dispose();
    super.dispose();
  }

  Future<void> _selectOdmResultsFolder() async {
    final String? directoryPath = await getDirectoryPath();
    if (directoryPath != null) {
      setState(() {
        _folderPathController.text = directoryPath;
        _progressMessage = 'Folder selected: $directoryPath';
        _odmProcessOutput = ''; // Clear output on new selection
      });
      widget.onFolderSelected(directoryPath); // Notify main.dart
    } else {
      setState(() {
        _progressMessage = 'Folder selection cancelled.';
      });
    }
  }

  Future<void> _runOdmSoftware() async {
    if (_folderPathController.text.isEmpty) {
      setState(() {
        _progressMessage = 'Please select an ODM results folder first.';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _progressMessage = 'Starting ODM software...';
      _odmProcessOutput = ''; // Clear previous output when starting
    });

    final String odmPath = _folderPathController.text;
    String? tempBatFilePath; // To store the path of the temporary .bat file

    try {
      // 1. Get a temporary directory where we can write the .bat file
      final Directory tempDir = await getTemporaryDirectory();
      final String tempDirPath = tempDir.path;

      // 2. Define the absolute path for the temporary .bat file
      final String batFileName = 'run_odm.bat';
      tempBatFilePath = p.join(tempDirPath, batFileName);
      final File tempBatFile = File(tempBatFilePath);

      // 3. Load the .bat file content from assets
      final ByteData data = await rootBundle.load('assets/run_odm.bat');
      final List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      // 4. Write the content to the temporary file
      await tempBatFile.writeAsBytes(bytes, flush: true);

      // 5. Ensure the temporary file is executable (important for Linux/macOS, optional for Windows .bat)
      if (!Platform.isWindows) {
        await Process.run('chmod', ['+x', tempBatFilePath]);
      }

      // 6. Execute the .bat file using Process.start for real-time output
      final Process process = await Process.start(
        tempBatFilePath, // Use the absolute path to the copied .bat file
        [odmPath], // Pass the selected ODM folder path as an argument
        runInShell: true, // Crucial for Windows .bat files
      );

      // Listen to stdout and update UI
      process.stdout.transform(utf8.decoder).listen((data) {
        setState(() {
          _odmProcessOutput += data;
        });
        print('ODM Stdout: $data'); // Still print to console for debugging
      });

      // Listen to stderr and update UI
      process.stderr.transform(utf8.decoder).listen((data) {
        setState(() {
          _odmProcessOutput += data;
        });
        print('ODM Stderr: $data'); // Still print to console for debugging
      });

      // Wait for the process to finish
      final int exitCode = await process.exitCode;

      setState(() {
        _isProcessing = false;
        if (exitCode == 0) {
          _progressMessage = 'ODM software completed successfully!';
          // NEW: Trigger the automatic model conversion
          widget.onOdmProcessComplete?.call(); // This line triggers the auto-conversion
        } else {
          _progressMessage = 'ODM software failed! Exit code: $exitCode';
        }
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _progressMessage = 'Error running ODM software: $e';
        _odmProcessOutput += '\nError: $e'; // Add error to output display
        print('Error running ODM software: $e');
      });
    } finally {
      // Clean up: Delete the temporary .bat file after execution
      if (tempBatFilePath != null && await File(tempBatFilePath).exists()) {
        try {
          await File(tempBatFilePath).delete();
          print('Deleted temporary bat file: $tempBatFilePath');
        } catch (e) {
          print('Error deleting temporary bat file: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select ODM Results Folder:',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _folderPathController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    hintText: 'Click "Browse" to select folder',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onTap: _selectOdmResultsFolder,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _selectOdmResultsFolder,
                child: const Text('Browse'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // The "Run ODM Software" button
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _runOdmSoftware, // Disable while processing
            icon: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.play_arrow),
            label: const Text('Run ODM Software'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40), // Full width button
            ),
          ),
          const SizedBox(height: 10),
          // Progress/Status Message
          if (_progressMessage.isNotEmpty)
            Text(
              _progressMessage,
              style: TextStyle(
                fontSize: 14,
                color: _progressMessage.contains('failed') ? Colors.red : Colors.green,
              ),
            ),
          const SizedBox(height: 20),
          // New: Display ODM Process Output
          if (_odmProcessOutput.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ODM Process Output:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  height: 200, // Fixed height for the output window
                  child: SingleChildScrollView(
                    child: Text(
                      _odmProcessOutput,
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.white),
                      maxLines: null, // Allow unlimited lines
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
        ],
      ),
    );
  }
}