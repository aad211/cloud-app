import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<Uint8List> loadNativeBytes(String path) {
  throw UnsupportedError('Native file access is not available on web.');
}

Future<Uint8List> loadBlobBytes(String blobUrl) async {
  final response = await web.window.fetch(blobUrl).toDart;
  final buffer = await response.arrayBuffer().toDart;
  return Uint8List.view(buffer.toDart);
}
