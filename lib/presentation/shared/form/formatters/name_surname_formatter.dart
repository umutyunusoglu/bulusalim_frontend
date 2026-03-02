import 'package:flutter/services.dart';
import 'package:outnest/presentation/shared/form/formatters/title_case_formatter.dart';

class NameSurnameFormatter extends TextInputFormatter {
  final _allowRegex = FilteringTextInputFormatter.allow(
    RegExp(r"[a-zA-ZğüşöçıİĞÜŞÖÇ\s'-]"),
  );

  final _titleCase = TitleCaseFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 1. Önce istenmeyen karakterleri filtrele
    final filteredValue = _allowRegex.formatEditUpdate(oldValue, newValue);

    // 2. Ardından TitleCase formatını uygula
    return _titleCase.formatEditUpdate(oldValue, filteredValue);
  }
}
