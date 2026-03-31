String? validatePostCaption(String? value) {
  if (value != null && value.trim().length > 64) {
    return 'En fazla 64 karakter olmalı';
  }
  return null;
}
