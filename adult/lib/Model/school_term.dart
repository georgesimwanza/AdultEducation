/// A single school term's date range (inclusive on both ends).
class SchoolTerm {
  final String label; // e.g. "Term 1 (2026)"
  final DateTime start;
  final DateTime end;

  SchoolTerm({required this.label, required this.start, required this.end});

  bool contains(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    return !day.isBefore(startDay) && !day.isAfter(endDay);
  }

  int get totalDays => end.difference(start).inDays + 1;
}

/// Result of comparing "now" against a list of SchoolTerms.
class TermProgress {
  final String label;
  final bool isHoliday; // true when `now` falls between terms
  final int
  daysLeft; // days left in the active term, or until the next one starts
  final double percentComplete; // 0..1 — only meaningful when !isHoliday
  final DateTime? nextTermStart; // set when isHoliday and a future term exists

  const TermProgress({
    required this.label,
    required this.isHoliday,
    required this.daysLeft,
    required this.percentComplete,
    this.nextTermStart,
  });
}

/// Given the full list of known term boundaries and the current moment,
/// works out whether `now` falls inside a term (and how far through it) or
/// in a holiday gap between two terms (and how many days until the next
/// one starts). Terms don't need to be pre-sorted.
///
/// If `now` is past every known term (e.g. the list only covers up to
/// December and it's now January of an unlisted year), this returns a
/// "Term dates not yet available" result rather than guessing — that's
/// your signal to add next year's dates.
TermProgress computeTermProgress(List<SchoolTerm> terms, DateTime now) {
  final sorted = [...terms]..sort((a, b) => a.start.compareTo(b.start));

  for (final term in sorted) {
    if (term.contains(now)) {
      final total = term.totalDays;
      final elapsed =
          DateTime(now.year, now.month, now.day)
              .difference(
                DateTime(term.start.year, term.start.month, term.start.day),
              )
              .inDays +
          1;
      final daysLeft = DateTime(
        term.end.year,
        term.end.month,
        term.end.day,
      ).difference(DateTime(now.year, now.month, now.day)).inDays;
      return TermProgress(
        label: term.label,
        isHoliday: false,
        daysLeft: daysLeft < 0 ? 0 : daysLeft,
        percentComplete: (elapsed / total).clamp(0.0, 1.0),
      );
    }
  }

  final upcoming = sorted.where((t) => t.start.isAfter(now)).toList();
  if (upcoming.isNotEmpty) {
    final next = upcoming.first;
    final daysUntil = DateTime(
      next.start.year,
      next.start.month,
      next.start.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
    return TermProgress(
      label: 'On holiday — ${next.label} starts soon',
      isHoliday: true,
      daysLeft: daysUntil,
      percentComplete: 0,
      nextTermStart: next.start,
    );
  }

  return const TermProgress(
    label: 'Term dates not yet available',
    isHoliday: true,
    daysLeft: 0,
    percentComplete: 0,
  );
}

/// Best-effort 2026 Zambian term dates. ONLY Term 1's opening (12 Jan 2026)
/// is confirmed against an official Ministry of Education source as of
/// this writing — the other five dates follow Zambia's typical unadjusted
/// 3-term pattern (Term 1 ~mid-Jan–Apr, Term 2 ~May–Aug as the longest
/// term, Term 3 ~Sep–Dec), inferred from past published calendars, NOT
/// confirmed for 2026 specifically.
///
/// The Ministry has revised dates mid-year before (e.g. the 2024 cholera
/// postponement), so verify every date below against the actual published
/// 2026 calendar before relying on this — ideally by moving this list
/// server-side so a Ministry revision doesn't require an app update.
final List<SchoolTerm> zambia2026TermsBestEffort = [
  SchoolTerm(
    label: 'Term 1 (2026)',
    start: DateTime(2026, 1, 12), // confirmed
    end: DateTime(2026, 4, 3), // NOT confirmed — verify
  ),
  SchoolTerm(
    label: 'Term 2 (2026)',
    start: DateTime(2026, 5, 4), // NOT confirmed — verify
    end: DateTime(2026, 8, 7), // NOT confirmed — verify
  ),
  SchoolTerm(
    label: 'Term 3 (2026)',
    start: DateTime(2026, 9, 7), // NOT confirmed — verify
    end: DateTime(2026, 12, 4), // NOT confirmed — verify
  ),
];
