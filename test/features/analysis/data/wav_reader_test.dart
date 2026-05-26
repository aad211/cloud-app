import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ohok_flutter/features/analysis/data/wav_reader.dart';

Uint8List _le16(int value) {
  final data = ByteData(2)..setInt16(0, value, Endian.little);
  return data.buffer.asUint8List();
}

Uint8List _le32(int value) {
  final data = ByteData(4)..setUint32(0, value, Endian.little);
  return data.buffer.asUint8List();
}

Uint8List _buildTestWav({
  required List<int> samples,
  int channels = 1,
  int? blockAlign,
  int formatCode = 1,
  int bitsPerSample = 16,
  bool dataBeforeFormat = false,
  List<_Chunk> extraChunks = const [],
}) {
  final sampleBytes = BytesBuilder();
  for (final sample in samples) {
    sampleBytes.add(_le16(sample));
  }

  final dataChunk = _Chunk('data', sampleBytes.toBytes());
  final riffBody = BytesBuilder();
  riffBody.add('WAVE'.codeUnits);
  final formatChunk = _Chunk(
    'fmt ',
    Uint8List.fromList([
      ..._le16(formatCode),
      ..._le16(channels),
      ..._le32(16000),
      ..._le32(16000 * (blockAlign ?? channels * 2)),
      ..._le16(blockAlign ?? channels * 2),
      ..._le16(bitsPerSample),
    ]),
  );

  final chunks =
      dataBeforeFormat
          ? [...extraChunks, dataChunk, formatChunk]
          : [...extraChunks, formatChunk, dataChunk];

  for (final chunk in chunks) {
    riffBody.add(chunk.id.codeUnits);
    riffBody.add(_le32(chunk.payload.length));
    riffBody.add(chunk.payload);
    if (chunk.payload.length.isOdd) {
      riffBody.add(const [0]);
    }
  }

  final riffBytes = riffBody.toBytes();
  final bytes = BytesBuilder();
  bytes.add('RIFF'.codeUnits);
  bytes.add(_le32(riffBytes.length));
  bytes.add(riffBytes);
  return bytes.toBytes();
}

class _Chunk {
  const _Chunk(this.id, this.payload);

  final String id;
  final Uint8List payload;
}

void main() {
  test('WavReader skips padded chunks before PCM data', () {
    final wavBytes = _buildTestWav(
      samples: const [0, 32767, -32768, 0],
      extraChunks: [
        _Chunk('JUNK', Uint8List.fromList([1])),
      ],
    );

    final samples = WavReader.readMono16BitPcmBytes(wavBytes);

    expect(samples, hasLength(4));
    expect(samples[0], 0);
    expect(samples[1], closeTo(32767 / 32768, 0.0001));
    expect(samples[2], -1);
    expect(samples[3], 0);
  });

  test('WavReader rejects malformed block alignment metadata', () {
    final wavBytes = _buildTestWav(
      samples: const [0, 32767, -32768, 0],
      channels: 1,
      blockAlign: 4,
    );

    final samples = WavReader.readMono16BitPcmBytes(wavBytes);

    expect(samples, isEmpty);
  });

  test('WavReader downmixes stereo PCM input to mono', () {
    final wavBytes = _buildTestWav(
      samples: const [32767, -32768, 16384, 16384],
      channels: 2,
    );

    final samples = WavReader.readMono16BitPcmBytes(wavBytes);

    expect(samples, hasLength(2));
    expect(samples[0], closeTo((-1 / 32768), 0.0001));
    expect(samples[1], closeTo(0.5, 0.0001));
  });

  test(
    'WavReader still reads format metadata when data chunk appears first',
    () {
      final wavBytes = _buildTestWav(
        samples: const [0, 32767, -32768, 0],
        dataBeforeFormat: true,
      );

      final samples = WavReader.readMono16BitPcmBytes(wavBytes);

      expect(samples, hasLength(4));
      expect(samples[0], 0);
      expect(samples[1], closeTo(32767 / 32768, 0.0001));
      expect(samples[2], -1);
      expect(samples[3], 0);
    },
  );

  test('WavReader throws for non-PCM WAV data', () {
    final wavBytes = _buildTestWav(samples: const [0, 32767], formatCode: 3);

    expect(
      () => WavReader.readMono16BitPcmBytes(wavBytes),
      throwsA(isA<UnsupportedError>()),
    );
  });

  test('WavReader throws for non-16-bit WAV data', () {
    final wavBytes = _buildTestWav(
      samples: const [0, 32767],
      bitsPerSample: 24,
      blockAlign: 3,
    );

    expect(
      () => WavReader.readMono16BitPcmBytes(wavBytes),
      throwsA(isA<UnsupportedError>()),
    );
  });
}
