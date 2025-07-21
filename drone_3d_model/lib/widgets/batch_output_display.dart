import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class BatchOutputDisplay extends StatefulWidget {
  final String modelPath; // This will now be the GLB path

  const BatchOutputDisplay({super.key, required this.modelPath});

  @override
  State<BatchOutputDisplay> createState() => _BatchOutputDisplayState();
}

class _BatchOutputDisplayState extends State<BatchOutputDisplay> {
  @override
  Widget build(BuildContext context) {
    if (widget.modelPath.isEmpty) {
      return const Center(
        child: Text(
          'No 3D Model Loaded.\nSelect an ODM results folder to view.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    // Use ModelViewer for GLB models
    return Column(
      children: [
        Expanded(
          child: Container( // Added Container for background color
            color: Colors.black, // Set the desired solid background color here
            child: ModelViewer(
              src: 'file://${widget.modelPath}', // Local file path
              alt: "A 3D model",
              // --- DISPLAY CUSTOMIZATION START ---
              environmentImage: 'none',   // Removes environmental lighting/reflections
              skyboxImage: 'none',        // Removes the default gradient skybox
              autoRotate: false,          // Do not auto-rotate on load
              ar: false,                  // Disable Augmented Reality
              cameraControls: true,       // Keep user controls (pan, zoom, rotate)
              shadowIntensity: 0.5,       // Keep a subtle shadow, set to 0 for completely flat look
              // exposure: 1.0,           // You can tweak this for overall brightness (default is 1.0)
              // fieldOfView: '45deg',    // Adjust camera field of view if needed
              // --- DISPLAY CUSTOMIZATION END ---
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Model Loaded: ${widget.modelPath.split('/').last}',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}