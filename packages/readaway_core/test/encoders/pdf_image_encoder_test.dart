import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:readaway_core/readaway_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('encodeBgraToPng encodes raw BGRA pixels and decodes via ui.instantiateImageCodec', () async {
    const width = 100;
    const height = 100;
    final bgraPixels = Uint8List(width * height * 4);

    // Fill with semi-opaque red pixels: BGRA = (0, 0, 255, 255)
    for (var i = 0; i < bgraPixels.length; i += 4) {
      bgraPixels[i] = 0; // Blue
      bgraPixels[i + 1] = 0; // Green
      bgraPixels[i + 2] = 255; // Red
      bgraPixels[i + 3] = 255; // Alpha
    }

    final pngBytes = encodeBgraToPng(bgraPixels, width: width, height: height);

    // Validate PNG signature: 89 50 4E 47 0D 0A 1A 0A
    expect(pngBytes.length, greaterThan(8));
    expect(pngBytes[0], equals(0x89));
    expect(pngBytes[1], equals(0x50)); // 'P'
    expect(pngBytes[2], equals(0x4E)); // 'N'
    expect(pngBytes[3], equals(0x47)); // 'G'

    // Decode with Flutter's image codec
    final buffer = await ui.ImmutableBuffer.fromUint8List(pngBytes);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    expect(descriptor.width, equals(width));
    expect(descriptor.height, equals(height));

    final codec = await descriptor.instantiateCodec();
    final frame = await codec.getNextFrame();
    expect(frame.image.width, equals(width));
    expect(frame.image.height, equals(height));

    frame.image.dispose();
    codec.dispose();
    descriptor.dispose();
    buffer.dispose();
  });
}
