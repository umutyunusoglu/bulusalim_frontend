import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileInputRow extends StatelessWidget {
  const ProfileInputRow({
    required this.label,
    required this.controller,
    super.key,
    this.maxLines = 1,
    this.maxLength,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.validator,
    this.formatters,
    this.canChange = true,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final int? maxLength;
  final bool readOnly;
  final bool canChange;
  final VoidCallback? onTap;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? formatters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- SOL TARAF: ETİKET (TIKLANAMAZ) ---
          SizedBox(
            width: 110.w,

            child: Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
          ),

          // --- SAĞ TARAF: INPUT (TIKLANABİLİR ALAN) ---
          Expanded(
            child: InkWell(
              onTap: onTap,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              child: IgnorePointer(
                ignoring: readOnly,
                child: TextFormField(
                  enabled: !readOnly,
                  controller: controller,
                  validator: validator,
                  inputFormatters: formatters,

                  minLines: 1,
                  maxLines: maxLines,
                  maxLength: maxLength,
                  readOnly: readOnly,
                  onChanged: onChanged,
                  cursorColor: Colors.black,

                  textAlignVertical: TextAlignVertical.center,
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: !canChange ? Colors.grey : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    filled: false,
                    fillColor: Colors.transparent,
                    isDense: true,
                    errorStyle: TextStyle(
                      fontSize: 12.sp,
                      height:
                          1.2, // Satır yüksekliğini artırır. 1.0 - 1.5 arası bir değer deneyebilirsin.
                      fontFamily: 'SF Pro Display',
                    ),
                    errorMaxLines: 2,

                    contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,

                    counterText: "",
                    hintText: '$label giriniz',
                    hintStyle: TextStyle(
                      fontFamily: 'SF Pro Display',
                      color: Colors.grey.shade400,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  buildCounter:
                      (
                        context, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) {
                        if (maxLength == null) return null;
                        return Text(
                          '$currentLength/$maxLength',
                          style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                        );
                      },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
