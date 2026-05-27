import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_app/features/analysis/domain/recorded_cough.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'blob_bytes_loader_stub.dart'
    if (dart.library.js_interop) 'blob_bytes_loader_web.dart';

class AudioCaptureService {
  AudioCaptureService({
    bool? isWeb,
    Future<bool> Function()? hasPermissionCallback,
    Future<void> Function({required String? path})? startCallback,
    Future<String?> Function()? stopCallback,
    Future<Uint8List> Function(String path)? readNativeBytes,
    Future<Uint8List> Function(String blobUrl)? readBlobBytes,
  }) : _isWeb = isWeb ?? kIsWeb,
       _hasPermission = hasPermissionCallback,
       _start = startCallback,
       _stop = stopCallback,
       _readNativeBytes = readNativeBytes,
       _readBlobBytes = readBlobBytes;

  final bool _isWeb;
  final Future<bool> Function()? _hasPermission;
  final Future<void> Function({required String? path})? _start;
  final Future<String?> Function()? _stop;
  final Future<Uint8List> Function(String path)? _readNativeBytes;
  final Future<Uint8List> Function(String blobUrl)? _readBlobBytes;
  AudioRecorder? _recorder;

  AudioRecorder get _audioRecorder => _recorder ??= AudioRecorder();

  Future<bool> hasPermission() async =>
      _hasPermission != null
          ? _hasPermission()
          : _audioRecorder.hasPermission();

  Future<void> startRecording() async {
    final path =
        _isWeb ? null : '${(await getTemporaryDirectory()).path}/recording.wav';
    if (_start != null) {
      await _start(path: path);
      return;
    }

    await _audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 128000,
      ),
      path: path ?? '',
    );
  }

  Future<RecordedCough?> stopRecording() async {
    final reference =
        _stop != null ? await _stop() : await _audioRecorder.stop();
    if (reference == null) {
      return null;
    }

    if (_isWeb) {
      final bytes = await (_readBlobBytes ?? loadBlobBytes)(reference);
      return RecordedCough(
        reference: reference,
        wavBytes: bytes,
        backend: RecordedCoughBackend.webBlob,
      );
    }

    final bytes = await (_readNativeBytes ?? loadNativeBytes)(reference);
    return RecordedCough(
      reference: reference,
      wavBytes: bytes,
      backend: RecordedCoughBackend.nativeFile,
    );
  }
}

final audioCaptureServiceProvider = Provider<AudioCaptureService>(
  (ref) => AudioCaptureService(),
);
