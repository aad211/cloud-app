import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ohok_flutter/features/analysis/data/audio_capture_service.dart';
import 'package:ohok_flutter/features/analysis/domain/recorded_cough.dart';

void main() {
  test('stop returns a native-file recording with bytes', () async {
    final wavBytes = Uint8List.fromList(const [82, 73, 70, 70]);
    final service = AudioCaptureService(
      isWeb: false,
      hasPermissionCallback: () async => true,
      startCallback: ({required String? path}) async {},
      stopCallback: () async => '/tmp/recording.wav',
      readNativeBytes: (_) async => wavBytes,
      readBlobBytes: (_) async {
        fail('blob bytes should not be requested in the native test');
      },
    );

    final result = await service.stopRecording();

    expect(result, isNotNull);
    expect(result!.backend, RecordedCoughBackend.nativeFile);
    expect(result.reference, '/tmp/recording.wav');
    expect(result.wavBytes, wavBytes);
  });

  test('stop returns a web-blob recording with bytes', () async {
    final wavBytes = Uint8List.fromList(const [82, 73, 70, 70, 1, 2, 3, 4]);
    final service = AudioCaptureService(
      isWeb: true,
      hasPermissionCallback: () async => true,
      startCallback: ({required String? path}) async {},
      stopCallback: () async => 'blob:http://localhost/cough',
      readNativeBytes: (_) async {
        fail('native bytes should not be requested in the web test');
      },
      readBlobBytes: (_) async => wavBytes,
    );

    final result = await service.stopRecording();

    expect(result, isNotNull);
    expect(result!.backend, RecordedCoughBackend.webBlob);
    expect(result.reference, 'blob:http://localhost/cough');
    expect(result.wavBytes, wavBytes);
  });
}
