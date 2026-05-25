import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web blob loader converts the blob URL to JS before fetch', () {
    final source =
        File(
          'lib/features/analysis/data/blob_bytes_loader_web.dart',
        ).readAsStringSync();

    expect(RegExp(r'fetch\(\s*blobUrl\.toJS\s*\)').hasMatch(source), isTrue);
  });
}
