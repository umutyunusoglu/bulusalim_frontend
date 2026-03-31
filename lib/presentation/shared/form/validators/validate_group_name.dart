String? validateGroupName(String? value) {
  if (value == null || value.trim().isEmpty) return 'Küme adı boş olamaz';
  if (value.length > 32) return 'En fazla 32 karakter olmalı';
  return null;
}
