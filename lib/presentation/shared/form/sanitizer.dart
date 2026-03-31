/// Sanitizer for general free-text fields.
/// e.g. bio, chat messages, event name/description, post caption, group name.
String sanitizeInput(String input) {
  var sanitized = input.trim();

  sanitized = sanitized
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#x27;');

  sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');

  return sanitized;
}

/// Sanitizer for URL fields.
/// e.g. social media links, event links, website URLs.
/// Preserves URL-valid characters like &, ?, = while blocking dangerous schemes.
String sanitizeUrl(String input) {
  var sanitized = input.trim();

  // Remove control characters
  sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');

  // Block dangerous URI schemes (javascript:, data:, vbscript:)
  final lower = sanitized.toLowerCase();
  if (lower.startsWith('javascript:') ||
      lower.startsWith('data:') ||
      lower.startsWith('vbscript:')) {
    return '';
  }

  return sanitized;
}

/// Sanitizer for email fields.
/// e.g. contact email for communities.
String sanitizeEmail(String input) {
  var sanitized = input.trim().toLowerCase();

  // Remove control characters
  sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');

  // Remove characters that should not appear in email addresses
  sanitized = sanitized.replaceAll(RegExp(r'[<>"{}|\\^`\s]'), '');

  return sanitized;
}
