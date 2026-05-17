import 'package:flutter_test/flutter_test.dart';
import 'package:autocreat/core/extensions.dart';

void main() {
  group('StringExt', () {
    test('capitalize - empty string', () {
      expect(''.capitalize, '');
    });

    test('capitalize - single char', () {
      expect('a'.capitalize, 'A');
    });

    test('capitalize - word', () {
      expect('hello'.capitalize, 'Hello');
    });

    test('capitalize - already capitalized', () {
      expect('Hello'.capitalize, 'Hello');
    });

    test('titleCase - single word', () {
      expect('hello'.titleCase, 'Hello');
    });

    test('titleCase - multiple words', () {
      expect('hello world'.titleCase, 'Hello World');
    });

    test('isValidEmail - valid email', () {
      expect('user@example.com'.isValidEmail, isTrue);
      expect('user.name+tag@sub.example.co.uk'.isValidEmail, isTrue);
    });

    test('isValidEmail - invalid email', () {
      expect('not-an-email'.isValidEmail, isFalse);
      expect('missing@'.isValidEmail, isFalse);
      expect('@missing.com'.isValidEmail, isFalse);
      expect(''.isValidEmail, isFalse);
    });

    test('truncate - short string unchanged', () {
      expect('hello'.truncate(10), 'hello');
    });

    test('truncate - long string gets ellipsis', () {
      expect('hello world'.truncate(5), 'hello...');
    });

    test('truncate - exactly at limit unchanged', () {
      expect('hello'.truncate(5), 'hello');
    });
  });

  group('DateTimeExt', () {
    test('formatted - correct format', () {
      final date = DateTime(2024, 3, 15);
      expect(date.formatted, '2024-03-15');
    });

    test('formatted - pads single digit month and day', () {
      final date = DateTime(2024, 1, 5);
      expect(date.formatted, '2024-01-05');
    });

    test('formattedWithTime - includes time', () {
      final date = DateTime(2024, 3, 15, 9, 5);
      expect(date.formattedWithTime, '2024-03-15 09:05');
    });

    test('timeAgo - just now', () {
      final now = DateTime.now();
      expect(now.timeAgo, 'just now');
    });

    test('timeAgo - minutes ago', () {
      final past = DateTime.now().subtract(const Duration(minutes: 30));
      expect(past.timeAgo, '30m ago');
    });

    test('timeAgo - hours ago', () {
      final past = DateTime.now().subtract(const Duration(hours: 3));
      expect(past.timeAgo, '3h ago');
    });

    test('timeAgo - days ago', () {
      final past = DateTime.now().subtract(const Duration(days: 3));
      expect(past.timeAgo, '3d ago');
    });

    test('timeAgo - older than a week shows formatted date', () {
      final past = DateTime(2024, 1, 1);
      expect(past.timeAgo, past.formatted);
    });
  });
}
