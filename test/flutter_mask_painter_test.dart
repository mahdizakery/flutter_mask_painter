import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mask_painter/flutter_mask_painter.dart';
import 'package:image_picker/image_picker.dart';

class DummyXFile extends XFile {
  DummyXFile() : super('test/assets/dummy.png');
}

void main() {
  testWidgets('MaskPainterWidget builds', (WidgetTester tester) async {
    
    final dummyImage = DummyXFile();

    await tester.pumpWidget(
      MaterialApp(
        home: MaskPainterWidget(
          backgroundImage: dummyImage,
        ),
      ),
    );

    expect(find.byType(MaskPainterWidget), findsOneWidget);
  });
}
