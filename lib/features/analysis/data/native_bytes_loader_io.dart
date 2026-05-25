import 'dart:io';
import 'dart:typed_data';

Future<Uint8List> loadNativeBytes(String path) {
  return File(path).readAsBytes();
}
