import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_app/features/analysis/data/mel_spectrogram.dart';

void main() {
  test('MelSpectrogram returns melBins by exact frame count output', () {
    final mel = MelSpectrogram.compute(
      samples: List<double>.filled(4096, 0.1),
      sampleRate: 16000,
      fftSize: 1024,
      hopLength: 256,
      melBins: 64,
      minFreq: 20,
      maxFreq: 8000,
    );

    expect(mel, hasLength(64));
    for (final row in mel) {
      expect(row, hasLength(13));
      expect(row.every((value) => value.isFinite), isTrue);
    }
  });

  test('MelSpectrogram zero pads short clips to one frame', () {
    final mel = MelSpectrogram.compute(
      samples: List<double>.filled(400, 0.1),
      sampleRate: 16000,
      fftSize: 1024,
      hopLength: 256,
      melBins: 64,
      minFreq: 20,
      maxFreq: 8000,
    );

    expect(mel, hasLength(64));
    for (final row in mel) {
      expect(row, hasLength(1));
      expect(row.single.isFinite, isTrue);
    }
  });
}
