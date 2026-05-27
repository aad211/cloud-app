import 'package:cloud_app/core/models/health_insight_record.dart';

const healthInsightsSeed = <HealthInsightRecord>[
  HealthInsightRecord(
    emoji: '🫁',
    title: 'Understanding COPD',
    description: 'Learn about chronic obstructive pulmonary disease',
    url:
        'https://www.who.int/news-room/fact-sheets/detail/chronic-obstructive-pulmonary-disease-(copd)',
  ),
  HealthInsightRecord(
    emoji: '🌿',
    title: 'Air Quality Tips',
    description: 'How to protect your lungs from pollution',
    url:
        'https://www.epa.gov/indoor-air-quality-iaq/inside-story-guide-indoor-air-quality',
  ),
  HealthInsightRecord(
    emoji: '🚭',
    title: 'Quit Smoking Guide',
    description: 'Steps to improve your respiratory health',
    url: 'https://www.cdc.gov/tobacco/quit_smoking/index.htm',
  ),
];
