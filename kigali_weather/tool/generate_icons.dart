import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

// Code-native marks, sharing the apps' monochrome / blue design tokens.
Future<void> generateIcons() async {
  for (final entry in {
    '../kigali_weather': false,
    '../daybook': true,
  }.entries) {
    final root = entry.key;
    final tasks = entry.value;
    final manifest = jsonDecode(
      await File(
        '$root/ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json',
      ).readAsString(),
    ) as Map;
    final outputs = <String, int>{};
    for (final row in manifest['images'] as List) {
      final size = double.parse((row['size'] as String).split('x').first);
      final scale = int.parse((row['scale'] as String).replaceAll('x', ''));
      outputs['$root/ios/Runner/Assets.xcassets/AppIcon.appiconset/${row['filename']}'] =
          (size * scale).round();
    }
    for (final density in {
      'mdpi': 48,
      'hdpi': 72,
      'xhdpi': 96,
      'xxhdpi': 144,
      'xxxhdpi': 192,
    }.entries) {
      outputs['$root/android/app/src/main/res/mipmap-${density.key}/ic_launcher.png'] =
          density.value;
    }
    for (final output in outputs.entries) {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder)..scale(output.value / 1024);
      final ink = Paint()..color = const Color(0xFF17191B);
      final blue = Paint()..color = const Color(0xFF3E6D8C);
      final white = Paint()..color = const Color(0xFFFFFFFF);
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 1024, 1024),
        tasks ? ink : white,
      );
      if (tasks) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(250, 210, 530, 610),
            const Radius.circular(62),
          ),
          white,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(250, 210, 65, 610),
            const Radius.circular(22),
          ),
          blue,
        );
        final pen = Paint()
          ..color = const Color(0xFF3E6D8C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 40
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        canvas.drawPath(
          Path()
            ..moveTo(400, 478)
            ..lineTo(485, 564)
            ..lineTo(648, 390),
          pen,
        );
        canvas.drawLine(
          const Offset(410, 675),
          const Offset(650, 675),
          Paint()
            ..color = const Color(0xFF17191B)
            ..strokeWidth = 20
            ..strokeCap = StrokeCap.round,
        );
      } else {
        canvas.drawCircle(const Offset(512, 512), 160, blue);
        final rays = Paint()
          ..color = const Color(0xFF17191B)
          ..strokeWidth = 38
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          canvas.drawLine(
            Offset(512 + 240 * math.cos(a), 512 + 240 * math.sin(a)),
            Offset(512 + 320 * math.cos(a), 512 + 320 * math.sin(a)),
            rays,
          );
        }
      }
      final picture = recorder.endRecording();
      final image = await picture.toImage(output.value, output.value);
      final data = await image.toByteData(format: ImageByteFormat.png);
      await File(output.key).writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
      picture.dispose();
    }
  }
}
