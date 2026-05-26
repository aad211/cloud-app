import 'dart:typed_data';

Future<String> getApplicationDocumentsDirectoryPath() {
  throw UnsupportedError('Native documents storage is not available on web.');
}

Future<String?> resolveRepoRootDirectoryPath() async => null;

Future<void> writeBytesToFile(String path, Uint8List bytes) {
  throw UnsupportedError('Native file writes are not available on web.');
}

String joinPath(List<String> segments) => _joinPath(segments, '/');

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
