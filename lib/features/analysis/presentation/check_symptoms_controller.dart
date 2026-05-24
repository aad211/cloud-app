import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ohok_flutter/features/analysis/data/mock_analysis_repository.dart';
import 'package:ohok_flutter/features/analysis/presentation/analysis_history_controller.dart';

enum AnalysisButtonState { idle, loading, success }

class CheckSymptomsState {
  const CheckSymptomsState({
    this.isRecording = false,
    this.recordingTime = 0,
    this.hasRecording = false,
    this.errorMessage = '',
    this.buttonState = AnalysisButtonState.idle,
  });

  final bool isRecording;
  final int recordingTime;
  final bool hasRecording;
  final String errorMessage;
  final AnalysisButtonState buttonState;

  CheckSymptomsState copyWith({
    bool? isRecording,
    int? recordingTime,
    bool? hasRecording,
    String? errorMessage,
    AnalysisButtonState? buttonState,
  }) {
    return CheckSymptomsState(
      isRecording: isRecording ?? this.isRecording,
      recordingTime: recordingTime ?? this.recordingTime,
      hasRecording: hasRecording ?? this.hasRecording,
      errorMessage: errorMessage ?? this.errorMessage,
      buttonState: buttonState ?? this.buttonState,
    );
  }
}

class CheckSymptomsController extends StateNotifier<CheckSymptomsState> {
  CheckSymptomsController(this.ref)
      : _repository = const MockAnalysisRepository(),
        super(const CheckSymptomsState());

  static const _missingRecordingError = '⚠️ Please record your cough first';

  final Ref ref;
  final MockAnalysisRepository _repository;
  Timer? _recordingTimer;
  Timer? _errorTimer;

  void toggleMockRecording() {
    _clearMissingRecordingError();

    if (state.isRecording) {
      _completeRecording();
      return;
    }

    _recordingTimer?.cancel();
    state = state.copyWith(
      isRecording: true,
      recordingTime: 0,
      errorMessage: '',
    );

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final nextSecond = state.recordingTime + 1;
      if (nextSecond >= 10) {
        _completeRecording();
        return;
      }

      state = state.copyWith(recordingTime: nextSecond);
    });
  }

  Future<bool> analyze() async {
    if (state.isRecording || state.buttonState != AnalysisButtonState.idle) {
      return false;
    }
    if (!state.hasRecording) {
      _showMissingRecordingError();
      return false;
    }

    _clearMissingRecordingError();
    state = state.copyWith(errorMessage: '', buttonState: AnalysisButtonState.loading);
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return false;
    final record = _repository.buildRecord();
    try {
      await ref.read(analysisHistoryProvider.notifier).addRecord(record);
    } catch (e, st) {
      if (!mounted) return false;
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: e,
          stack: st,
          library: 'check_symptoms_controller',
          context: ErrorDescription('Failed to persist analysis result.'),
        ),
      );
      state = state.copyWith(
        buttonState: AnalysisButtonState.idle,
        errorMessage: 'Failed to save analysis. Please try again.',
      );
      return false;
    }
    if (!mounted) return false;
    state = state.copyWith(buttonState: AnalysisButtonState.success);
    return true;
  }

  void _completeRecording() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    if (!mounted) return;
    state = state.copyWith(
      isRecording: false,
      recordingTime: 0,
      hasRecording: true,
    );
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

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _errorTimer?.cancel();
    super.dispose();
  }
}

final checkSymptomsControllerProvider =
    StateNotifierProvider.autoDispose<CheckSymptomsController, CheckSymptomsState>(
  CheckSymptomsController.new,
);
