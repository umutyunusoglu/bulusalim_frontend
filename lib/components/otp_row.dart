import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OtpRow extends StatefulWidget {
  const OtpRow({
    required this.controllers,
    super.key,
  });

  // 6 adet controller'ı dışarıdan alıyoruz
  final List<TextEditingController> controllers;

  @override
  State<OtpRow> createState() => _OtpRowState();
}

class _OtpRowState extends State<OtpRow> {
  // Her kutu için bir FocusNode
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    // 6 tane FocusNode oluştur
    _focusNodes = List.generate(6, (index) => FocusNode());
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // Bir sonraki kutuya geç
  void _nextField(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  // Geri silme işlemi
  void _previousField(String value, int index) {
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 40.w,
          height: 40.h,
          child: TextField(
            controller: widget.controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1, // Sadece 1 karakter
            // İmleç Rengi
            cursorColor: const Color(0xFF1F4668),

            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 20.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),

            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: const Color(0xFFF1F1F5),
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4.r),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4.r),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4.r),
                borderSide: BorderSide.none,
              ),
            ),

            // Yazıldığında
            onChanged: (value) {
              if (value.isNotEmpty) {
                _nextField(value, index);
              } else {
                _previousField(value, index);
              }
            },
            // Geri silme
            onEditingComplete: () {
              if (index < 5) _focusNodes[index + 1].requestFocus();
            },
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
          ),
        );
      }),
    );
  }
}
