import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

class AppUtils {
  static String formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }

  static String formatCurrency(double amount, {String symbol = '\$'}) {
    return NumberFormat.currency(symbol: symbol, decimalDigits: 2).format(amount);
  }

  static String formatNumber(num number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'approved':
      case 'completed':
      case 'done':
        return AppColors.success;
      case 'pending':
      case 'waiting':
      case 'in_progress':
        return AppColors.warning;
      case 'rejected':
      case 'failed':
      case 'error':
        return AppColors.error;
      case 'draft':
      case 'inactive':
        return AppColors.lightTextSecondary;
      default:
        return AppColors.info;
    }
  }

  static IconData getFieldTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'text':
        return Icons.text_fields;
      case 'number':
        return Icons.pin;
      case 'textarea':
        return Icons.notes;
      case 'dropdown':
        return Icons.arrow_drop_down_circle_outlined;
      case 'multiselect':
        return Icons.checklist;
      case 'checkbox':
        return Icons.check_box_outlined;
      case 'radio':
        return Icons.radio_button_checked;
      case 'date':
        return Icons.calendar_today;
      case 'time':
        return Icons.access_time;
      case 'file':
        return Icons.attach_file;
      case 'image':
        return Icons.image_outlined;
      case 'color':
        return Icons.color_lens_outlined;
      case 'switch':
        return Icons.toggle_on_outlined;
      case 'table':
        return Icons.table_chart_outlined;
      case 'rating':
        return Icons.star_outline;
      case 'signature':
        return Icons.draw_outlined;
      default:
        return Icons.input;
    }
  }

  static IconData getNodeTypeIcon(String type) {
    switch (type.toUpperCase()) {
      case 'START':
        return Icons.play_circle_outline;
      case 'STEP':
        return Icons.task_alt;
      case 'DECISION':
        return Icons.call_split;
      case 'END':
        return Icons.stop_circle_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  static Color getNodeTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'START':
        return AppColors.nodeStart;
      case 'STEP':
        return AppColors.nodeStep;
      case 'DECISION':
        return AppColors.nodeDecision;
      case 'END':
        return AppColors.nodeEnd;
      default:
        return AppColors.lightTextSecondary;
    }
  }

  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidPassword(String password) {
    return password.length >= 8;
  }
}
