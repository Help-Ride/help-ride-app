import 'package:email_validator/email_validator.dart';

class InputValidators {
  static String? requiredText(String value, {required String fieldLabel}) {
    if (value.trim().isEmpty) {
      return '$fieldLabel is required.';
    }
    return null;
  }

  static String? email(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Email is required.';
    if (!EmailValidator.validate(trimmed)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? password(String value, {int minLength = 8}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Password is required.';
    if (trimmed.length < minLength) {
      return 'Password must be at least $minLength characters.';
    }
    return null;
  }

  static String? otpCode(String value, {int length = 6}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Verification code is required.';
    if (!RegExp(r'^\d+$').hasMatch(trimmed)) {
      return 'Code must contain only digits.';
    }
    if (trimmed.length != length) {
      return 'Enter the $length-digit code.';
    }
    return null;
  }

  static String? positiveInt(
    String value, {
    required String fieldLabel,
    int min = 1,
  }) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '$fieldLabel is required.';
    final parsed = int.tryParse(trimmed);
    if (parsed == null) return '$fieldLabel must be a whole number.';
    if (parsed < min) return '$fieldLabel must be at least $min.';
    return null;
  }

  static String? nonNegativeDecimal(
    String value, {
    required String fieldLabel,
  }) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '$fieldLabel is required.';
    final parsed = double.tryParse(trimmed);
    if (parsed == null) return '$fieldLabel must be a valid number.';
    if (parsed < 0) return '$fieldLabel can not be negative.';
    return null;
  }

  static String? optionalName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.length < 2) return 'Name must be at least 2 characters.';
    return null;
  }

  static String? optionalPhone(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (!RegExp(r'^[0-9+\-()\s]{7,20}$').hasMatch(trimmed)) {
      return 'Enter a valid phone number.';
    }
    return null;
  }

  static String? optionalUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.host.trim().isEmpty) {
      return 'Enter a valid URL (for example, https://example.com).';
    }
    return null;
  }

  static String? optionalYear(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (!RegExp(r'^\d{4}$').hasMatch(trimmed)) {
      return 'Enter a valid 4-digit year.';
    }
    final year = int.parse(trimmed);
    final maxYear = DateTime.now().year + 1;
    if (year < 1900 || year > maxYear) {
      return 'Year must be between 1900 and $maxYear.';
    }
    return null;
  }

  static String? minLength(
    String value, {
    required String fieldLabel,
    required int minChars,
  }) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '$fieldLabel is required.';
    if (trimmed.length < minChars) {
      return '$fieldLabel must be at least $minChars characters.';
    }
    return null;
  }
}
