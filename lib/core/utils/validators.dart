class Validators {
  static String? validateEmail(String? value) {
    // print('Validating email: "$value"');
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    // print('Validating password: "$value"');
    if (value == null || value.trim().isEmpty) {
      return 'Password is required';
    }
    if (value.trim().length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  static String? validateName(String? value) {
    // print('Validating name: "$value"');
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  static String? validateUniversityNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your university number';
    }
    if (!RegExp(r'^\d{7}$').hasMatch(value)) {
      return 'University number must be exactly 7 digits';
    }
    return null;
  }

  static String? validateRequired(String? value) {
    // print('Validating required field: "$value"');
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  static String? validatePhoneNumber(String? value) {
    // print('Validating phone number: "$value"');
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^\+?\d{8,15}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Enter a valid phone number (8-15 digits, optional +)';
    }
    return null;
  }
}
