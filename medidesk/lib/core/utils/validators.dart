abstract final class Validators {
  static String? required(String? value, {String? label}) {
    if (value == null || value.trim().isEmpty) {
      return '${label ?? 'This field'} is required';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone is required';
    final cleaned = value.replaceAll(RegExp(r'[\s\-()]'), '');
    if (!RegExp(r'^(\+?88)?01[3-9]\d{8}$').hasMatch(cleaned)) {
      return 'Enter a valid Bangladeshi phone number';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? positiveNumber(String? value, {String? label}) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final n = double.tryParse(value);
    if (n == null || n <= 0) {
      return '${label ?? 'Value'} must be a positive number';
    }
    return null;
  }

  static String? integer(String? value, {String? label, int? min, int? max}) {
    if (value == null || value.trim().isEmpty) return null;
    final n = int.tryParse(value);
    if (n == null) return '${label ?? 'Value'} must be a whole number';
    if (min != null && n < min) return '${label ?? 'Value'} must be ≥ $min';
    if (max != null && n > max) return '${label ?? 'Value'} must be ≤ $max';
    return null;
  }
}
