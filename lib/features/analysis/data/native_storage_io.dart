import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<String> getApplicationDocumentsDirectoryPath() async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}

Future<String?> resolveRepoRootDirectoryPath() async {
  var current = Directory.current.absolute;
  while (true) {
    if (await Directory(joinPath([current.path, '.git'])).exists()) {
      return current.path;
    }

    final parent = current.parent;
    if (parent.path == current.path) {
      return null;
    }
    current = parent;
  }
}

Future<void> writeBytesToFile(String path, Uint8List bytes) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes, flush: true);
}

String joinPath(List<String> segments) =>
    _joinPath(segments, Platform.pathSeparator);

String _joinPath(List<String> segments, String separator) {
  final normalizedSegments = <String>[];
  for (final segment in segments) {
    if (segment.isEmpty) {
      continue;
    }

    if (normalizedSegments.isEmpty) {
      normalizedSegments.add(_trimTrailingSeparators(segment, separator));
      continue;
    }

    normalizedSegments.add(_trimEdgeSeparators(segment, separator));
  }

  return normalizedSegments.join(separator);
}

String _trimTrailingSeparators(String value, String separator) {
  if (value == separator) {
    return value;
  }

  var trimmed = value;
  while (trimmed.endsWith(separator) && trimmed.length > separator.length) {
    trimmed = trimmed.substring(0, trimmed.length - separator.length);
  }
  return trimmed;
}

String _trimEdgeSeparators(String value, String separator) {
  var trimmed = value;
  while (trimmed.startsWith(separator)) {
    trimmed = trimmed.substring(separator.length);
  }
  return _trimTrailingSeparators(trimmed, separator);
}
