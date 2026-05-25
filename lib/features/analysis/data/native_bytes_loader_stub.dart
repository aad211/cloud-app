import 'dart:typed_data';

Future<Uint8List> loadNativeBytes(String path) {
  throw UnsupportedError('Native file access is not available on web.');
}
