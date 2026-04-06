import 'dart:math';
import 'dart:ui';

import 'package:inoventory_ui/expiry_scan/models/expiry_scan_candidate.dart';
import 'package:inoventory_ui/expiry_scan/models/expiry_scan_detection.dart';
import 'package:inoventory_ui/expiry_scan/models/expiry_scan_text_block.dart';
import 'package:intl/intl.dart';

class ExpiryDateParser {
  static final RegExp _fullDatePattern = RegExp(
    r'(?<!\d)(\d{1,2})[\/\-.](\d{1,2})[\/\-.](\d{2,4})(?!\d)',
    caseSensitive: false,
  );
  static final RegExp _isoDatePattern = RegExp(
    r'(?<!\d)(20\d{2})[\/\-.](\d{1,2})[\/\-.](\d{1,2})(?!\d)',
    caseSensitive: false,
  );
  static final RegExp _monthYearPattern = RegExp(
    r'(?<!\d)(\d{1,2})[\/\-.](\d{2,4})(?!\d)',
    caseSensitive: false,
  );
  static final RegExp _compactDatePattern = RegExp(
    r'(?<!\d)(\d{6}|\d{8})(?!\d)',
    caseSensitive: false,
  );
  static final RegExp _keywordPattern = RegExp(
    r'\b(exp|expiry|expires|best before|bbd|mhd|use by)\b',
    caseSensitive: false,
  );

  ExpiryScanDetection parse({
    required List<ExpiryScanTextBlock> blocks,
    required Rect targetBox,
    DateTime? now,
  }) {
    final DateTime referenceNow = now ?? DateTime.now();
    final Iterable<ExpiryScanTextBlock> targetBlocks = blocks
        .where((block) => _isRelevantToTarget(block.boundingBox, targetBox));
    final bool detectedTextInTarget = targetBlocks.isNotEmpty;

    final Map<String, ExpiryScanCandidate> deduped =
        <String, ExpiryScanCandidate>{};

    for (final ExpiryScanTextBlock block in targetBlocks) {
      final List<String> lines = block.text
          .split(RegExp(r'[\n\r]+'))
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      final bool hasKeyword = _keywordPattern.hasMatch(block.text);

      for (final String line in lines.isEmpty ? <String>[block.text] : lines) {
        for (final ExpiryScanCandidate candidate in _extractCandidatesFromLine(
          line: line,
          block: block,
          targetBox: targetBox,
          hasKeyword: hasKeyword || _keywordPattern.hasMatch(line),
          now: referenceNow,
        )) {
          final ExpiryScanCandidate? existing = deduped[candidate.isoDate];
          if (existing == null || candidate.score > existing.score) {
            deduped[candidate.isoDate] = candidate;
          }
        }
      }
    }

    final List<ExpiryScanCandidate> candidates = deduped.values.toList()
      ..sort((a, b) {
        final int scoreComparison = b.score.compareTo(a.score);
        if (scoreComparison != 0) {
          return scoreComparison;
        }
        return b.date.compareTo(a.date);
      });

    final bool requiresConfirmation = candidates.length > 1 &&
        (candidates.first.score - candidates[1].score) < 10;

    return ExpiryScanDetection(
      detectedTextInTarget: detectedTextInTarget,
      requiresConfirmation: requiresConfirmation,
      candidates: candidates.take(4).toList(),
    );
  }

