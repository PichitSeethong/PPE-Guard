import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppe_guard_app/ui/widgets/evidence_image.dart';
import 'package:ppe_guard_app/ui/widgets/evidence_layout.dart';

Future<MemoryImage> _fixture(int width, int height) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = Colors.blue,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return MemoryImage(bytes!.buffer.asUint8List());
}

void _viewport(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _loadImage(WidgetTester tester, MemoryImage image) async {
  await tester.runAsync(() => precacheImage(
        image,
        tester.element(find.byType(EvidenceImage).first),
      ));
  await tester.pumpAndSettle();
}

void main() {
  for (final size in [const Size(90, 160), const Size(160, 90), const Size(100, 100)]) {
    testWidgets('contains complete ${size.width} x ${size.height} evidence',
        (tester) async {
      _viewport(tester, const Size(1280, 800));
      final image = (await tester.runAsync(
        () => _fixture(size.width.toInt(), size.height.toInt()),
      ))!;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 500,
              child: EvidenceImage(image: image, height: 360),
            ),
          ),
        ),
      ));
      await _loadImage(tester, image);
      final rendered = tester.renderObject<RenderImage>(find.byType(RawImage));
      expect(rendered.fit, BoxFit.contain);
      final fitted = applyBoxFit(rendered.fit!, size, rendered.size);
      expect(fitted.source, size);
      expect(fitted.destination.aspectRatio, closeTo(size.aspectRatio, .000001));
      expect(fitted.destination.width, lessThanOrEqualTo(500));
      expect(fitted.destination.height, lessThanOrEqualTo(360));
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in [
    const Size(1536, 777),
    const Size(1366, 768),
    const Size(1024, 600),
    const Size(768, 1024),
    const Size(390, 844),
    const Size(320, 568),
    const Size(844, 390),
  ]) {
    testWidgets('responsive event layout at $size', (tester) async {
      _viewport(tester, size);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('รายละเอียดเหตุการณ์')),
          body: const EvidenceLayout(
            image: null,
            header: Text('PPE-CAMERA-01'),
            information: SizedBox(height: 200, child: Text('ผลการตรวจ PPE')),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      final preview = tester.getRect(find.byKey(const ValueKey('evidence-preview')));
      final details = tester.getRect(find.byKey(const ValueKey('evidence-information')));
      if (size.width >= 960) {
        expect(details.left, greaterThan(preview.right));
        expect(details.top, closeTo(preview.top, .01));
        expect(preview.height, lessThanOrEqualTo(500));
      } else {
        expect(details.top, greaterThan(preview.bottom));
        expect(preview.height, lessThanOrEqualTo(320));
      }
      expect(details.top, lessThan(size.height));
      expect(preview.left, greaterThanOrEqualTo(0));
      expect(preview.right, lessThanOrEqualTo(size.width));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('entrance status comes first on a small screen', (tester) async {
    _viewport(tester, const Size(390, 844));
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: EvidenceLayout(
          image: null,
          imageFirstOnMobile: false,
          information: SizedBox(height: 200, child: Text('ยังไม่ผ่านจุดตรวจ')),
        ),
      ),
    ));
    final preview = tester.getRect(find.byKey(const ValueKey('evidence-preview')));
    final details = tester.getRect(find.byKey(const ValueKey('evidence-information')));
    expect(details.bottom, lessThan(preview.top));
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing evidence has a bounded placeholder', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: EvidenceImage(image: null, height: 240)),
    ));
    expect(find.text('ไม่มีรูปหลักฐาน'), findsOneWidget);
    expect(find.byTooltip('ขยายภาพหลักฐาน'), findsNothing);
    expect(tester.getSize(find.byType(EvidenceImage)).height, 240);
    expect(tester.takeException(), isNull);
  });

  testWidgets('entrance can hide missing evidence without hiding status',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: EvidenceLayout(
          image: null,
          showMissingImage: false,
          information: Text('ผ่านจุดตรวจ'),
        ),
      ),
    ));
    expect(find.byType(EvidenceImage), findsNothing);
    expect(find.text('ผ่านจุดตรวจ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fullscreen opens and closes without changing the preview',
      (tester) async {
    _viewport(tester, const Size(1280, 800));
    final image = (await tester.runAsync(() => _fixture(90, 160)))!;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: EvidenceImage(image: image, height: 300)),
    ));
    await _loadImage(tester, image);
    await tester.tap(find.byTooltip('ขยายภาพหลักฐาน'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    final viewer = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
    expect(viewer.minScale, 1);
    expect(viewer.maxScale, 4);
    for (final widget in tester.widgetList<Image>(find.byType(Image))) {
      expect(widget.fit, BoxFit.contain);
    }
    await tester.tap(find.byTooltip('ปิดภาพ'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsNothing);
    expect(tester.getSize(find.byType(EvidenceImage)).height, 300);
    expect(tester.takeException(), isNull);
  });
}
