import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cloud_app/app/theme/app_colors.dart';
import 'package:cloud_app/core/models/analysis_record.dart';
import 'package:cloud_app/core/widgets/condition_visuals.dart';
import 'package:cloud_app/core/widgets/parity_cards.dart';
import 'package:cloud_app/core/widgets/parity_page_header.dart';
import 'package:cloud_app/features/analysis/presentation/analysis_history_controller.dart';

enum _HistoryPeriod {
  all,
  sevenDays,
  thirtyDays;

  String get label => switch (this) {
        _HistoryPeriod.all => 'All Time',
        _HistoryPeriod.sevenDays => 'Last 7 Days',
        _HistoryPeriod.thirtyDays => 'Last 30 Days',
      };
}

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key, this.now});

  /// Injectable clock for testability; defaults to [DateTime.now].
  final DateTime? now;

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  _HistoryPeriod _period = _HistoryPeriod.all;

  static final _dateFmt = DateFormat('MMMM d, y', 'en_US');
  static final _timestampFmt = DateFormat('MMMM d, y, hh:mm a', 'en_US');

  DateTime get _now => widget.now ?? DateTime.now();

  bool _isWithinPastDays(AnalysisRecord record, int days) {
    final cutoff = _now.subtract(Duration(days: days));
    return !record.date.isAfter(_now) && !record.date.isBefore(cutoff);
  }

  List<AnalysisRecord> _filter(List<AnalysisRecord> records) {
    return switch (_period) {
      _HistoryPeriod.all => records,
      _HistoryPeriod.sevenDays => records
          .where((r) => _isWithinPastDays(r, 7))
          .toList(),
      _HistoryPeriod.thirtyDays => records
          .where((r) => _isWithinPastDays(r, 30))
          .toList(),
    };
  }

  /// Returns an ordered list of (dateLabel, records) pairs.
  List<(String, List<AnalysisRecord>)> _group(List<AnalysisRecord> records) {
    final ordered = [...records]
      ..sort((a, b) => b.date.compareTo(a.date));
    final groups = <String, List<AnalysisRecord>>{};
    for (final record in ordered) {
      final key = _dateFmt.format(record.date);
      (groups[key] ??= []).add(record);
    }
    return groups.entries.map((e) => (e.key, e.value)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(analysisHistoryProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ParityPageHeader(
              title: 'Symptom History',
              subtitle: 'Track your respiratory health over time',
              onBack: () => context.go('/home'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: _PeriodFilterRow(
                selected: _period,
                onChanged: (p) => setState(() => _period = p),
              ),
            ),
            Expanded(
              child: historyAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => const _ErrorState(),
                data: (records) {
                  final filtered = _filter(records);
                  final groups = _group(filtered);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (filtered.isNotEmpty) ...[
                          Text(
                            'All Records (${filtered.length})',
                            style: const TextStyle(
                              color: AppColors.blue,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          for (final (label, groupRecords) in groups) ...[
                            _DateHeading(label: label),
                            const SizedBox(height: 12),
                            for (final record in groupRecords) ...[
                              _RecordCard(
                                record: record,
                                timestampLabel: _timestampFmt.format(record.date),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ],
                          _InsightsCard(recordCount: filtered.length),
                          const SizedBox(height: 16),
                        ] else ...[
                          const _EmptyState(),
                          const SizedBox(height: 16),
                        ],
                        const ParityDisclaimerCard(
                          message:
                              '⚠️ This is not a medical diagnosis. Please consult a healthcare professional.',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _PeriodFilterRow extends StatelessWidget {
  const _PeriodFilterRow({
    required this.selected,
    required this.onChanged,
  });

  final _HistoryPeriod selected;
  final ValueChanged<_HistoryPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PeriodFilterButton(
            label: _HistoryPeriod.all.label,
            selected: selected == _HistoryPeriod.all,
            onPressed: () => onChanged(_HistoryPeriod.all),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PeriodFilterButton(
            label: _HistoryPeriod.sevenDays.label,
            selected: selected == _HistoryPeriod.sevenDays,
            onPressed: () => onChanged(_HistoryPeriod.sevenDays),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PeriodFilterButton(
            label: _HistoryPeriod.thirtyDays.label,
            selected: selected == _HistoryPeriod.thirtyDays,
            onPressed: () => onChanged(_HistoryPeriod.thirtyDays),
          ),
        ),
      ],
    );
  }
}

class _PeriodFilterButton extends StatelessWidget {
  const _PeriodFilterButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: selected ? AppColors.navy : AppColors.sand,
          foregroundColor: selected ? Colors.white : AppColors.blue,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }
}

class _DateHeading extends StatelessWidget {
  const _DateHeading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.blue,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record, required this.timestampLabel});

  final AnalysisRecord record;
  final String timestampLabel;

  @override
  Widget build(BuildContext context) {
    final visuals = conditionVisualsFor(record.condition);

    return ParityGradientCard(
      child: Column(
        children: [
          Text(visuals.emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          Text(
            record.condition,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: visuals.color.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Confidence',
                  style: TextStyle(
                    color: Color(0xB3FFFFFF),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${record.percentage}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0x33FFFFFF)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Color(0xB3FFFFFF),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    timestampLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xB3FFFFFF),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Text('📋', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text(
            'No History Yet',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start checking your symptoms to build your health history',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.blue,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightsCard extends StatelessWidget {
  const _InsightsCard({required this.recordCount});

  final int recordCount;

  @override
  Widget build(BuildContext context) {
    return ParityInfoCard(
      leading: const SizedBox.shrink(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💡 Health Insights',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "• You've completed $recordCount ${recordCount == 1 ? 'analysis' : 'analyses'}",
            style: const TextStyle(color: AppColors.blue, fontSize: 14),
          ),
          const SizedBox(height: 8),
          const Text(
            '• Regular monitoring helps track respiratory health changes',
            style: TextStyle(color: AppColors.blue, fontSize: 14),
          ),
          const SizedBox(height: 8),
          const Text(
            '• Consult a healthcare professional if symptoms persist',
            style: TextStyle(color: AppColors.blue, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Unable to load history',
        style: TextStyle(
          color: AppColors.navy,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
