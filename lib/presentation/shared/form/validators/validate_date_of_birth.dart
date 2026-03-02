String? validateDateOfBirth(DateTime? dateOfBirth) {
  if (dateOfBirth == null) {
    return 'Lütfen doğum tarihinizi seçin';
  }
  // Bugünün tarihi
  final now = DateTime.now();
  //TODO: 28 şubat
  // 18 yıl önceki aynı günün tarihi
  final eighteenYearsAgo = DateTime(
    now.year - 18,
    now.month,
    now.day,
  );

  // Eğer seçilen tarih, 18 yıl önceki tarihten sonra ise (yani daha gençse)
  if (dateOfBirth!.isAfter(eighteenYearsAgo)) {
    return "Outnest'e katılmak için 18 yaşını doldurmuş olmalısın";
  }

  return null; // Her şey yolunda
}
