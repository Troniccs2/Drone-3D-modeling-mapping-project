import 'package:flutter/material.dart';
import 'package:drone_3d_model/widgets/odm_result_selector.dart';
import 'package:drone_3d_model/widgets/batch_output_display.dart';
import 'package:drone_3d_model/utils/model_converter_data.dart'; 
import 'dart:io'; // For Directory.fromPath
import 'package:path/path.dart' as p; // For path manipulation
import 'package:webview_windows/webview_windows.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) {
    // This is absolutely crucial for webview_windows to work on Windows.
    // It tells Flutter to register the native parts of the plugin.
    try {
      WebviewWindows.registerWith();
      print('webview_windows registered successfully.');
    } catch (e) {
      print('Error registering webview_windows: $e');
      // Handle the error appropriately, perhaps show a dialog to the user
      // that the WebView component could not be initialized.
    }
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ODM Testing App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _selectedOdmFolderPath = '';
  String _convertedModelPath = ''; // Stores the path to the converted GLB model
  bool _isConvertingModel = false;
  String _modelConversionMessage = '';

  Future<void> _convertModel() async {
    if (_selectedOdmFolderPath.isEmpty) {
      setState(() {
        _modelConversionMessage = 'Please select an ODM results folder first.';
      });
      return;
    }

    setState(() {
      _isConvertingModel = true;
      _modelConversionMessage = 'Converting OBJ to GLB...';
      _convertedModelPath = ''; // Clear previous model
    });

    final objFilePath = p.join(_selectedOdmFolderPath, 'odm_texturing', 'odm_textured_model_geo.obj');
    final outputGlbDir = _selectedOdmFolderPath; // Output GLB in the same selected folder

    try {
      if (!await File(objFilePath).exists()) {
        throw Exception('OBJ file not found at: $objFilePath');
      }

      final String glbPath = await ModelConverter.convertObjToGltf(objFilePath, outputGlbDir);

      setState(() {
        _convertedModelPath = glbPath;
        _modelConversionMessage = 'Model converted and loaded successfully!';
      });
    } catch (e) {
      setState(() {
        _modelConversionMessage = 'Model conversion failed: $e';
        _convertedModelPath = ''; // Clear path on error
      });
      print('Model conversion error: $e'); // Print to console for debugging
    } finally {
      setState(() {
        _isConvertingModel = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ODM 3D Model Viewer'),
      ),
      body: Row(
        children: <Widget>[
          // Left panel for controls
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  OdmResultSelector(
                    onFolderSelected: (path) {
                      setState(() {
                        _selectedOdmFolderPath = path;
                        // Clear previous conversion info when new folder is selected
                        _convertedModelPath = '';
                        _modelConversionMessage = '';
                      });
                    },
                    // NEW: Pass the _convertModel callback for automatic execution
                    onOdmProcessComplete: _convertModel, // THIS IS THE KEY FOR AUTOMATION
                  ),
                  const Divider(height: 40, thickness: 1),
                  // Button to trigger model conversion from OBJ to GLB
                  ElevatedButton.icon(
                    onPressed: _isConvertingModel ? null : _convertModel,
                    icon: _isConvertingModel
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.threesixty),
                    label: const Text('Load Selected Model (Convert OBJ to GLB)'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40), // Full width
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Conversion Status Message
                  if (_modelConversionMessage.isNotEmpty)
                    Text(
                      _modelConversionMessage,
                      style: TextStyle(
                        fontSize: 14,
                        color: _modelConversionMessage.contains('failed') ? Colors.red : Colors.green,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Right panel for 3D display
          Expanded(
            flex: 2,
            child: BatchOutputDisplay(
              modelPath: _convertedModelPath, // Pass the converted GLB path
            ),
          ),
        ],
      ),
    );
  }
}