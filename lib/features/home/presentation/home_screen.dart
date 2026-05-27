import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cloud_app/app/theme/app_colors.dart';
import 'package:cloud_app/core/data/health_insights_seed.dart';
import 'package:cloud_app/core/models/analysis_record.dart';
import 'package:cloud_app/core/models/health_insight_record.dart';
import 'package:cloud_app/core/utils/external_link_opener.dart';
import 'package:cloud_app/core/widgets/parity_cards.dart';
import 'package:cloud_app/features/analysis/presentation/analysis_history_controller.dart';
import 'package:cloud_app/core/widgets/cloud_logo.dart';
import 'package:cloud_app/core/widgets/exit_confirmation_dialog.dart';

typedef OpenLinkHandler = Future<bool> Function(BuildContext context, String url);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, this.openLink = _defaultOpenLink});

  final OpenLinkHandler openLink;

  static Future<bool> _defaultOpenLink(BuildContext context, String url) {
    return openExternalLink(context: context, url: url);
  }

  static final _dateFmt = DateFormat('MMMM d, y • hh:mm a', 'en_US');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(analysisHistoryProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldExit = await showExitConfirmationDialog(context);
        if (shouldExit && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CloudLogo(size: CloudLogoSize.medium),
                    const SizedBox(height: 4),
                    Text(
                      'Cough Lung Observation & Diagnosis',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AppColors.blue),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              historyAsync.when(
                loading: () => const _AnalysisLoadingCard(),
                error: (_, __) => const _AnalysisErrorCard(),
                data:
                    (history) =>
                        history.isEmpty
                            ? const _EmptyAnalysisCard()
                            : _LatestAnalysisCard(record: history.first),
              ),
              const SizedBox(height: 20),
              Text(
                'Quick Actions',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: AppColors.navy),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/check-symptoms'),
                  icon: const Icon(Icons.monitor_heart),
                  label: const Text('Check Symptoms'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.navy,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _SecondaryActionButton(
                    icon: Icons.article_outlined,
                    label: 'Articles',
                    onTap: () => context.push('/articles'),
                  ),
                  const SizedBox(width: 12),
                  _SecondaryActionButton(
                    icon: Icons.history,
                    label: 'History',
                    onTap: () => context.push('/history'),
                  ),
                  const SizedBox(width: 12),
                  _SecondaryActionButton(
                    icon: Icons.local_hospital_outlined,
                    label: 'Hospital',
                    onTap: () => context.push('/hospitals'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Health Insights',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: AppColors.navy),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 250,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: healthInsightsSeed.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder:
                      (context, index) =>
                          _InsightCard(
                            insight: healthInsightsSeed[index],
                            openLink: openLink,
                          ),
                ),
              ),
              const SizedBox(height: 20),
              const ParityDisclaimerCard(
                message:
                    '⚠️ Not a medical diagnosis. Consult healthcare professionals.',
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class _EmptyAnalysisCard extends StatelessWidget {
  const _EmptyAnalysisCard();

  @override
  Widget build(BuildContext context) {
    return const ParityGradientCard(
      child: Column(
        children: [
          Text('🫁', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text(
            'No Analysis Yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start by checking your symptoms to get your first respiratory health analysis',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _AnalysisErrorCard extends StatelessWidget {
  const _AnalysisErrorCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.disclaimerBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        children: [
          Icon(Icons.error_outline, color: AppColors.critical, size: 48),
          SizedBox(height: 12),
          Text(
            'Unable to load analysis history',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Please try again to view your latest respiratory analysis.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.warning, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _AnalysisLoadingCard extends StatelessWidget {
  const _AnalysisLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _LatestAnalysisCard extends StatelessWidget {
  const _LatestAnalysisCard({required this.record});

  final AnalysisRecord record;

  @override
  Widget build(BuildContext context) {
    return ParityGradientCard(
      child: Column(
        children: [
          Text(
            'Latest Analysis',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _conditionIcon(record.condition),
            style: const TextStyle(fontSize: 56),
          ),
          const SizedBox(height: 8),
          Text(
            record.condition,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'Confidence',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${record.percentage}%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            HomeScreen._dateFmt.format(record.date),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  static String _conditionIcon(String condition) {
    switch (condition) {
      case 'Healthy':
        return '✅';
      case 'Asthma':
        return '🫁';
      case 'Bronchitis':
        return '🤒';
      case 'Pneumonia':
      case 'COVID-19':
        return '🦠';
      case 'Lung Cancer':
        return '⚠️';
      default:
        return '🫁';
    }
  }

}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.sand, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(icon, color: AppColors.blue, size: 20),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(color: AppColors.navy, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight, required this.openLink});

  final HealthInsightRecord insight;
  final OpenLinkHandler openLink;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.sand, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(insight.emoji, style: const TextStyle(fontSize: 34)),
          const SizedBox(height: 10),
          Text(
            insight.title,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            insight.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.blue, fontSize: 11),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => openLink(context, insight.url),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.infoBackground,
              foregroundColor: AppColors.navy,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Read more'),
          ),
        ],
      ),
    );
  }
}
