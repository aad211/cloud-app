import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_flutter/app/theme/app_colors.dart';
import 'package:cloud_flutter/core/models/article_record.dart';
import 'package:cloud_flutter/core/models/news_record.dart';
import 'package:cloud_flutter/core/widgets/parity_cards.dart';
import 'package:cloud_flutter/core/widgets/parity_page_header.dart';
import 'package:cloud_flutter/features/articles/data/articles_seed.dart';
import 'package:cloud_flutter/features/articles/data/news_seed.dart';

class ArticlesScreen extends StatefulWidget {
  const ArticlesScreen({super.key});

  @override
  State<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends State<ArticlesScreen> {
  var tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            ParityPageHeader(
              title: 'Articles and News',
              subtitle: 'Learn about respiratory conditions and lung health',
              onBack: () => context.go('/home'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.sand,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _SegmentButton(
                        label: 'Articles',
                        selected: tab == 0,
                        onTap: () => setState(() => tab = 0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SegmentButton(
                        label: 'News',
                        selected: tab == 1,
                        onTap: () => setState(() => tab = 1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: tab == 0 ? const _ArticlesTab() : const _NewsTab(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.blue,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ArticlesTab extends StatelessWidget {
  const _ArticlesTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ParityInfoCard(
          leading: Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.info_outline, color: AppColors.blue, size: 20),
          ),
          child: Text(
            'Our AI analyzes cough audio patterns to detect potential respiratory conditions. This is not a medical diagnosis - always consult healthcare professionals.',
            style: TextStyle(color: AppColors.navy, fontSize: 14, height: 1.45),
          ),
        ),
        const SizedBox(height: 16),
        for (final article in articleSeed) ...[
          _DiseaseCard(article: article),
          const SizedBox(height: 16),
        ],
        const SizedBox(height: 8),
        const Text(
          'Educational Articles',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        for (final card in const [
          (
            'Understanding Lung Health',
            'Learn how to maintain healthy lungs and prevent respiratory diseases.',
          ),
          (
            'Air Quality & Your Lungs',
            'How pollution affects respiratory health and what you can do.',
          ),
          (
            'Quitting Smoking Guide',
            'Evidence-based strategies to quit smoking and improve lung function.',
          ),
        ]) ...[
          _EducationalArticleCard(title: card.$1, description: card.$2),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _DiseaseCard extends StatelessWidget {
  const _DiseaseCard({required this.article});

  final ArticleRecord article;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: article.color, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A1A3263),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(article.icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.name,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      article.description,
                      style: const TextStyle(
                        color: AppColors.blue,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.only(left: 44),
            child: Text(
              'Common Symptoms:',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Column(
              children: [
                for (final symptom in article.symptoms)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '•',
                          style: TextStyle(
                            color: article.color,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            symptom,
                            style: const TextStyle(
                              color: AppColors.blue,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
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

class _EducationalArticleCard extends StatelessWidget {
  const _EducationalArticleCard({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.sand, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.blue,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE0F2FE),
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

class _NewsTab extends StatelessWidget {
  const _NewsTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Latest Health News',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        for (final news in newsSeed) ...[
          _NewsCard(news: news),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.news});

  final NewsRecord news;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.sand, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A1A3263),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(news.image, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        news.category,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        news.date,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  news.title,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  news.description,
                  style: const TextStyle(
                    color: AppColors.blue,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
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
          ),
        ],
      ),
    );
  }
}
