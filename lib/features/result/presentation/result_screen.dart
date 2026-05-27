import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cloud_app/app/theme/app_colors.dart';
import 'package:cloud_app/core/models/analysis_record.dart';
import 'package:cloud_app/core/models/condition_probability.dart';
import 'package:cloud_app/core/widgets/parity_cards.dart';
import 'package:cloud_app/core/widgets/parity_page_header.dart';
import 'package:cloud_app/features/analysis/presentation/analysis_history_controller.dart';
import 'package:cloud_app/features/analysis/presentation/latest_analysis_provider.dart';
import 'package:cloud_app/features/result/presentation/result_summary.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key, this.recordId});

  final String? recordId;

  static final _dateFmt = DateFormat('MMMM d, y', 'en_US');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestRecord = ref.watch(latestAnalysisProvider);
    final historyAsync = ref.watch(analysisHistoryProvider);
    final isHistorical = recordId != null;
    final selectedRecord = _resolveRecord(
      recordId,
      latestRecord,
      historyAsync.valueOrNull,
    );
    void goToFallbackRoute() {
      if (isHistorical) {
        context.go('/history');
      } else {
        context.go('/home');
      }
    }

    void handleBack() {
      if (isHistorical && context.canPop()) {
        context.pop();
        return;
      }
      goToFallbackRoute();
    }

    if (selectedRecord == null) {
      return PopScope(
        canPop: isHistorical,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          goToFallbackRoute();
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                ParityPageHeader(
                  title: 'Analysis Result',
                  subtitle: 'Based on your cough recording',
                  onBack: handleBack,
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'No analysis available yet.',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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

    final summary = buildResultSummary(selectedRecord);
    final record = summary.record;
    final items = summary.probabilities;

    return PopScope(
      canPop: isHistorical,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        goToFallbackRoute();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              ParityPageHeader(
                title: isHistorical ? 'Historical Record' : 'Analysis Result',
                subtitle:
                    isHistorical
                        ? 'Recorded on ${_dateFmt.format(selectedRecord.date)}'
                        : 'Based on your cough recording',
                onBack: handleBack,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    ParityGradientCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _RiskBadge(
                            text: 'Primary Result',
                            color: AppColors.navy,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Most Likely',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            record.condition,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Confidence',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${record.percentage}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _ProbabilityBreakdown(items: items),
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
                          Icons.info,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'What you should do',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 12),
                          _BulletPoint('Rest and monitor your symptoms'),
                          _BulletPoint('Consult a doctor if symptoms persist'),
                          _BulletPoint(
                            'Seek medical attention if condition worsens',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Column(
                      children: [
                        FilledButton(
                          onPressed: () => context.go('/hospitals'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.navy,
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_on_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Find Nearby Hospital'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => context.go('/home'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: AppColors.navy,
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.home_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Back to Home'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const ParityDisclaimerCard(
                      message:
                          '⚠️ This is not a medical diagnosis. Please consult a healthcare professional.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

AnalysisRecord? _resolveRecord(
  String? recordId,
  AnalysisRecord? latestRecord,
  List<AnalysisRecord>? history,
) {
  // Priority 1: Explicit recordId from route parameter
  if (recordId != null && history != null) {
    try {
      return history.firstWhere((r) => r.id == recordId);
    } catch (_) {
      // Record not found in history, fall through to latest
    }
  }

  // Priority 2: Latest analysis from fresh recording
  if (latestRecord != null) {
    return latestRecord;
  }

  // Priority 3: Most recent from history if no latest
  if (history != null && history.isNotEmpty) {
    return history.first;
  }

  return null;
}

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProbabilityBreakdown extends StatelessWidget {
  const _ProbabilityBreakdown({required this.items});

  final List<ConditionProbability> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.sand, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Probability Breakdown',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          for (final item in items) ...[
            _ProbabilityRow(item: item),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _ProbabilityRow extends StatelessWidget {
  const _ProbabilityRow({required this.item});

  final ConditionProbability item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              item.name,
              style: const TextStyle(color: AppColors.navy, fontSize: 14),
            ),
            Text(
              '${item.percentage}%',
              style: const TextStyle(color: AppColors.blue, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: item.percentage / 100,
            backgroundColor: AppColors.sand,
            valueColor: AlwaysStoppedAnimation<Color>(Color(item.hexColor)),
          ),
        ),
      ],
    );
  }
}

class _BulletPoint extends StatelessWidget {
  const _BulletPoint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '•',
            style: TextStyle(color: AppColors.blue, fontSize: 18, height: 1.2),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.navy, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
