import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ohok_flutter/app/theme/app_colors.dart';
import 'package:ohok_flutter/core/models/analysis_record.dart';
import 'package:ohok_flutter/features/analysis/presentation/analysis_history_controller.dart';

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

  DateTime get _now => widget.now ?? DateTime.now();

  bool _isWithinPastDays(AnalysisRecord record, int days) {
    final cutoff = _now.subtract(Duration(days: days));
    return !record.date.isAfter(_now) && record.date.isAfter(cutoff);
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'History',
          style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: AppColors.navy),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PeriodFilterRow(
            selected: _period,
            onChanged: (p) => setState(() => _period = p),
          ),
          Expanded(
            child: historyAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => const _ErrorState(),
              data: (records) {
                final filtered = _filter(records);
                if (filtered.isEmpty) return const _EmptyState();
                final groups = _group(filtered);
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  itemCount: groups.fold<int>(
                      0, (sum, g) => sum + 1 + g.$2.length),
                  itemBuilder: (context, index) {
                    // Flatten groups into a list of widgets
                    var cursor = 0;
                    for (final (label, groupRecords) in groups) {
                      if (index == cursor) {
                        return _DateHeading(label: label);
                      }
                      cursor++;
                      final localIndex = index - cursor;
                      if (localIndex >= 0 &&
                          localIndex < groupRecords.length) {
                        return _RecordRow(record: groupRecords[localIndex]);
                      }
                      cursor += groupRecords.length;
                    }
                    return const SizedBox.shrink();
                  },
                );
              },
            ),
          ),
        ],
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: _HistoryPeriod.values.map((period) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(period.label),
              selected: selected == period,
              onSelected: (_) => onChanged(period),
              selectedColor: AppColors.navy,
              labelStyle: TextStyle(
                color: selected == period ? Colors.white : AppColors.navy,
                fontSize: 13,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DateHeading extends StatelessWidget {
  const _DateHeading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.navy,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({required this.record});

  final AnalysisRecord record;

  static final _timeFmt = DateFormat('hh:mm a', 'en_US');

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: const Color(0xFFF5F7FA),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          record.condition,
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          _timeFmt.format(record.date),
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: Text(
          '${record.percentage}%',
          style: const TextStyle(
            color: AppColors.blue,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No History Yet',
        style: TextStyle(
          color: AppColors.navy,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
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
