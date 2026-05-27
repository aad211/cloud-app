import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_app/features/analysis/data/audio_playback_service.dart';
import 'package:cloud_app/features/analysis/data/audio_capture_service.dart';
import 'package:cloud_app/features/analysis/data/cough_analysis_service.dart';
import 'package:cloud_app/features/analysis/domain/recorded_cough.dart';
import 'package:cloud_app/features/analysis/presentation/analysis_history_controller.dart';
import 'package:cloud_app/features/analysis/presentation/latest_analysis_provider.dart';

enum AnalysisButtonState { idle, loading, success }

enum DebugInferenceStatus { idle, loading, success, error }

class CheckSymptomsState {
  static const _noChange = Object();

  const CheckSymptomsState({
    this.isRecording = false,
    this.recordingTime = 0,
    this.hasRecording = false,
    this.errorMessage = '',
    this.buttonState = AnalysisButtonState.idle,
    this.isDebugPanelOpen = false,
    this.debugStatus = DebugInferenceStatus.idle,
    this.debugLogs = const [],
    this.debugErrorMessage = '',
    this.isDebugPlaybackActive = false,
    this.debugResult,
  });

  final bool isRecording;
  final int recordingTime;
  final bool hasRecording;
  final String errorMessage;
  final AnalysisButtonState buttonState;
  final bool isDebugPanelOpen;
  final DebugInferenceStatus debugStatus;
  final List<String> debugLogs;
  final String debugErrorMessage;
  final bool isDebugPlaybackActive;
  final DebugAnalysisResult? debugResult;

  CheckSymptomsState copyWith({
    bool? isRecording,
    int? recordingTime,
    bool? hasRecording,
    String? errorMessage,
    AnalysisButtonState? buttonState,
    bool? isDebugPanelOpen,
    DebugInferenceStatus? debugStatus,
    List<String>? debugLogs,
    String? debugErrorMessage,
    bool? isDebugPlaybackActive,
    Object? debugResult = _noChange,
  }) {
    return CheckSymptomsState(
      isRecording: isRecording ?? this.isRecording,
      recordingTime: recordingTime ?? this.recordingTime,
      hasRecording: hasRecording ?? this.hasRecording,
      errorMessage: errorMessage ?? this.errorMessage,
      buttonState: buttonState ?? this.buttonState,
      isDebugPanelOpen: isDebugPanelOpen ?? this.isDebugPanelOpen,
      debugStatus: debugStatus ?? this.debugStatus,
      debugLogs: debugLogs ?? this.debugLogs,
      debugErrorMessage: debugErrorMessage ?? this.debugErrorMessage,
      isDebugPlaybackActive:
          isDebugPlaybackActive ?? this.isDebugPlaybackActive,
      debugResult:
          identical(debugResult, _noChange)
              ? this.debugResult
              : debugResult as DebugAnalysisResult?,
    );
  }
}

class CheckSymptomsController extends StateNotifier<CheckSymptomsState> {
  CheckSymptomsController(this.ref) : super(const CheckSymptomsState());

  static const _missingRecordingError = '⚠️ Please record your cough first';
  static const _permissionDeniedError =
      'Microphone permission is required to record your cough.';
  static const _recordingFailedError =
      'Failed to capture audio. Please try again.';
  static const _analysisSetupError =
      'Analysis setup is incomplete. Add the real model and labels before running analysis.';
  static const _invalidRecordingInputError =
      'Recorded cough audio is invalid. Please try recording again.';
  static const _analysisFailedError =
      'Failed to analyze cough. Please try again.';

  final Ref ref;
  Timer? _recordingTimer;
  Timer? _errorTimer;
  RecordedCough? _recordedCough;

