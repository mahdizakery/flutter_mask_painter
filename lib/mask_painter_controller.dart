import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Controller that manages all state for MaskPainterWidget
class MaskPainterController extends ChangeNotifier {
  MaskPainterController({
    double initialBrushSize = 20.0,
    double minBrushSize = 5.0,
    double maxBrushSize = 100.0,
    Color maskColor = Colors.white,
    Color backgroundColor = Colors.black,
  })  : _brushSize = initialBrushSize,
        _minBrushSize = minBrushSize,
        _maxBrushSize = maxBrushSize,
        _maskColor = maskColor,
        _backgroundColor = backgroundColor;

  // Configuration
  final double _minBrushSize;
  final double _maxBrushSize;
  final Color _maskColor;
  final Color _backgroundColor;

  // Drawing state
  double _brushSize;
  List<Offset> _currentStroke = [];
  List<DrawingStroke> _strokes = [];
  List<DrawingStroke> _redoStack = [];

  // Smooth drawing state
  Path _currentPath = Path();
  bool _isDrawing = false;
  bool _hasPanned = false;

  // Image properties
  ui.Image? _backgroundImageUI;
  double? _imageWidth;
  double? _imageHeight;
  double? _canvasWidth;
  double? _canvasHeight;
  bool _isLoading = true;

  // Callbacks
  Function(XFile)? _onMaskSaved;

  // Getters
  double get brushSize => _brushSize;
  double get minBrushSize => _minBrushSize;
  double get maxBrushSize => _maxBrushSize;
  Color get maskColor => _maskColor;
  Color get backgroundColor => _backgroundColor;

  List<DrawingStroke> get strokes => List.unmodifiable(_strokes);
  List<Offset> get currentStroke => List.unmodifiable(_currentStroke);
  Path get currentPath => _currentPath;
  bool get isDrawing => _isDrawing;
  bool get hasPanned => _hasPanned;

  ui.Image? get backgroundImageUI => _backgroundImageUI;
  double? get imageWidth => _imageWidth;
  double? get imageHeight => _imageHeight;
  double? get canvasWidth => _canvasWidth;
  double? get canvasHeight => _canvasHeight;
  bool get isLoading => _isLoading;

  bool get canUndo => _strokes.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  bool get hasStrokes => _strokes.isNotEmpty;

  // Public methods
  Future<void> loadBackgroundImage(XFile backgroundImage) async {
    try {
      _isLoading = true;
      notifyListeners();

      final imageFile = File(backgroundImage.path);
      final bytes = await imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();

      _backgroundImageUI = frame.image;
      _imageWidth = frame.image.width.toDouble();
      _imageHeight = frame.image.height.toDouble();
      _isLoading = false;

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading background image: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  void setOnMaskSaved(Function(XFile)? callback) {
    _onMaskSaved = callback;
  }

  void setCanvasDimensions(double width, double height) {
    _canvasWidth = width;
    _canvasHeight = height;
  }

  void onTapDown(TapDownDetails details) {
    _hasPanned = false;

    final localPosition = details.localPosition;
    if (_isPointInBounds(localPosition)) {
      _isDrawing = true;
      _currentStroke = [localPosition];
      _currentPath = Path();
      notifyListeners();
    }
  }

  void onTapUp(TapUpDetails details) {
    if (!_hasPanned && _isDrawing) {
      final localPosition = details.localPosition;
      if (_isPointInBounds(localPosition)) {
        final tapPath = Path()
          ..addOval(Rect.fromCircle(
            center: localPosition,
            radius: _brushSize / 2,
          ));

        final tapStroke = DrawingStroke(
          points: [localPosition],
          size: _brushSize,
          color: _maskColor,
          path: tapPath,
        );

        _strokes.add(tapStroke);
        _redoStack.clear();

        _isDrawing = false;
        _currentStroke.clear();
        _currentPath = Path();
        notifyListeners();
      }
    } else if (_isDrawing) {
      _isDrawing = false;
      _currentStroke.clear();
      _currentPath = Path();
      notifyListeners();
    }
  }

  void onPanStart(DragStartDetails details) {
    final localPosition = details.localPosition;
    if (_isPointInBounds(localPosition)) {
      _hasPanned = true;

      if (!_isDrawing) {
        _isDrawing = true;
        _currentStroke = [localPosition];
        _currentPath = Path();
      }

      if (_currentPath.getBounds().isEmpty) {
        _currentPath.moveTo(localPosition.dx, localPosition.dy);
      }
      notifyListeners();
    }
  }

  void onPanUpdate(DragUpdateDetails details) {
    if (!_isDrawing) return;

    final localPosition = details.localPosition;
    if (_isPointInBounds(localPosition)) {
      if (_currentStroke.isNotEmpty) {
        final lastPoint = _currentStroke.last;
        final distance = (localPosition - lastPoint).distance;

        if (distance > 2.0) {
          final steps = (distance / 2.0).round().clamp(1, 5);
          for (int i = 1; i <= steps; i++) {
            final t = i / steps;
            final interpolatedPoint = Offset.lerp(lastPoint, localPosition, t)!;
            _currentStroke.add(interpolatedPoint);
          }
        } else {
          _currentStroke.add(localPosition);
        }
      } else {
        _currentStroke.add(localPosition);
      }

      _updateCurrentPath();
      notifyListeners();
    }
  }

  void onPanEnd(DragEndDetails details) {
    if (!_isDrawing) return;

    _isDrawing = false;

    if (_currentStroke.isNotEmpty) {
      final stroke = DrawingStroke(
        points: List.from(_currentStroke),
        size: _brushSize,
        color: _maskColor,
        path: Path.from(_currentPath),
      );

      _strokes.add(stroke);
      _currentStroke.clear();
      _currentPath = Path();
      _redoStack.clear();
    }
    notifyListeners();
  }

  void _updateCurrentPath() {
    if (_currentStroke.length < 2) return;

    _currentPath = Path();
    _currentPath.moveTo(_currentStroke[0].dx, _currentStroke[0].dy);

    if (_currentStroke.length == 2) {
      _currentPath.lineTo(_currentStroke[1].dx, _currentStroke[1].dy);
    } else if (_currentStroke.length > 2) {
      for (int i = 1; i < _currentStroke.length - 1; i++) {
        final currentPoint = _currentStroke[i];
        final nextPoint = _currentStroke[i + 1];

        final controlPoint = Offset(
          (currentPoint.dx + nextPoint.dx) / 2,
          (currentPoint.dy + nextPoint.dy) / 2,
        );

        _currentPath.quadraticBezierTo(
          currentPoint.dx,
          currentPoint.dy,
          controlPoint.dx,
          controlPoint.dy,
        );
      }

      final lastPoint = _currentStroke.last;
      _currentPath.lineTo(lastPoint.dx, lastPoint.dy);
    }
  }

  bool _isPointInBounds(Offset point) {
    if (_canvasWidth == null || _canvasHeight == null) return false;
    return point.dx >= 0 &&
        point.dx <= _canvasWidth! &&
        point.dy >= 0 &&
        point.dy <= _canvasHeight!;
  }

  void undo() {
    if (_strokes.isNotEmpty) {
      final lastStroke = _strokes.removeLast();
      _redoStack.add(lastStroke);
      _currentStroke.clear();
      _currentPath = Path();
      _isDrawing = false;
      notifyListeners();
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      final lastRedoStroke = _redoStack.removeLast();
      _strokes.add(lastRedoStroke);
      _currentStroke.clear();
      _currentPath = Path();
      _isDrawing = false;
      notifyListeners();
    }
  }

  void clear() {
    _strokes.clear();
    _currentStroke.clear();
    _currentPath = Path();
    _redoStack.clear();
    _isDrawing = false;
    notifyListeners();
  }

  void setBrushSize(double size) {
    final clampedSize = size.clamp(_minBrushSize, _maxBrushSize);
    if (_brushSize != clampedSize) {
      _brushSize = clampedSize;
      notifyListeners();
    }
  }

  Future<XFile?> saveMask() async {
    try {
      if (_imageWidth == null || _imageHeight == null) return null;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, _imageWidth!, _imageHeight!),
      );

      final backgroundPaint = Paint()..color = _backgroundColor;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, _imageWidth!, _imageHeight!),
        backgroundPaint,
      );

