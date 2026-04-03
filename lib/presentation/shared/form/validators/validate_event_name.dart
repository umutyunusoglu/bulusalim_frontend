String? validateEventName(String? value) {
  if (value == null || value.trim().isEmpty) return 'Buluşma adı boş olamaz';
  if (value.trim().length > 128) return 'En fazla 128 karakter olmalı';
  return null;
}
