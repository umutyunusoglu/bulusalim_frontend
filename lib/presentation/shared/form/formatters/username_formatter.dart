import 'package:flutter/services.dart';

class UsernameFormatter extends TextInputFormatter {
  // Sadece harf, rakam, nokta ve alt çizgiye izin verir
  final _allowRegex = FilteringTextInputFormatter.allow(
    RegExp('[a-zA-Z0-9._]'),
  );

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 1. Önce karakter kısıtlamasını uygula
    final filteredValue = _allowRegex.formatEditUpdate(oldValue, newValue);

    // 2. Metni tamamen küçük harfe çevir ve döndür
    return filteredValue.copyWith(
      text: filteredValue.text.toLowerCase(),
    );
  }
}
