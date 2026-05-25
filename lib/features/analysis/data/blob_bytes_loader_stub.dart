import 'dart:io';
import 'dart:typed_data';

Future<Uint8List> loadNativeBytes(String path) {
  return File(path).readAsBytes();
}

Future<Uint8List> loadBlobBytes(String blobUrl) {
  throw UnsupportedError('Blob URLs are only available on web.');
}
