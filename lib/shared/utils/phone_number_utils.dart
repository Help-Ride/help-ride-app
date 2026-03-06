import 'dart:math' as math;

import 'package:flutter/services.dart';

class PhoneNumberUtils {
  static final RegExp _nonDigit = RegExp(r'\D');
  static final RegExp _internationalInput = RegExp(r'^\+\d*$');

  static String digitsOnly(String value) {
    return value.replaceAll(_nonDigit, '');
  }

  static String? normalizeToE164(String value) {
    var trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('00')) {
      trimmed = '+${trimmed.substring(2)}';
    }

    if (_internationalInput.hasMatch(trimmed)) {
      final digits = digitsOnly(trimmed);
      if (digits.length < 8 || digits.length > 15) return null;
      return '+$digits';
    }

    final digits = digitsOnly(trimmed);
    if (digits.length == 10) return '+1$digits';
    if (digits.length == 11 && digits.startsWith('1')) return '+$digits';
    return null;
  }

  static bool isValid(String value) => normalizeToE164(value) != null;

  static String formatForDisplay(String? value) {
    final normalized = normalizeToE164(value ?? '');
    if (normalized == null) {
      return value?.trim() ?? '';
    }

    if (normalized.startsWith('+1') && normalized.length == 12) {
      final local = normalized.substring(2);
      return '+1 (${local.substring(0, 3)}) '
          '${local.substring(3, 6)}-${local.substring(6)}';
    }

    return normalized;
  }

  static String maskForDisplay(String? value) {
    final normalized = normalizeToE164(value ?? '');
    if (normalized == null || normalized.length < 4) {
      return value?.trim() ?? '';
    }

    final last4 = normalized.substring(normalized.length - 4);
    if (normalized.startsWith('+1') && normalized.length == 12) {
      return '+1 (***) ***-$last4';
    }

    return '${normalized.substring(0, math.min(3, normalized.length - 4))}•••$last4';
  }

  static String formatNorthAmericaDraft(String digits) {
    if (digits.isEmpty) return '';

    final limited = digits.substring(0, math.min(digits.length, 11));
    final hasCountryCode = limited.startsWith('1') && limited.length > 1;
    final local = hasCountryCode ? limited.substring(1) : limited;
    final buffer = StringBuffer();

    if (hasCountryCode) {
      buffer.write('+1 ');
    }

    if (local.isEmpty) {
      return buffer.toString().trimRight();
    }

    if (local.length <= 3) {
      buffer.write('($local');
      return buffer.toString();
    }

    buffer.write('(${local.substring(0, 3)}) ');
    if (local.length <= 6) {
      buffer.write(local.substring(3));
      return buffer.toString();
    }

    buffer.write(local.substring(3, 6));
    buffer.write('-');
    buffer.write(local.substring(6, math.min(local.length, 10)));
    return buffer.toString();
  }
}

class PhoneTextInputFormatter extends TextInputFormatter {
  const PhoneTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text;
    if (raw.trim().startsWith('+') && !raw.trim().startsWith('+1')) {
      final digits = PhoneNumberUtils.digitsOnly(raw);
      final international = digits.isEmpty
          ? '+'
          : '+${digits.substring(0, math.min(digits.length, 15))}';
      return TextEditingValue(
        text: international,
        selection: TextSelection.collapsed(offset: international.length),
      );
    }

    final digits = PhoneNumberUtils.digitsOnly(raw);
    final limited = digits.substring(0, math.min(digits.length, 11));
    final formatted = PhoneNumberUtils.formatNorthAmericaDraft(limited);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
