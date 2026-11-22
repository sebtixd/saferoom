/// Utility class for form validation
class Validators {
  Validators._();

  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Validate password (minimum 6 characters)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validate confirm password
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate mood value (1-10)
  static String? validateMoodValue(int? value) {
    if (value == null) {
      return 'Please select a value';
    }
    if (value < 1 || value > 10) {
      return 'Value must be between 1 and 10';
    }
    return null;
  }

  /// Validate journal entry (minimum 10 characters)
  static String? validateJournalEntry(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please write something';
    }
    if (value.length < 10) {
      return 'Entry must be at least 10 characters';
    }
    return null;
  }
}
