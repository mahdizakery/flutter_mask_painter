import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'mask_painter_controller.dart';

/// A responsive widget for creating mask layers (black and white) from sketched or brushed areas on top of an image
/// Features: undo, redo, brush size control, save functionality
class MaskPainterWidget extends StatefulWidget {
  const MaskPainterWidget({
    super.key,
    required this.backgroundImage,
    this.onMaskSaved,
    this.initialBrushSize = 20.0,
    this.minBrushSize = 5.0,
    this.maxBrushSize = 100.0,
    this.maskColor = Colors.white,
    this.backgroundColor = Colors.black,
    this.showControls = true,
    this.aspectRatio,
    this.controller,
  });

  /// The background image file to draw mask on
  final XFile backgroundImage;

  /// Callback when mask is saved, returns the mask as XFile
  final Function(XFile maskFile)? onMaskSaved;

  /// Initial brush size
  final double initialBrushSize;

  /// Minimum brush size
  final double minBrushSize;

  /// Maximum brush size
  final double maxBrushSize;

  /// Color for drawn areas (mask areas)
  final Color maskColor;

  /// Background color for non-masked areas
  final Color backgroundColor;

  /// Whether to show drawing controls
  final bool showControls;

  /// Fixed aspect ratio for the drawing area
  final double? aspectRatio;

  /// Controller for external control of the widget
  final MaskPainterController? controller;

  @override
  State<MaskPainterWidget> createState() => _MaskPainterWidgetState();
}

class _MaskPainterWidgetState extends State<MaskPainterWidget> {
  late final MaskPainterController _controller = widget.controller ??
      MaskPainterController(
        initialBrushSize: widget.initialBrushSize,
        minBrushSize: widget.minBrushSize,
        maxBrushSize: widget.maxBrushSize,
        maskColor: widget.maskColor,
        backgroundColor: widget.backgroundColor,
      );

