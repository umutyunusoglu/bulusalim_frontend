import 'package:flutter/material.dart';
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
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final int? maxLength;
  final bool readOnly;
  final VoidCallback? onTap;
  final Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        // Etiket ve Input her zaman dikeyde ortalı
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // --- SOL TARAF: ETİKET (TIKLANAMAZ) ---
          SizedBox(
            width: 110.w,
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

          // --- SAĞ TARAF: INPUT (TIKLANABİLİR ALAN) ---
          Expanded(
            child: InkWell(
              onTap: onTap,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              child: IgnorePointer(
                ignoring: readOnly,
                child: TextField(
                  controller: controller,
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
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    filled: false,
                    fillColor: Colors.transparent,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,

                    counterText: maxLength != null ? null : '',
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
                        return Container(
                          alignment: Alignment.centerRight,
                          margin: EdgeInsets.only(top: 2.h),
                          child: Text(
                            "$currentLength/$maxLength",
                            style: TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 10.sp,
                              color: Colors.grey,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
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
