/// Centralized validation utilities for form fields
///
/// Usage:
/// ```dart
/// TextFormField(
///   validator: Validators.email,
/// )
/// ```
class Validators {
  // Email validation
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // Password validation
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  // Username validation
  static String? username(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }

    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Username can only contain letters, numbers, and underscores';
    }

    return null;
  }

  // Name validation
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }

    return null;
  }

  // Phone validation
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone is optional
    }

    if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(value)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  // Confirm password validation
  static String? Function(String?) confirmPassword(String originalPassword) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'Please confirm your password';
      }

      if (value != originalPassword) {
        return 'Passwords do not match';
      }

      return null;
    };
  }

  // Required field validation
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  // Min length validation
  static String? Function(String?) minLength(int length, {String? fieldName}) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return '${fieldName ?? 'This field'} is required';
      }

      if (value.length < length) {
        return '${fieldName ?? 'This field'} must be at least $length characters';
      }

      return null;
    };
  }

  // Max length validation
  static String? Function(String?) maxLength(int length, {String? fieldName}) {
    return (String? value) {
      if (value != null && value.length > length) {
        return '${fieldName ?? 'This field'} must not exceed $length characters';
      }
      return null;
    };
  }
}
