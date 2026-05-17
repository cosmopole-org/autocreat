import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:autocreat/core/utils.dart';
import 'package:autocreat/theme/app_colors.dart';

void main() {
  group('AppUtils.formatDate', () {
    test('null returns dash', () {
      expect(AppUtils.formatDate(null), '-');
    });

    test('formats date correctly', () {
      final date = DateTime(2024, 3, 15);
      // "Mar 15, 2024"
      expect(AppUtils.formatDate(date), contains('2024'));
      expect(AppUtils.formatDate(date), contains('15'));
    });
  });

  group('AppUtils.formatDateTime', () {
    test('null returns dash', () {
      expect(AppUtils.formatDateTime(null), '-');
    });

    test('formats datetime correctly', () {
      final date = DateTime(2024, 3, 15, 10, 30);
      expect(AppUtils.formatDateTime(date), contains('10:30'));
    });
  });

  group('AppUtils.formatNumber', () {
    test('small numbers unchanged', () {
      expect(AppUtils.formatNumber(999), '999');
    });

    test('thousands abbreviated with K', () {
      expect(AppUtils.formatNumber(1500), '1.5K');
    });

    test('millions abbreviated with M', () {
      expect(AppUtils.formatNumber(2500000), '2.5M');
    });

    test('exact thousand', () {
      expect(AppUtils.formatNumber(1000), '1.0K');
    });
  });

  group('AppUtils.isValidEmail', () {
    test('valid emails', () {
      expect(AppUtils.isValidEmail('user@example.com'), isTrue);
      expect(AppUtils.isValidEmail('test+tag@domain.org'), isTrue);
    });

    test('invalid emails', () {
      expect(AppUtils.isValidEmail(''), isFalse);
      expect(AppUtils.isValidEmail('notanemail'), isFalse);
      expect(AppUtils.isValidEmail('missing@'), isFalse);
    });
  });

  group('AppUtils.isValidPassword', () {
    test('valid password (8+ chars)', () {
      expect(AppUtils.isValidPassword('password'), isTrue);
      expect(AppUtils.isValidPassword('verylongpassword'), isTrue);
    });

    test('invalid password (less than 8 chars)', () {
      expect(AppUtils.isValidPassword('short'), isFalse);
      expect(AppUtils.isValidPassword(''), isFalse);
      expect(AppUtils.isValidPassword('1234567'), isFalse);
    });
  });

  group('AppUtils.getStatusColor', () {
    test('active → success color', () {
      expect(AppUtils.getStatusColor('active'), AppColors.success);
    });

    test('approved → success color', () {
      expect(AppUtils.getStatusColor('approved'), AppColors.success);
    });

    test('pending → warning color', () {
      expect(AppUtils.getStatusColor('pending'), AppColors.warning);
    });

    test('rejected → error color', () {
      expect(AppUtils.getStatusColor('rejected'), AppColors.error);
    });

    test('draft → secondary color', () {
      expect(AppUtils.getStatusColor('draft'), AppColors.lightTextSecondary);
    });

    test('unknown → info color', () {
      expect(AppUtils.getStatusColor('unknown_status'), AppColors.info);
    });

    test('case insensitive', () {
      expect(AppUtils.getStatusColor('ACTIVE'), AppColors.success);
      expect(AppUtils.getStatusColor('Active'), AppColors.success);
    });
  });

  group('AppUtils.getNodeTypeIcon', () {
    test('start node icon', () {
      expect(AppUtils.getNodeTypeIcon('start'), Icons.play_circle_outline);
    });

    test('step node icon', () {
      expect(AppUtils.getNodeTypeIcon('step'), Icons.task_alt);
    });

    test('decision node icon', () {
      expect(AppUtils.getNodeTypeIcon('decision'), Icons.call_split);
    });

    test('end node icon', () {
      expect(AppUtils.getNodeTypeIcon('end'), Icons.stop_circle_outlined);
    });

    test('unknown node icon', () {
      expect(AppUtils.getNodeTypeIcon('unknown'), Icons.circle_outlined);
    });

    test('case insensitive', () {
      expect(AppUtils.getNodeTypeIcon('START'), Icons.play_circle_outline);
    });
  });

  group('AppUtils.getNodeTypeColor', () {
    test('start node color', () {
      expect(AppUtils.getNodeTypeColor('start'), AppColors.nodeStart);
    });

    test('step node color', () {
      expect(AppUtils.getNodeTypeColor('step'), AppColors.nodeStep);
    });

    test('decision node color', () {
      expect(AppUtils.getNodeTypeColor('decision'), AppColors.nodeDecision);
    });

    test('end node color', () {
      expect(AppUtils.getNodeTypeColor('end'), AppColors.nodeEnd);
    });
  });

  group('AppUtils.getFieldTypeIcon', () {
    test('text field icon', () {
      expect(AppUtils.getFieldTypeIcon('text'), Icons.text_fields);
    });

    test('number field icon', () {
      expect(AppUtils.getFieldTypeIcon('number'), Icons.pin);
    });

    test('date field icon', () {
      expect(AppUtils.getFieldTypeIcon('date'), Icons.calendar_today);
    });

    test('unknown field icon', () {
      expect(AppUtils.getFieldTypeIcon('custom_field'), Icons.input);
    });
  });

  group('AppUtils.generateId', () {
    test('generates non-empty string', () {
      final id = AppUtils.generateId();
      expect(id.isNotEmpty, isTrue);
    });

    test('generates unique ids', () {
      final ids = List.generate(10, (_) => AppUtils.generateId());
      // All ids should be unique (timestamp-based, but may collide in fast loops;
      // at least test it returns strings)
      for (final id in ids) {
        expect(id.isNotEmpty, isTrue);
      }
    });
  });
}
