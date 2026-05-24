import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ohok_flutter/app/theme/app_colors.dart';
import 'package:ohok_flutter/features/analysis/data/mock_analysis_repository.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = const MockAnalysisRepository().probabilities();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Analysis Result',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bronchitis',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            const Text(
              '65%',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 24),
            for (final item in items) ...[
              _ProbabilityRow(item: item),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/hospitals'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.navy,
                minimumSize: const Size.fromHeight(56),
              ),
              child: const Text('Find Nearby Hospital'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.go('/home'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProbabilityRow extends StatelessWidget {
  const _ProbabilityRow({required this.item});

  final dynamic item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Color(item.hexColor),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(item.name)),
        Text('${item.percentage}%'),
      ],
    );
  }
}
