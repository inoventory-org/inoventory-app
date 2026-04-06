import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:inoventory_ui/expiry_scan/expiry_date_parser.dart';
import 'package:inoventory_ui/expiry_scan/models/expiry_scan_text_block.dart';

void main() {
  final ExpiryDateParser parser = ExpiryDateParser();
  const Rect targetBox = Rect.fromLTWH(0.16, 0.2, 0.68, 0.44);
  final DateTime referenceNow = DateTime(2026, 4, 6);

  test('prefers keyword-adjacent future expiry date', () {
    final detection = parser.parse(
      blocks: const [
        ExpiryScanTextBlock(
          text: 'LOT 1234\nEXP 14/05/2026',
          boundingBox: Rect.fromLTWH(0.2, 0.28, 0.4, 0.16),
        ),
      ],
      targetBox: targetBox,
      now: referenceNow,
    );

    expect(detection.requiresConfirmation, isFalse);
    expect(detection.bestCandidate?.isoDate, '2026-05-14');
  });

  test('uses end of month for month-year dates', () {
    final detection = parser.parse(
      blocks: const [
        ExpiryScanTextBlock(
          text: 'Best before 08/26',
          boundingBox: Rect.fromLTWH(0.22, 0.3, 0.35, 0.12),
        ),
      ],
      targetBox: targetBox,
      now: referenceNow,
    );

    expect(detection.bestCandidate?.isoDate, '2026-08-31');
    expect(detection.bestCandidate?.inferredFromMonthYear, isTrue);
  });

  test('parses ambiguous numeric dates as european day-month-year', () {
    final detection = parser.parse(
      blocks: const [
        ExpiryScanTextBlock(
          text: 'EXP 02.07.26',
          boundingBox: Rect.fromLTWH(0.22, 0.3, 0.35, 0.12),
        ),
      ],
      targetBox: targetBox,
      now: referenceNow,
    );

    expect(detection.bestCandidate?.isoDate, '2026-07-02');
  });

  test('parses compact eight-digit european dates', () {
    final detection = parser.parse(
      blocks: const [
        ExpiryScanTextBlock(
          text: 'EXP 21032027',
          boundingBox: Rect.fromLTWH(0.22, 0.3, 0.35, 0.12),
        ),
      ],
      targetBox: targetBox,
      now: referenceNow,
    );

    expect(detection.bestCandidate?.isoDate, '2027-03-21');
  });

  test('asks for confirmation when two dates are similarly plausible', () {
    final detection = parser.parse(
      blocks: const [
        ExpiryScanTextBlock(
          text: 'EXP 14/05/2026\nBEST BEFORE 21/05/2026',
          boundingBox: Rect.fromLTWH(0.25, 0.24, 0.38, 0.18),
        ),
      ],
      targetBox: targetBox,
      now: referenceNow,
    );

    expect(detection.requiresConfirmation, isTrue);
    expect(detection.candidates.length, 2);
    expect(detection.candidates.first.isoDate, '2026-05-21');
  });
}
