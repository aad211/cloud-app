import 'dart:math';
import 'dart:typed_data';

class WavReader {
  static List<double> readMono16BitPcmBytes(Uint8List bytes) {
    if (bytes.length < 12) {
      return const [];
    }

    if (_chunkId(bytes, 0) != 'RIFF' || _chunkId(bytes, 8) != 'WAVE') {
      return const [];
    }

    final data = ByteData.sublistView(bytes);
    var channels = 0;
    var blockAlign = 0;
    var bitsPerSample = 0;
    var formatCode = 0;
    var offset = 12;
    var hasFormatChunk = false;
    int? dataOffset;
    var dataLength = 0;

    while (offset + 8 <= bytes.length) {
      final chunkId = _chunkId(bytes, offset);
      final chunkSize = data.getUint32(offset + 4, Endian.little);
      final chunkDataOffset = offset + 8;
      final chunkDataEnd = chunkDataOffset + chunkSize;

      if (chunkDataEnd > bytes.length) {
        break;
      }

      if (chunkId == 'fmt ' && chunkSize >= 16) {
        hasFormatChunk = true;
        formatCode = data.getUint16(chunkDataOffset, Endian.little);
        channels = data.getUint16(chunkDataOffset + 2, Endian.little);
        blockAlign = data.getUint16(chunkDataOffset + 12, Endian.little);
        bitsPerSample = data.getUint16(chunkDataOffset + 14, Endian.little);
      } else if (chunkId == 'data' && dataOffset == null) {
        dataOffset = chunkDataOffset;
        dataLength = chunkSize;
      }

      offset = chunkDataEnd + (chunkSize.isOdd ? 1 : 0);
    }

    if (dataOffset == null ||
        !hasFormatChunk ||
        channels <= 0 ||
        blockAlign <= 0) {
      return const [];
    }

    if (formatCode != 1) {
      throw UnsupportedError('Only PCM WAV is supported.');
    }

    if (bitsPerSample != 16) {
      throw UnsupportedError('Only 16-bit WAV is supported.');
    }

    if (blockAlign != channels * 2) {
      return const [];
    }

    final clampedDataLength = min(dataLength, bytes.length - dataOffset);
    final frameCount = clampedDataLength ~/ blockAlign;

    return List<double>.generate(frameCount, (frameIndex) {
      final frameOffset = dataOffset! + frameIndex * blockAlign;
      var monoSample = 0.0;

      for (var channel = 0; channel < channels; channel += 1) {
        final sampleOffset = frameOffset + channel * 2;
        monoSample += data.getInt16(sampleOffset, Endian.little) / 32768.0;
      }

      return monoSample / channels;
    });
  }

  static String _chunkId(Uint8List bytes, int offset) {
    return String.fromCharCodes(bytes.sublist(offset, offset + 4));
  }
}
