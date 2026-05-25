import 'dart:typed_data';

enum RecordedCoughBackend { nativeFile, webBlob }

class RecordedCough {
  const RecordedCough({
    required this.reference,
    required this.wavBytes,
    required this.backend,
  });

  final String reference;
  final Uint8List wavBytes;
  final RecordedCoughBackend backend;
}
