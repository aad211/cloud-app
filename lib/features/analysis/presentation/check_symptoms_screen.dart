import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_app/app/theme/app_colors.dart';
import 'package:cloud_app/core/widgets/parity_cards.dart';
import 'package:cloud_app/core/widgets/parity_page_header.dart';
import 'check_symptoms_controller.dart';

class CheckSymptomsScreen extends ConsumerWidget {
  const CheckSymptomsScreen({super.key});

  static const _waveformHeights = [
    22.0,
    36.0,
    28.0,
    44.0,
    30.0,
    40.0,
    26.0,
    34.0,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(checkSymptomsControllerProvider);
    final controller = ref.read(checkSymptomsControllerProvider.notifier);
    final canAnalyze =
        state.hasRecording &&
        !state.isRecording &&
        state.buttonState == AnalysisButtonState.idle;
    final recordButtonColor =
        state.isRecording
            ? AppColors.danger
            : state.hasRecording
            ? AppColors.success
            : AppColors.gold;
    final analyzeButtonColor = switch (state.buttonState) {
      AnalysisButtonState.idle => AppColors.navy,
      AnalysisButtonState.loading => AppColors.navy,
      AnalysisButtonState.success => AppColors.success,
    };

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ParityPageHeader(
                title: 'Check Symptoms',
                subtitle: 'Analyze your cough using AI',
                onBack: () => context.go('/home'),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 32,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            FilledButton(
                              onPressed:
                                  state.buttonState == AnalysisButtonState.idle
                                      ? () => controller.toggleRecording()
                                      : null,
                              style: FilledButton.styleFrom(
                                backgroundColor: recordButtonColor,
                                disabledBackgroundColor: recordButtonColor,
                                minimumSize: const Size(128, 128),
                                shape: const CircleBorder(),
                                padding: EdgeInsets.zero,
                                elevation: 0,
                              ),
                              child: Icon(
                                state.isRecording
                                    ? Icons.stop_rounded
                                    : Icons.mic_rounded,
                                color:
                                    state.hasRecording || state.isRecording
                                        ? Colors.white
                                        : AppColors.navy,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (state.isRecording) ...[
                              const Text(
                                'Recording...',
                                style: TextStyle(
                                  color: AppColors.navy,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '00:${state.recordingTime.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  color: AppColors.danger,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 48,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    for (final height in _waveformHeights) ...[
                                      Container(
                                        width: 6,
                                        height: height,
                                        decoration: BoxDecoration(
                                          color: AppColors.danger,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                      ),
                                      if (height != _waveformHeights.last)
                                        const SizedBox(width: 6),
                                    ],
                                  ],
                                ),
                              ),
                            ] else ...[
                              Text(
                                state.hasRecording
                                    ? 'Cough recorded ✓'
                                    : 'Tap to record your cough',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.navy,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                state.hasRecording
                                    ? 'Click analyze to continue'
                                    : 'Record for 5–10 seconds',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.blue,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ParityInfoCard(
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: AppColors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.info_outline_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'This tool analyzes cough patterns using AI classification',
                              style: TextStyle(
                                color: AppColors.navy,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '⚠️ Not a medical diagnosis',
                              style: TextStyle(
                                color: AppColors.blue,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (kDebugMode) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            onPressed: controller.toggleDebugPanel,
                            icon: const Icon(
                              Icons.bug_report_outlined,
                              size: 16,
                            ),
                            label: Text(
                              state.isDebugPanelOpen
                                  ? 'Hide Debug'
                                  : 'Show Debug',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.navy,
                              side: const BorderSide(color: AppColors.sand),
                            ),
                          ),
                        ),
                        if (state.isDebugPanelOpen) ...[
                          const SizedBox(height: 12),
                          _DebugPanel(state: state, controller: controller),
                        ],
                      ],
                      if (state.errorMessage.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            state.errorMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.critical,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: FilledButton(
                  onPressed:
                      canAnalyze
                          ? () async {
                            final success = await controller.analyze();
                            if (!context.mounted || !success) {
                              return;
                            }
                            await Future<void>.delayed(
                              const Duration(seconds: 1),
                            );
                            if (context.mounted) {
                              context.push('/result');
                            }
                          }
                          : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: analyzeButtonColor,
                    disabledBackgroundColor: AppColors.muted,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (state.buttonState == AnalysisButtonState.idle)
                          const Icon(Icons.psychology_alt_rounded, size: 18)
                        else if (state.buttonState ==
                            AnalysisButtonState.loading)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else
                          const Icon(Icons.check_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(switch (state.buttonState) {
                          AnalysisButtonState.idle => 'Analyze Now',
                          AnalysisButtonState.loading => 'Analyzing...',
                          AnalysisButtonState.success => 'Analysis Complete ✓',
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DebugPanel extends StatelessWidget {
  const _DebugPanel({required this.state, required this.controller});

  final CheckSymptomsState state;
  final CheckSymptomsController controller;

  @override
  Widget build(BuildContext context) {
    final result = state.debugResult;
    final canRun = state.hasRecording && !state.isRecording;
    final isBusy = state.debugStatus == DebugInferenceStatus.loading;
    final isPlaybackActive = state.isDebugPlaybackActive;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sand, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Debug Inference',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: canRun ? controller.toggleDebugPlayback : null,
                  icon: Icon(
                    isPlaybackActive
                        ? Icons.pause_circle_outline_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  label: Text(
                    isPlaybackActive ? 'Pause Playback' : 'Play Recording',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed:
                      canRun && !isBusy ? controller.runDebugInference : null,
                  icon:
                      isBusy
                          ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(Icons.science_outlined),
                  label: const Text('Run Debug Inference'),
                ),
              ),
            ],
          ),
          if (!canRun) ...[
            const SizedBox(height: 8),
            const Text(
              'Record cough first to enable debugging actions.',
              style: TextStyle(color: AppColors.blue, fontSize: 12),
            ),
          ],
          if (result != null) ...[
            const SizedBox(height: 12),
            const Text(
              'Mel Spectrogram',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            _PreviewImage(bytes: result.melPreviewPngBytes),
            const SizedBox(height: 10),
            Text(
              'Model Input (${result.modelHeight} x ${result.modelWidth} x ${result.modelChannels})',
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            _PreviewImage(bytes: result.preparedInputPreviewPngBytes),
          ],
          const SizedBox(height: 12),
          Text(
            'Status: ${switch (state.debugStatus) {
              DebugInferenceStatus.idle => 'Idle',
              DebugInferenceStatus.loading => 'Running',
              DebugInferenceStatus.success => 'Success',
              DebugInferenceStatus.error => 'Error',
            }}',
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (state.debugErrorMessage.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              state.debugErrorMessage,
              style: const TextStyle(
                color: AppColors.critical,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (state.debugLogs.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.sand),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final line in state.debugLogs)
                    Text(
                      '- $line',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviewImage extends StatelessWidget {
  const _PreviewImage({required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        color: Colors.black,
        width: double.infinity,
        height: 120,
        child:
            bytes.isEmpty
                ? const Center(
                  child: Text(
                    'No preview',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                )
                : Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true),
      ),
    );
  }
}
