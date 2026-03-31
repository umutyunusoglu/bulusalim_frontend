/// Sanitizer for general free-text fields.
/// e.g. bio, chat messages, event name/description, post caption, group name.
/// Trims whitespace and strips control characters.
String sanitizeInput(String input) {
  var sanitized = input.trim();

  // Remove control characters (U+0000–U+001F except tab, newline, carriage return)
  sanitized =
      sanitized.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');

  return sanitized;
}

/// Sanitizer for URL fields.
/// e.g. social media links, event links, website URLs.
/// Returns null if the URL uses a dangerous scheme or is not parseable.
/// Only allows http and https schemes.
String? sanitizeUrl(String input) {
  var sanitized = input.trim();

  // Remove control characters
  sanitized =
      sanitized.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');

  if (sanitized.isEmpty) return sanitized;

  final uri = Uri.tryParse(sanitized);
  if (uri == null) return null;

  // Only allow http/https schemes, or no scheme (relative URLs)
  if (uri.hasScheme && uri.scheme != 'http' && uri.scheme != 'https') {
    return null;
  }

  return sanitized;
}

/// Sanitizer for email fields.
/// e.g. contact email for communities.
String sanitizeEmail(String input) {
  var sanitized = input.trim().toLowerCase();

  // Remove control characters
  sanitized =
      sanitized.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');

  // Remove characters that should not appear in email addresses
  sanitized = sanitized.replaceAll(RegExp(r'[<>"{}|\\^`\s]'), '');

  return sanitized;
}

/// Sanitizer for username fields.
/// Only allows lowercase letters, digits, dots and underscores.
String sanitizeUsername(String input) {
  var sanitized = input.trim().toLowerCase();

  // Remove control characters
  sanitized =
      sanitized.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');

  // Strip everything except allowed username characters
  sanitized = sanitized.replaceAll(RegExp(r'[^a-z0-9._]'), '');

  return sanitized;
}

/// Sanitizer for name/surname fields.
/// Only allows letters (including Turkish characters), spaces, apostrophes and hyphens.
String sanitizeName(String input) {
  var sanitized = input.trim();

  // Remove control characters
  sanitized =
      sanitized.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');

  // Strip everything except allowed name characters
  sanitized = sanitized.replaceAll(RegExp(r"[^a-zA-ZğüşöçıİĞÜŞÖÇ\s'\-]"), '');

  return sanitized;
}

/// Sanitizer for phone number fields.
/// Only allows digits.
String sanitizePhone(String input) {
  return input.replaceAll(RegExp(r'[^\d]'), '');
}