  @override
  void initState() {
    super.initState();
    _controller.setOnMaskSaved(widget.onMaskSaved);

    // Defer loadBackgroundImage to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadBackgroundImage(widget.backgroundImage);
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  Widget _buildBrushSizeSlider() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: Row(
        children: [
          Icon(Icons.brush, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Slider(
              value: _controller.brushSize,
              min: _controller.minBrushSize,
              max: _controller.maxBrushSize,
              divisions:
                  ((_controller.maxBrushSize - _controller.minBrushSize) / 5)
                      .round(),
              onChanged: _controller.setBrushSize,
              activeColor: Colors.blue,
            ),
          ),
          SizedBox(width: 8),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _controller.maskColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Container(
                width:
                    (_controller.brushSize / _controller.maxBrushSize * 16),
                height:
                    (_controller.brushSize / _controller.maxBrushSize * 16),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Container(
      padding: EdgeInsets.all(8),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildControlButton(
            icon: Icons.undo,
            onTap: _controller.canUndo ? _controller.undo : null,
            tooltip: 'Undo',
          ),
          SizedBox(width: 8),
          _buildControlButton(
            icon: Icons.redo,
            onTap: _controller.canRedo ? _controller.redo : null,
            tooltip: 'Redo',
          ),
          SizedBox(width: 8),
          _buildControlButton(
            icon: Icons.delete,
            onTap: _controller.hasStrokes ? _controller.clear : null,
            tooltip: 'Clear',
          ),
          SizedBox(width: 8),
          _buildControlButton(
            icon: Icons.save,
            onTap: _controller.hasStrokes ? _controller.saveMask : null,
            tooltip: 'Save Mask',
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onTap,
    required String tooltip,
  }) {
    final isEnabled = onTap != null;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            border: Border.all(
              color: isEnabled ? Colors.blue : Colors.grey,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isEnabled ? Colors.blue : Colors.grey,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (_controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_controller.backgroundImageUI == null) {
          return const Center(child: Text('Failed to load image'));
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final imageAspectRatio =
                _controller.imageWidth! / _controller.imageHeight!;
            final maxWidth = constraints.maxWidth - 32;
            final maxHeight =
                constraints.maxHeight - (widget.showControls ? 120 : 32);

            double canvasWidth, canvasHeight;

            if (widget.aspectRatio != null) {
              canvasWidth = maxWidth;
              canvasHeight = maxWidth / widget.aspectRatio!;

              if (canvasHeight > maxHeight) {
                canvasHeight = maxHeight;
                canvasWidth = maxHeight * widget.aspectRatio!;
              }
            } else {
              if (imageAspectRatio > (maxWidth / maxHeight)) {
                canvasWidth = maxWidth;
                canvasHeight = maxWidth / imageAspectRatio;
              } else {
                canvasHeight = maxHeight;
                canvasWidth = maxHeight * imageAspectRatio;
              }
            }

            _controller.setCanvasDimensions(canvasWidth, canvasHeight);

            return Column(
              children: [
                Center(
                  child: Container(
                    width: canvasWidth,
                    height: canvasHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: RepaintBoundary(
                        child: GestureDetector(
                          onTapDown: _controller.onTapDown,
                          onTapUp: _controller.onTapUp,
                          onPanStart: _controller.onPanStart,
                          onPanUpdate: _controller.onPanUpdate,
                          onPanEnd: _controller.onPanEnd,
                          behavior: HitTestBehavior.opaque,
                          child: Stack(
                            children: [
                              SizedBox(
                                width: canvasWidth,
                                height: canvasHeight,
                                child: RawImage(
                                  image: _controller.backgroundImageUI,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              CustomPaint(
                                size: Size(canvasWidth, canvasHeight),
                                painter: MaskPainter(
                                  strokes: _controller.strokes,
                                  currentStroke: _controller.currentStroke,
                                  brushSize: _controller.brushSize,
                                  strokeColor: _controller.maskColor,
                                  isDrawing: _controller.isDrawing,
                                  currentPath: _controller.currentPath,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.showControls) ...[
                  SizedBox(height: 16),
                  _buildBrushSizeSlider(),
                  SizedBox(height: 12),
                  _buildControlButtons(),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

/// Custom painter for drawing mask strokes
class MaskPainter extends CustomPainter {
  const MaskPainter({
    required this.strokes,
    required this.currentStroke,
    required this.brushSize,
    required this.strokeColor,
    required this.isDrawing,
    required this.currentPath,
  });

  final List<DrawingStroke> strokes;
  final List<Offset> currentStroke;
  final double brushSize;
  final Color strokeColor;
  final bool isDrawing;
  final Path currentPath;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final paint = Paint()
      ..color = strokeColor.withOpacity(0.8)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      paint
        ..strokeWidth = stroke.size
        ..color = stroke.color.withOpacity(0.8);

      if (stroke.points.length == 1) {
        paint.style = PaintingStyle.fill;
        canvas.drawCircle(stroke.points.first, stroke.size / 2, paint);
        paint.style = PaintingStyle.stroke;
      } else {
        canvas.drawPath(stroke.path, paint);
      }
    }

    if (currentStroke.isNotEmpty && isDrawing) {
      paint
        ..strokeWidth = brushSize
        ..color = strokeColor.withOpacity(0.9);

      if (currentStroke.length == 1) {
        paint.style = PaintingStyle.fill;
        canvas.drawCircle(currentStroke.first, brushSize / 2, paint);
        paint.style = PaintingStyle.stroke;
      } else {
        canvas.drawPath(currentPath, paint);

        if (currentStroke.isNotEmpty) {
          final lastPoint = currentStroke.last;
          paint
            ..style = PaintingStyle.fill
            ..color = strokeColor.withOpacity(0.3);
          canvas.drawCircle(lastPoint, brushSize / 2, paint);
          paint.style = PaintingStyle.stroke;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant MaskPainter oldDelegate) {
    return oldDelegate.strokes.length != strokes.length ||
        oldDelegate.currentStroke.length != currentStroke.length ||
        oldDelegate.brushSize != brushSize ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.isDrawing != isDrawing ||
        oldDelegate.currentPath != currentPath;
  }
}
