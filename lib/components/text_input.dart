import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TextInput extends StatelessWidget {
  const TextInput({
    super.key,
    this.controller,
    this.hintText,
    this.title,
    this.iconData,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
  });

  final TextEditingController? controller;
  final String? hintText;
  final String? title;
  final IconData? iconData;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Tema rengi yoksa varsayılan açık gri kullanılır (Görseldeki gibi)
    final fillColor =
        theme.inputDecorationTheme.fillColor ?? Colors.grey.shade100;

    // Border Helper: İstenilen duruma göre border oluşturur
    // isVisible: false ise kenarlık çizgisini yok eder (Sadece radius kalır)
    OutlineInputBorder getBorder({Color? color, bool isVisible = false}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(40.r),
        borderSide: isVisible
            ? BorderSide(color: color ?? colorScheme.primary, width: 1.5)
            : BorderSide.none,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8.h), // Başlık ile input arası boşluk
        ],

        // --- INPUT ALANI ---
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,

          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),

          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor,
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.shade500),

            contentPadding: EdgeInsets.symmetric(
              vertical: 16.h,
              horizontal: 24.w,
            ),

            // İkon varsa sol tarafa ekler
            prefixIcon: iconData != null
                ? Padding(
                    padding: EdgeInsets.only(left: 12.w, right: 8.w),
                    child: Icon(iconData, size: 22.sp),
                  )
                : null,
            prefixIconColor: colorScheme.primary,

            // --- BORDER AYARLARI ---

            // 1. Normal Durum (Enabled): Çizgi YOK, sadece dolgu ve radius var.
            enabledBorder: getBorder(isVisible: false),

            // 2. Odaklanma (Focus): Temanın renginde çizgi VAR.
            focusedBorder: getBorder(
              color:
                  theme.inputDecorationTheme.focusedBorder?.borderSide.color ??
                  colorScheme.primary,
              isVisible: true,
            ),

            // 3. Hata Durumu (Error): Kırmızı çizgi VAR.
            errorBorder: getBorder(
              color: colorScheme.error,
              isVisible: true,
            ),

            // 4. Odaklanmış Hata: Kalın kırmızı çizgi VAR.
            focusedErrorBorder: getBorder(
              color: colorScheme.error,
              isVisible: true,
            ),
          ),
        ),
      ],
    );
  }
}
