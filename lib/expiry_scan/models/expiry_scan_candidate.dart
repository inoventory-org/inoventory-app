import 'dart:ui';

class ExpiryScanCandidate {
  final String sourceText;
  final String isoDate;
  final DateTime date;
  final double score;
  final Rect boundingBox;
  final bool inferredFromMonthYear;

  const ExpiryScanCandidate({
    required this.sourceText,
    required this.isoDate,
    required this.date,
    required this.score,
    required this.boundingBox,
    this.inferredFromMonthYear = false,
  });

  String get scoreLabel => '${score.clamp(0, 100).round()}%';
}