      final scaleX = _imageWidth! / (_canvasWidth ?? _imageWidth!);
      final scaleY = _imageHeight! / (_canvasHeight ?? _imageHeight!);

      final maskPaint = Paint()
        ..color = _maskColor
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      for (final stroke in _strokes) {
        maskPaint.strokeWidth = stroke.size * scaleX;

        if (stroke.points.length == 1) {
          final scaledPoint = Offset(
            stroke.points.first.dx * scaleX,
            stroke.points.first.dy * scaleY,
          );
          final scaledRadius = (stroke.size / 2) * scaleX;

          canvas.drawCircle(
            scaledPoint,
            scaledRadius,
            Paint()
              ..color = _maskColor
              ..style = PaintingStyle.fill,
          );
        } else {
          final scaledPath = Path();
          final pathMetrics = stroke.path.computeMetrics();

          for (final pathMetric in pathMetrics) {
            bool isFirst = true;

            for (double distance = 0;
                distance <= pathMetric.length;
                distance += 1.0) {
              final tangent = pathMetric.getTangentForOffset(distance);
              if (tangent != null) {
                final scaledPoint = Offset(
                  tangent.position.dx * scaleX,
                  tangent.position.dy * scaleY,
                );

                if (isFirst) {
                  scaledPath.moveTo(scaledPoint.dx, scaledPoint.dy);
                  isFirst = false;
                } else {
                  scaledPath.lineTo(scaledPoint.dx, scaledPoint.dy);
                }
              }
            }
          }

          canvas.drawPath(scaledPath, maskPaint);
        }
      }

      final picture = recorder.endRecording();
      final image =
          await picture.toImage(_imageWidth!.toInt(), _imageHeight!.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final directory = await getTemporaryDirectory();
        final file = File(
            '${directory.path}/mask_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(byteData.buffer.asUint8List());

        final maskFile = XFile(file.path);
        _onMaskSaved?.call(maskFile);
        print('Mask saved to: ${maskFile.path}');
        return maskFile;
      }
    } catch (e) {
      debugPrint('Error saving mask: $e');
    }
    return null;
  }
}

/// Represents a drawing stroke with points, size, color, and smooth path
class DrawingStroke {
  const DrawingStroke({
    required this.points,
    required this.size,
    required this.color,
    required this.path,
  });

  final List<Offset> points;
  final double size;
  final Color color;
  final Path path;
}
