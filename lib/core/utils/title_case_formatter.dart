import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TitleCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    // Metni kelimelere ayır ve her birinin ilk harfini büyüt
    final String capitalizedText = newValue.text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() +
              word.substring(1).toLowerCase(); // .toLowerCase() opsiyoneldir
        })
        .join(' ');

    return TextEditingValue(
      text: capitalizedText,
      // Kullanıcının imleç yerini (selection) koruyoruz
      selection: newValue.selection,
    );
  }
}
