import 'package:bulusalim/core/constants/constant.dart';
import 'package:flutter/material.dart';

// LoginButton artık bir StatefulWidget'tır
class LoginButton extends StatefulWidget {
  const LoginButton({
    required this.label,
    required this.onPress,
    required this.height,
    required this.borderWidth,
    required this.borderRadius,
    required this.width,
    super.key,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
  });
  final String label;
  final VoidCallback onPress;
  final double height;
  final double borderWidth;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final double? width;

  @override
  State<LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<LoginButton> {
  // Widget durumuna (State) özgü değişkenleri burada tutabilirsiniz,
  // örneğin tıklanma anında rengini değiştirmek gibi.
  // Şu an için sadece görsel düzenlemeleri yapıyoruz.

  @override
  Widget build(BuildContext context) {
    // Border rengi sağlanmamışsa varsayılan olarak gri bir renk kullanır
    // (Aksi halde widget.borderColor! kullanımı null hatası verecektir)
    final resolvedBorderColor = widget.borderColor ?? const Color(0xFF5B7A98);

    return GestureDetector(
      onTap: widget.onPress,
      child: Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? Colors.white, // Arkaplan rengi
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: resolvedBorderColor,
            width: widget.borderWidth,
          ),
        ),

        // InkWell'ı doğrudan Container'ın üzerine yerleştiriyoruz
        child: Material(
          color: Colors.transparent, // Material'ın rengi şeffaf olmalı
          child: InkWell(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            onTap: widget.onPress, // Tıklama fonksiyonu
            child: Center(
              child: Text(
                widget.label,
                style: TextStyle(
                  color:
                      widget.textColor ?? kButtonBackgroundColor, // Metin rengi
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
