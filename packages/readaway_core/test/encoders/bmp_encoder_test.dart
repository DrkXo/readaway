import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:readaway_core/src/readers/pdf/bmp_encoder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('encodeBgraToBmp encodes raw BGRA pixels and decodes via ui.instantiateImageCodec', () async {
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

    final bmpBytes = encodeBgraToBmp(bgraPixels, width: width, height: height);

    expect(bmpBytes.length, equals(54 + width * height * 4));
    expect(bmpBytes[0], equals(0x42)); // 'B'
    expect(bmpBytes[1], equals(0x4D)); // 'M'

    // Decode with Flutter's image codec
    final buffer = await ui.ImmutableBuffer.fromUint8List(bmpBytes);
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
