import 'package:flutter/material.dart';
import 'package:cloud_app/core/models/article_record.dart';

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
    url:
        'https://www.mayoclinic.org/diseases-conditions/asthma/symptoms-causes/syc-20369653',
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
    url:
        'https://www.mayoclinic.org/diseases-conditions/bronchitis/symptoms-causes/syc-20355566',
  ),
  ArticleRecord(
    name: 'Pneumonia',
    icon: '🦠',
    description:
        'An infection that inflames air sacs in one or both lungs, which may fill with fluid.',
    symptoms: ['Fever', 'Chills', 'Cough with phlegm', 'Difficulty breathing'],
    color: Color(0xFFEF4444),
    url: 'https://www.cdc.gov/pneumonia/index.html',
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
    url: 'https://www.cdc.gov/covid/index.html',
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
    url: 'https://www.cancer.gov/types/lung',
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
    url: 'https://www.nhlbi.nih.gov/health/lungs',
  ),
];
