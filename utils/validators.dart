class Validators {
  static String? validateFullName(String? v) =>
      (v == null || v.isEmpty) ? 'Required' : null;

  static String? validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$').hasMatch(v)) {
      return 'Email must end with @gmail.com and be spelled correctly';
    }
    return null;
  }

  static String? validatePhone(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    if (!RegExp(r'^[79]\d{7}$').hasMatch(v)) {
      return 'Phone number must start with 7 or 9 and be 8 digits long';
    }
    return null;
  }

  static String? validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'At least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Must contain uppercase letter';
    if (!RegExp(r'[a-z]').hasMatch(v)) return 'Must contain lowercase letter';
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Must contain a number';
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(v)) {
      return 'Must contain special character';
    }
    return null; 
  }
}
