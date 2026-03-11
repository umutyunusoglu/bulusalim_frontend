String? validateBio(String value) {
  if (value.length > 160) return 'En fazla 160 karakter olmalı';
  return null;
}
