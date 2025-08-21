import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_mask_painter/flutter_mask_painter.dart';
import 'package:flutter_mask_painter/mask_painter_controller.dart';
import 'package:image_picker/image_picker.dart';


/// A comprehensive demo of the MaskPainterWidget showing all features
/// This can be used for testing and demonstration purposes
class MaskPainterExample extends StatefulWidget {
  const MaskPainterExample({super.key});

  @override
  State<MaskPainterExample> createState() => _MaskPainterExampleState();
}

class _MaskPainterExampleState extends State<MaskPainterExample> {
  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    setState(() {
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }
  final MaskPainterController _controller = MaskPainterController(
  initialBrushSize: 25.0,
  minBrushSize: 5.0,
  maxBrushSize: 100.0,
  maskColor: const Color.fromARGB(255, 255, 255, 255),
  backgroundColor: Colors.black,
);
  XFile? _selectedImage;
  XFile? _savedMask;
  String _statusMessage = 'Select an image to start drawing mask';
  bool _showMaskPreview = false;
  bool _hasStrokes = false;

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
          _savedMask = null;
          _statusMessage = 'Image loaded. Start drawing to create mask.';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error picking image: $e';
      });
    }
  }

  void _onMaskSaved(XFile maskFile) {
    setState(() {
      _savedMask = maskFile;
      _statusMessage = 'Mask saved successfully!';
      _showMaskPreview = true;
    });
  }

  void _reset() {
    _controller.clear();
    setState(() {
      _selectedImage = null;
      _savedMask = null;
      _statusMessage = 'Select an image to start drawing mask';
      _showMaskPreview = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showMaskPreview && _savedMask != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: Image.file(
                File(_savedMask!.path),
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
                  onPressed: () {
                    setState(() {
                      _showMaskPreview = false;
                    });
                  },
                  tooltip: 'Back',
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Mask Drawing Demo'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          if (_selectedImage != null)
            IconButton(
              onPressed: _reset,
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset',
            ),
        ],
      ),
      body:
          _selectedImage == null ? _buildImageSelector() : _buildMaskDrawing(),
      floatingActionButton: _selectedImage == null
          ? FloatingActionButton(
              onPressed: _pickImage,
              backgroundColor: const Color(0XFF5460C6),
              child: const Icon(Icons.add_photo_alternate, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildImageSelector() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.image_outlined,
                size: 60,
                color: Colors.grey.shade400,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Mask Drawing Widget Demo',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              'Create precise black and white masks for image editing',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),

            // Features list
            _buildFeaturesList(),

            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('Select Image'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0XFF5460C6),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      'Responsive design - adapts to any screen size',
      'Undo & Redo functionality',
      'Adjustable brush size with visual preview',
      'Real-time mask preview with transparency',
      'Save mask as PNG file',
      'Touch-friendly drawing experience',
      'Boundary detection prevents drawing outside image',
      'Professional UI with smooth controls',
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Features',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0XFF5460C6),
            ),
          ),
          SizedBox(height: 12),
          ...features.map((feature) => Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildMaskDrawing() {
    return Column(
      children: [
        // Status bar
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                _savedMask != null ? Colors.green.shade50 : Colors.blue.shade50,
            border: Border(
              bottom: BorderSide(
                color: _savedMask != null
                    ? Colors.green.shade200
                    : Colors.blue.shade200,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _savedMask != null ? Icons.check_circle : Icons.info_outline,
                color: _savedMask != null
                    ? Colors.green.shade600
                    : Colors.blue.shade600,
                size: 20,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    fontSize: 14,
                    color: _savedMask != null
                        ? Colors.green.shade800
                        : Colors.blue.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

  // (Full screen preview handled in build)

        // Instructions
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey.shade100,
          child: Row(
            children: [
              Icon(Icons.brush, size: 16, color: Colors.grey.shade600),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Draw on areas you want to mask (remove). White = masked, Black = keep.'
                '  tap on save button to export the mask',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Mask drawing widget
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: MaskPainterWidget(
              backgroundImage: _selectedImage!,
              onMaskSaved: _onMaskSaved,
              controller: _controller, 
            ),
          ),
        ),

        // Action buttons
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
            onPressed: _controller.hasStrokes ? (){
              print(  'Exporting mask...');
              _controller.saveMask();
            } : null,
                  icon: const Icon(Icons.save),
                  label: const Text('Export Mask'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0XFF5460C6),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
         
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Start Over'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0XFF5460C6),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
