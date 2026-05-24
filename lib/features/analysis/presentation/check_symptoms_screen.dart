import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ohok_flutter/app/theme/app_colors.dart';
import 'package:ohok_flutter/core/widgets/parity_cards.dart';
import 'package:ohok_flutter/core/widgets/parity_page_header.dart';
import 'check_symptoms_controller.dart';

class CheckSymptomsScreen extends ConsumerWidget {
  const CheckSymptomsScreen({super.key});

  static const _waveformHeights = [22.0, 36.0, 28.0, 44.0, 30.0, 40.0, 26.0, 34.0];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(checkSymptomsControllerProvider);
    final controller = ref.read(checkSymptomsControllerProvider.notifier);
    final canAnalyze =
        !state.isRecording && state.buttonState == AnalysisButtonState.idle;
    final recordButtonColor = state.isRecording
        ? AppColors.danger
        : state.hasRecording
            ? AppColors.success
            : AppColors.gold;
    final analyzeButtonColor = switch (state.buttonState) {
      AnalysisButtonState.idle => AppColors.navy,
      AnalysisButtonState.loading => AppColors.navy,
      AnalysisButtonState.success => AppColors.success,
    };

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
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
                            onPressed: state.buttonState == AnalysisButtonState.loading
                                ? null
                                : controller.toggleMockRecording,
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
                              color: state.hasRecording || state.isRecording
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
                                        borderRadius: BorderRadius.circular(999),
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
                onPressed: canAnalyze
                    ? () async {
                        final success = await controller.analyze();
                        if (!context.mounted || !success) {
                          return;
                        }
                        await Future<void>.delayed(const Duration(seconds: 1));
                        if (context.mounted) {
                          context.go('/result');
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
                      else if (state.buttonState == AnalysisButtonState.loading)
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
                      Text(
                        switch (state.buttonState) {
                          AnalysisButtonState.idle => 'Analyze Now',
                          AnalysisButtonState.loading => 'Analyzing...',
                          AnalysisButtonState.success => 'Analysis Complete ✓',
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