  Iterable<ExpiryScanCandidate> _extractCandidatesFromLine({
    required String line,
    required ExpiryScanTextBlock block,
    required Rect targetBox,
    required bool hasKeyword,
    required DateTime now,
  }) sync* {
    for (final Match match in _isoDatePattern.allMatches(line)) {
      final int? year = int.tryParse(match.group(1)!);
      final int? month = int.tryParse(match.group(2)!);
      final int? day = int.tryParse(match.group(3)!);
      final DateTime? date = _safeDate(year, month, day);
      if (date == null) {
        continue;
      }
      yield _buildCandidate(
        line: line,
        block: block,
        targetBox: targetBox,
        hasKeyword: hasKeyword,
        date: date,
        now: now,
      );
    }

    for (final Match match in _fullDatePattern.allMatches(line)) {
      final int? part1 = int.tryParse(match.group(1)!);
      final int? part2 = int.tryParse(match.group(2)!);
      final int? part3 = _normalizeYear(match.group(3)!);
      final DateTime? date = _safeDate(part3, part2, part1);
      if (date == null) {
        continue;
      }
      yield _buildCandidate(
        line: line,
        block: block,
        targetBox: targetBox,
        hasKeyword: hasKeyword,
        date: date,
        now: now,
      );
    }

    for (final Match match in _monthYearPattern.allMatches(line)) {
      final int? month = int.tryParse(match.group(1)!);
      final int? year = _normalizeYear(match.group(2)!);
      if (month == null || month < 1 || month > 12 || year == null) {
        continue;
      }
      final DateTime date = DateTime(year, month + 1, 0);
      yield _buildCandidate(
        line: line,
        block: block,
        targetBox: targetBox,
        hasKeyword: hasKeyword,
        date: date,
        now: now,
        inferredFromMonthYear: true,
      );
    }

    for (final Match match in _compactDatePattern.allMatches(line)) {
      final String rawValue = match.group(1)!;
      final DateTime? date = _parseCompactEuropeanDate(rawValue);
      if (date == null) {
        continue;
      }
      yield _buildCandidate(
        line: line,
        block: block,
        targetBox: targetBox,
        hasKeyword: hasKeyword,
        date: date,
        now: now,
      );
    }
  }

  ExpiryScanCandidate _buildCandidate({
    required String line,
    required ExpiryScanTextBlock block,
    required Rect targetBox,
    required bool hasKeyword,
    required DateTime date,
    required DateTime now,
    bool inferredFromMonthYear = false,
  }) {
    double score = inferredFromMonthYear ? 48 : 62;
    if (hasKeyword) {
      score += 22;
    }

    final Offset targetCenter = targetBox.center;
    final Offset blockCenter = block.boundingBox.center;
    final double distance = (blockCenter - targetCenter).distance;
    score += max(0, 15 - (distance * 24));

    final int daysDifference =
        date.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (daysDifference >= 0) {
      score += 12;
      if (daysDifference > 30) {
        score += min(10, daysDifference / 90);
      }
    } else {
      score -= 28;
    }

    if (date.year > now.year + 10) {
      score -= 20;
    }

    final String isoDate = DateFormat('yyyy-MM-dd').format(date);
    return ExpiryScanCandidate(
      sourceText: line,
      isoDate: isoDate,
      date: date,
      score: score,
      boundingBox: block.boundingBox,
      inferredFromMonthYear: inferredFromMonthYear,
    );
  }

  bool _isRelevantToTarget(Rect boundingBox, Rect targetBox) {
    if (targetBox.overlaps(boundingBox)) {
      return true;
    }
    return targetBox.inflate(0.08).contains(boundingBox.center);
  }

  int? _normalizeYear(String value) {
    final int? parsed = int.tryParse(value);
    if (parsed == null) {
      return null;
    }
    if (value.length == 2) {
      return 2000 + parsed;
    }
    return parsed;
  }

  DateTime? _parseCompactEuropeanDate(String value) {
    if (value.length == 8) {
      final int? day = int.tryParse(value.substring(0, 2));
      final int? month = int.tryParse(value.substring(2, 4));
      final int? year = int.tryParse(value.substring(4, 8));
      return _safeDate(year, month, day);
    }
    if (value.length == 6) {
      final int? day = int.tryParse(value.substring(0, 2));
      final int? month = int.tryParse(value.substring(2, 4));
      final int? year = _normalizeYear(value.substring(4, 6));
      return _safeDate(year, month, day);
    }
    return null;
  }

  DateTime? _safeDate(int? year, int? month, int? day) {
    if (year == null || month == null || day == null) {
      return null;
    }
    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }
    final DateTime candidate = DateTime(year, month, day);
    if (candidate.year != year ||
        candidate.month != month ||
        candidate.day != day) {
      return null;
    }
    return candidate;
  }
}
