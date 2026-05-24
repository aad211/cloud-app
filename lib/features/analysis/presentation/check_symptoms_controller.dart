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

  final Ref ref;
  final MockAnalysisRepository _repository;

  Future<void> startMockRecording() async {
    state = state.copyWith(isRecording: true, recordingTime: 0, errorMessage: '');
    for (var second = 1; second <= 10; second++) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      state = state.copyWith(recordingTime: second);
    }
    if (!mounted) return;
    state = state.copyWith(isRecording: false, recordingTime: 0, hasRecording: true);
  }

  Future<bool> analyze() async {
    if (state.isRecording || state.buttonState != AnalysisButtonState.idle) {
      return false;
    }
    if (!state.hasRecording) {
      state = state.copyWith(errorMessage: 'Please record your cough first');
      return false;
    }

    state = state.copyWith(errorMessage: '', buttonState: AnalysisButtonState.loading);
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return false;
    final record = _repository.buildRecord();
    await ref.read(analysisHistoryProvider.notifier).addRecord(record);
    if (!mounted) return false;
    state = state.copyWith(buttonState: AnalysisButtonState.success);
    return true;
  }
}

final checkSymptomsControllerProvider =
    StateNotifierProvider.autoDispose<CheckSymptomsController, CheckSymptomsState>(
  CheckSymptomsController.new,
);
