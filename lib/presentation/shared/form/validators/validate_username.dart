String? validateUsername(String? username) {
  if (username == null) return 'Kullanıcı adı boş olamaz';
  if (username.isEmpty) return 'Kullanıcı adı boş olamaz';

  // 2. Uzunluk kontrolü
  if (username.length < 3) return 'En az 3 karakter olmalı';
  if (username.length > 30) return 'En fazla 30 karakter olmalı';
  // 3. Karakter kontrolü (Küçük harf, rakam, nokta ve alt tire)
  // ^ : Başlangıç, $ : Bitiş, [a-z0-0._] : İzin verilenler, + : En az bir tane
  final usernameRegExp = RegExp(r'^[a-z0-9._]+$');

  if (!usernameRegExp.hasMatch(username)) {
    return 'Sadece küçük harf, rakam, "." ve "_" kullanabilirsiniz';
  }

  return null;
}
