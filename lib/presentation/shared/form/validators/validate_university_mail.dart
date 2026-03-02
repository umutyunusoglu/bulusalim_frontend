String? validateUniversityMail(String? email, String? detectedUniversity) {
  if (email == null) return 'Mail adresi boş olamaz';
  if (email.isEmpty) return 'Mail adresi boş olamaz';

  if (detectedUniversity == null) {
    return 'Tanınan bir üniversite maili giriniz';
  }
  return null;
}
