import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cloud_app/features/analysis/domain/recorded_cough.dart';

abstract class AudioPlaybackService {
  Future<void> play(RecordedCough cough);
  Future<void> pause();
  Future<void> stop();
}

class AudioplayersAudioPlaybackService implements AudioPlaybackService {
  AudioplayersAudioPlaybackService({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Future<void> play(RecordedCough cough) async {
    switch (cough.backend) {
      case RecordedCoughBackend.nativeFile:
        await _player.play(DeviceFileSource(cough.reference));
      case RecordedCoughBackend.webBlob:
        await _player.play(UrlSource(cough.reference));
    }
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();
}

final audioPlaybackServiceProvider = Provider<AudioPlaybackService>((ref) {
  return AudioplayersAudioPlaybackService();
});
