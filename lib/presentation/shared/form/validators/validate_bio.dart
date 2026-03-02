String? validateBio(String? value) {
  if (value == null) return 'Biyografi boş olamaz';
  if (value.isEmpty) return 'Biyografi boş olamaz';
  if (value.length < 10) return 'En az 10 karakter olmalı';
  if (value.length > 160) return 'En fazla 160 karakter olmalı';
  return null;
}
