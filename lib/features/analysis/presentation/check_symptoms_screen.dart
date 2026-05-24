import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ohok_flutter/app/theme/app_colors.dart';
import 'check_symptoms_controller.dart';

class CheckSymptomsScreen extends ConsumerWidget {
  const CheckSymptomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(checkSymptomsControllerProvider);
    final controller = ref.read(checkSymptomsControllerProvider.notifier);
    final canAnalyze =
        !state.isRecording && state.buttonState == AnalysisButtonState.idle;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
              const Text(
                'Check Symptoms',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed:
                    state.isRecording ? null : controller.startMockRecording,
                style: FilledButton.styleFrom(
                  backgroundColor:
                      state.isRecording ? AppColors.danger : AppColors.gold,
                  minimumSize: const Size(220, 220),
                  shape: const CircleBorder(),
                ),
                child: Text(
                  state.hasRecording
                      ? 'Cough recorded ✓'
                      : 'Tap to record your cough',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              if (state.isRecording)
                Text(
                    '00:${state.recordingTime.toString().padLeft(2, '0')}'),
              if (state.errorMessage.isNotEmpty)
                Text(
                  state.errorMessage,
                  style: const TextStyle(color: AppColors.danger),
                ),
              const Spacer(),
              FilledButton(
                onPressed: canAnalyze
                    ? () async {
                        final success = await controller.analyze();
                        if (success && context.mounted) {
                          context.go('/result');
                        }
                      }
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  minimumSize: const Size.fromHeight(56),
                ),
                child: Text(
                  switch (state.buttonState) {
                    AnalysisButtonState.idle => 'Analyze Now',
                    AnalysisButtonState.loading => 'Analyzing...',
                    AnalysisButtonState.success => 'Analysis Complete ✓',
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
