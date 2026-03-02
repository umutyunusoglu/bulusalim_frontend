String? validateNameSurname(String? value) {
  if (value == null) return 'Ad - Soyad boş olamaz';
  if (value.isEmpty) return 'Ad - Soyad boş olamaz';

  final words = value.split(' ').where((w) => w.isNotEmpty).toList();
  if (words.length < 2) {
    return 'Lütfen adınızı ve soyadınızı tam giriniz';
  }

  if (value.length < 2) return 'En az 2 karakter olmalı';
  if (value.length > 50) return 'En fazla 50 karakter olmalı';

  return null;
}
