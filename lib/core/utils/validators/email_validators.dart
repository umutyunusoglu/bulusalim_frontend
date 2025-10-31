bool isValidEmail(String email) {
  // Basic email validation regex
  final emailRegex = RegExp(
    // ? Is this regex sufficient for email validation?
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  return emailRegex.hasMatch(email);
}
