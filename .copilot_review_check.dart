import 'dart:typed_data';
import 'lib/features/analysis/data/wav_reader.dart';

Uint8List buildCanonical() {
  final bytes = BytesBuilder();
  bytes.add('RIFF'.codeUnits);
  bytes.add(Uint8List(4));
  bytes.add('WAVE'.codeUnits);
  bytes.add('fmt '.codeUnits);
  bytes.add(Uint8List.fromList(const [16, 0, 0, 0]));
  bytes.add(Uint8List.fromList(const [1, 0, 1, 0, 128, 62, 0, 0, 0, 125, 0, 0, 2, 0, 16, 0]));
  bytes.add('data'.codeUnits);
  bytes.add(Uint8List.fromList(const [4, 0, 0, 0]));
  bytes.add(Uint8List.fromList(const [0, 0, 255, 127]));
  return bytes.toBytes();
}

Uint8List buildOddChunk() {
  final bytes = BytesBuilder();
  bytes.add('RIFF'.codeUnits);
  bytes.add(Uint8List(4));
  bytes.add('WAVE'.codeUnits);
  bytes.add('fmt '.codeUnits);
  bytes.add(Uint8List.fromList(const [16, 0, 0, 0]));
  bytes.add(Uint8List.fromList(const [1, 0, 1, 0, 128, 62, 0, 0, 0, 125, 0, 0, 2, 0, 16, 0]));
  bytes.add('JUNK'.codeUnits);
  bytes.add(Uint8List.fromList(const [1, 0, 0, 0]));
  bytes.add(Uint8List.fromList(const [7, 0])); // 1 byte payload + 1 byte pad
  bytes.add('data'.codeUnits);
  bytes.add(Uint8List.fromList(const [4, 0, 0, 0]));
  bytes.add(Uint8List.fromList(const [0, 0, 255, 127]));
  return bytes.toBytes();
}

Uint8List buildTruncatedData() {
  final bytes = BytesBuilder();
  bytes.add(buildCanonical());
  final out = bytes.toBytes();
  out[40] = 8; // claim 8 bytes of PCM data but only 4 exist
  return out;
}

void main() {
  print('canonical len=${WavReader.readMono16BitPcmBytes(buildCanonical()).length}');
  print('odd chunk len=${WavReader.readMono16BitPcmBytes(buildOddChunk()).length}');
  try {
    print('truncated len=${WavReader.readMono16BitPcmBytes(buildTruncatedData()).length}');
  } catch (e) {
    print('truncated error=$e');
  }
}