  Future<void> toggleRecording() async {
    if (state.buttonState != AnalysisButtonState.idle) {
      return;
    }

    _clearMissingRecordingError();

    if (state.isRecording) {
      await _completeRecording();
      return;
    }

    _recordedCough = null;
    final audioCaptureService = ref.read(audioCaptureServiceProvider);
    final hasPermission = await audioCaptureService.hasPermission();
    if (!mounted || !hasPermission) {
      if (mounted) {
        state = state.copyWith(
          isRecording: false,
          recordingTime: 0,
          hasRecording: false,
          errorMessage: _permissionDeniedError,
          debugResult: null,
          debugLogs: const [],
          debugErrorMessage: '',
          debugStatus: DebugInferenceStatus.idle,
          isDebugPlaybackActive: false,
        );
      }
      return;
    }

    try {
      await audioCaptureService.startRecording();
    } catch (e, st) {
      _reportControllerError(
        error: e,
        stackTrace: st,
        context: 'Failed to start cough recording.',
      );
      if (!mounted) {
        return;
      }
      state = state.copyWith(
        isRecording: false,
        recordingTime: 0,
        hasRecording: false,
        errorMessage: _recordingFailedError,
        debugResult: null,
        debugLogs: const [],
        debugErrorMessage: '',
        debugStatus: DebugInferenceStatus.idle,
        isDebugPlaybackActive: false,
      );
      return;
    }

    _recordingTimer?.cancel();
    state = state.copyWith(
      isRecording: true,
      recordingTime: 0,
      hasRecording: false,
      errorMessage: '',
      debugResult: null,
      debugLogs: const [],
      debugErrorMessage: '',
      debugStatus: DebugInferenceStatus.idle,
      isDebugPlaybackActive: false,
    );

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final nextSecond = state.recordingTime + 1;
      if (nextSecond >= 10) {
        await _completeRecording();
        return;
      }

      state = state.copyWith(recordingTime: nextSecond);
    });
  }

  void toggleMockRecording() {
    unawaited(toggleRecording());
  }

  void toggleDebugPanel() {
    if (!kDebugMode) {
      return;
    }
    state = state.copyWith(isDebugPanelOpen: !state.isDebugPanelOpen);
  }

  Future<void> runDebugInference() async {
    if (!kDebugMode || state.isRecording) {
      return;
    }
    final recordedCough = _recordedCough;
    if (!state.hasRecording || recordedCough == null) {
      state = state.copyWith(
        debugStatus: DebugInferenceStatus.error,
        debugErrorMessage: _missingRecordingError,
        debugLogs: const ['Record cough first before running debug inference.'],
      );
      return;
    }

    state = state.copyWith(
      debugStatus: DebugInferenceStatus.loading,
      debugErrorMessage: '',
      debugLogs: const ['Starting debug inference...'],
    );

    try {
      final debugResult = await ref
          .read(coughAnalysisServiceProvider)
          .buildDebugAnalysis(recordedCough);
      final topIndex =
          debugResult.rawScores.indexed.reduce((best, current) {
            return current.$2 > best.$2 ? current : best;
          }).$1;
      final topLabel = debugResult.labels[topIndex];
      final topScore = debugResult.rawScores[topIndex];

      final logs = <String>[
        ...state.debugLogs,
        'Decoded ${debugResult.wavSampleCount} WAV samples',
        'Mel shape: ${debugResult.melSpectrogram.length} x '
            '${debugResult.melSpectrogram.isEmpty ? 0 : debugResult.melSpectrogram.first.length}',
        'Model shape: ${debugResult.modelHeight} x ${debugResult.modelWidth} x ${debugResult.modelChannels}',
        for (final entry in debugResult.stageDurationsMs.entries)
          '${entry.key}: ${entry.value} ms',
        'Top prediction: $topLabel (${(topScore * 100).toStringAsFixed(2)}%)',
      ];

      state = state.copyWith(
        debugStatus: DebugInferenceStatus.success,
        debugResult: debugResult,
        debugLogs: logs,
        debugErrorMessage: '',
      );
    } catch (error, stackTrace) {
      _reportControllerError(
        error: error,
        stackTrace: stackTrace,
        context: 'Failed to run debug inference.',
      );
      state = state.copyWith(
        debugStatus: DebugInferenceStatus.error,
        debugErrorMessage: error.toString(),
        debugLogs: [...state.debugLogs, 'Debug inference failed.'],
      );
    }
  }

  Future<void> playLatestRecording() async {
    await toggleDebugPlayback();
  }

  Future<void> toggleDebugPlayback() async {
    if (!kDebugMode) {
      return;
    }
    final recordedCough = _recordedCough;
    if (!state.hasRecording || recordedCough == null) {
      state = state.copyWith(
        debugStatus: DebugInferenceStatus.error,
        debugErrorMessage: _missingRecordingError,
        debugLogs: const ['Record cough first before playback.'],
        isDebugPlaybackActive: false,
      );
      return;
    }
    try {
      final playback = ref.read(audioPlaybackServiceProvider);
      if (state.isDebugPlaybackActive) {
        await playback.pause();
        state = state.copyWith(
          debugLogs: [...state.debugLogs, 'Playback paused.'],
          isDebugPlaybackActive: false,
        );
        return;
      }
      await playback.play(recordedCough);
      state = state.copyWith(
        debugLogs: [
          ...state.debugLogs,
          'Playback started for latest recording.',
        ],
        isDebugPlaybackActive: true,
      );
    } catch (error, stackTrace) {
      _reportControllerError(
        error: error,
        stackTrace: stackTrace,
        context: 'Failed to play recorded cough.',
      );
      state = state.copyWith(
        debugStatus: DebugInferenceStatus.error,
        debugErrorMessage: 'Playback failed: $error',
        debugLogs: [...state.debugLogs, 'Playback failed.'],
        isDebugPlaybackActive: false,
      );
    }
  }

  Future<bool> analyze() async {
    if (state.isRecording || state.buttonState != AnalysisButtonState.idle) {
      return false;
    }

    final recordedCough = _recordedCough;
    if (!state.hasRecording || recordedCough == null) {
      _showMissingRecordingError();
      return false;
    }

    _clearMissingRecordingError();
    state = state.copyWith(
      errorMessage: '',
      buttonState: AnalysisButtonState.loading,
    );

    try {
      final record = await ref
          .read(coughAnalysisServiceProvider)
          .analyze(recordedCough);
      await ref.read(analysisHistoryProvider.notifier).addRecord(record);
      ref.read(latestAnalysisProvider.notifier).state = record;
    } catch (e, st) {
      _reportControllerError(
        error: e,
        stackTrace: st,
        context: 'Failed to analyze or persist cough result.',
      );
      if (!mounted) {
        return false;
      }
      state = state.copyWith(
        buttonState: AnalysisButtonState.idle,
        errorMessage: _errorMessageFor(e),
      );
      return false;
    }
    if (!mounted) {
      return false;
    }
    state = state.copyWith(buttonState: AnalysisButtonState.success);
    return true;
  }

  Future<void> _completeRecording() async {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    try {
      final recordedCough =
          await ref.read(audioCaptureServiceProvider).stopRecording();
      if (!mounted) {
        return;
      }
      _recordedCough = recordedCough;
      state = state.copyWith(
        isRecording: false,
        recordingTime: 0,
        hasRecording: recordedCough != null,
        errorMessage:
            recordedCough == null ? _recordingFailedError : state.errorMessage,
        debugResult: null,
        debugLogs: const [],
        debugErrorMessage: '',
        debugStatus: DebugInferenceStatus.idle,
        isDebugPlaybackActive: false,
      );
    } catch (e, st) {
      _reportControllerError(
        error: e,
        stackTrace: st,
        context: 'Failed to stop cough recording.',
      );
      if (!mounted) {
        return;
      }
      _recordedCough = null;
      state = state.copyWith(
        isRecording: false,
        recordingTime: 0,
        hasRecording: false,
        errorMessage: _recordingFailedError,
        debugResult: null,
        debugLogs: const [],
        debugErrorMessage: '',
        debugStatus: DebugInferenceStatus.idle,
        isDebugPlaybackActive: false,
      );
    }
  }

  void _showMissingRecordingError() {
    _errorTimer?.cancel();
    state = state.copyWith(errorMessage: _missingRecordingError);
    _errorTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      state = state.copyWith(errorMessage: '');
    });
  }

  void _clearMissingRecordingError() {
    _errorTimer?.cancel();
    _errorTimer = null;
    if (state.errorMessage == _missingRecordingError) {
      state = state.copyWith(errorMessage: '');
    }
  }

  String _errorMessageFor(Object error) {
    if (error is StateError) {
      final message = error.message;
      if (_isAnalysisSetupFailure(message)) {
        return _analysisSetupError;
      }
      if (message.contains('valid 16-bit PCM WAV samples')) {
        return _invalidRecordingInputError;
      }
    }
    return _analysisFailedError;
  }

  bool _isAnalysisSetupFailure(String message) {
    return message.contains('labels.txt') ||
        message.contains('cloud.tflite') ||
        message.contains('TensorFlow.js') ||
        message.contains('tf-tflite.min.js');
  }

  void _reportControllerError({
    required Object error,
    required StackTrace stackTrace,
    required String context,
  }) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'check_symptoms_controller',
        context: ErrorDescription(context),
      ),
    );
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _errorTimer?.cancel();
    super.dispose();
  }
}

final checkSymptomsControllerProvider = StateNotifierProvider.autoDispose<
  CheckSymptomsController,
  CheckSymptomsState
>(CheckSymptomsController.new);
