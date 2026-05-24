import 'package:flutter/material.dart';
import 'package:ohok_flutter/core/models/article_record.dart';

const List<ArticleRecord> articleSeed = [
  ArticleRecord(
    name: 'Asthma',
    icon: '🫁',
    description:
        'A condition in which airways narrow and swell, producing extra mucus, making breathing difficult.',
    symptoms: [
      'Wheezing',
      'Shortness of breath',
      'Chest tightness',
      'Coughing attacks',
    ],
    color: Color(0xFF547792),
  ),
  ArticleRecord(
    name: 'Bronchitis',
    icon: '🤒',
    description:
        'Inflammation of the bronchial tubes that carry air to and from the lungs.',
    symptoms: [
      'Persistent cough',
      'Mucus production',
      'Fatigue',
      'Chest discomfort',
    ],
    color: Color(0xFFFAB95B),
  ),
  ArticleRecord(
    name: 'Pneumonia',
    icon: '🦠',
    description:
        'An infection that inflames air sacs in one or both lungs, which may fill with fluid.',
    symptoms: ['Fever', 'Chills', 'Cough with phlegm', 'Difficulty breathing'],
    color: Color(0xFFEF4444),
  ),
  ArticleRecord(
    name: 'COVID-19',
    icon: '🦠',
    description:
        'Respiratory illness caused by the coronavirus, affecting the lungs and airways.',
    symptoms: [
      'Dry cough',
      'Fever',
      'Loss of taste/smell',
      'Shortness of breath',
    ],
    color: Color(0xFFEF4444),
  ),
  ArticleRecord(
    name: 'Lung Cancer',
    icon: '⚠️',
    description:
        'Cancer that begins in the lungs, often associated with smoking and air pollution.',
    symptoms: [
      'Persistent cough',
      'Coughing up blood',
      'Chest pain',
      'Weight loss',
    ],
    color: Color(0xFF991B1B),
  ),
  ArticleRecord(
    name: 'Healthy',
    icon: '✅',
    description: 'Normal respiratory function with no detected conditions.',
    symptoms: [
      'Clear breathing',
      'No persistent cough',
      'Normal oxygen levels',
      'Active lifestyle',
    ],
    color: Color(0xFF22C55E),
  ),
];
