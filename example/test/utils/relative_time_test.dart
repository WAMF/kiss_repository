import 'package:example/utils/relative_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A fixed local reference time keeps every expectation deterministic.
  final now = DateTime(2026, 8, 9, 13, 45, 30);

  String format(Duration ago) => formatCreatedDate(now.subtract(ago), now: now);

  group('formatCreatedDate relative labels', () {
    test('under a minute reads "Just now"', () {
      expect(format(Duration.zero), 'Just now');
      expect(format(const Duration(seconds: 59)), 'Just now');
    });

    test('a time in the future also reads "Just now"', () {
      expect(format(const Duration(seconds: -30)), 'Just now');
      expect(format(const Duration(days: -400)), 'Just now');
    });

    test('minutes are singular at one and plural above one', () {
      expect(format(const Duration(minutes: 1)), '1 minute ago');
      expect(format(const Duration(minutes: 2)), '2 minutes ago');
      expect(format(const Duration(minutes: 59)), '59 minutes ago');
    });

    test('hours are singular at one and plural above one', () {
      expect(format(const Duration(hours: 1)), '1 hour ago');
      expect(format(const Duration(hours: 2)), '2 hours ago');
      expect(format(const Duration(hours: 23)), '23 hours ago');
    });

    test('days are singular at one and plural above one', () {
      expect(format(const Duration(days: 1)), '1 day ago');
      expect(format(const Duration(days: 2)), '2 days ago');
      expect(format(const Duration(days: 6)), '6 days ago');
    });

    test('the unit changes on the exact boundary, not before it', () {
      expect(format(const Duration(seconds: 59)), 'Just now');
      expect(format(const Duration(seconds: 60)), '1 minute ago');

      expect(
        format(const Duration(minutes: 59, seconds: 59)),
        '59 minutes ago',
      );
      expect(format(const Duration(minutes: 60)), '1 hour ago');

      expect(format(const Duration(hours: 23, minutes: 59)), '23 hours ago');
      expect(format(const Duration(hours: 24)), '1 day ago');
    });

    test('a whole week stops being relative and becomes a full date', () {
      expect(format(const Duration(days: 6, hours: 23)), '6 days ago');
      expect(format(const Duration(days: 7)), 'Aug 2, 2026 at 1:45 PM');
    });
  });

  group('formatCreatedDate absolute labels', () {
    String at(DateTime created) => formatCreatedDate(created, now: now);

    test('midnight shows 12 AM, not 0 AM', () {
      expect(at(DateTime(2020, 3, 4)), 'Mar 4, 2020 at 12:00 AM');
    });

    test('noon shows 12 PM', () {
      expect(at(DateTime(2020, 3, 4, 12)), 'Mar 4, 2020 at 12:00 PM');
    });

    test('the hour before noon is AM and the hour after is PM', () {
      expect(at(DateTime(2020, 3, 4, 11, 59)), 'Mar 4, 2020 at 11:59 AM');
      expect(at(DateTime(2020, 3, 4, 13)), 'Mar 4, 2020 at 1:00 PM');
      expect(at(DateTime(2020, 3, 4, 23, 30)), 'Mar 4, 2020 at 11:30 PM');
    });

    test('a single-digit minute keeps its leading zero', () {
      expect(at(DateTime(2020, 3, 4, 9, 5)), 'Mar 4, 2020 at 9:05 AM');
    });

    test('every month maps to the right abbreviation', () {
      const expected = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      for (var month = 1; month <= 12; month++) {
        expect(
          at(DateTime(2020, month, 15, 10)),
          '${expected[month - 1]} 15, 2020 at 10:00 AM',
          reason: 'month $month',
        );
      }
    });

    test('a leap day formats as itself', () {
      expect(at(DateTime(2024, 2, 29, 6, 7)), 'Feb 29, 2024 at 6:07 AM');
    });
  });

  test('a UTC time is converted to local before it is formatted', () {
    final local = DateTime(2020, 5, 6, 8, 9);
    expect(
      formatCreatedDate(local.toUtc(), now: now),
      formatCreatedDate(local, now: now),
    );
  });
}
