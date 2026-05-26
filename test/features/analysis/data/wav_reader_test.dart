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
  List<_Chunk> extraChunks = const [],
}) {
  final sampleBytes = BytesBuilder();
  for (final sample in samples) {
    sampleBytes.add(_le16(sample));
  }

  final dataChunk = _Chunk('data', sampleBytes.toBytes());
  final riffBody = BytesBuilder();
  riffBody.add('WAVE'.codeUnits);
  riffBody.add('fmt '.codeUnits);
  riffBody.add(_le32(16));
  riffBody.add(_le16(1));
  riffBody.add(_le16(channels));
  riffBody.add(_le32(16000));
  riffBody.add(_le32(16000 * (blockAlign ?? channels * 2)));
  riffBody.add(_le16(blockAlign ?? channels * 2));
  riffBody.add(_le16(16));

  for (final chunk in [...extraChunks, dataChunk]) {
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
}
