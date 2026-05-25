import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohok_flutter/features/analysis/presentation/check_symptoms_controller.dart';

void main() {
  test('toggleMockRecording ignores non-idle button states', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(checkSymptomsControllerProvider.notifier);
    notifier.state = notifier.state.copyWith(
      buttonState: AnalysisButtonState.success,
    );

    notifier.toggleMockRecording();

    expect(notifier.state.buttonState, AnalysisButtonState.success);
    expect(notifier.state.isRecording, isFalse);
    expect(notifier.state.recordingTime, 0);
    expect(notifier.state.hasRecording, isFalse);
  });
}
