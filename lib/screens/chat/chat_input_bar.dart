import 'package:bulusalim/core/constants/theme/color_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    required this.onSend,
    super.key,
  });

  final Function(String) onSend;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _textController = TextEditingController();

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    widget.onSend(text);
    _textController.clear();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 10.h,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 10.h : 34.h,
      ),
      child: Container(
        constraints: BoxConstraints(minHeight: 52.h, maxHeight: 150.h),

        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(30.r),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // INPUT ALANI
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 12.w, right: 8.w),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(context).colorScheme.copyWith(
                      primary: AppColors.secondaryColor,
                    ),
                    textSelectionTheme: TextSelectionThemeData(
                      cursorColor: AppColors.secondaryColor,
                      selectionColor: AppColors.secondaryColor.withOpacity(0.3),
                      selectionHandleColor: AppColors.secondaryColor,
                    ),
                  ),
                  child: Scrollbar(
                    child: TextField(
                      controller: _textController,
                      cursorColor: AppColors.secondaryColor,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontFamily: 'SF Pro Display',
                        color: Colors.black87,
                      ),

                      textInputAction: TextInputAction.newline,
                      keyboardType: TextInputType.multiline,

                      decoration: InputDecoration(
                        hintText: 'Buraya yaz...',
                        hintStyle: TextStyle(
                          color: AppColors.textGrey.withOpacity(0.6),
                          fontSize: 15.sp,
                        ),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                      ),

                      // SATIR AYARLARI
                      minLines: 1,
                      maxLines: null,
                    ),
                  ),
                ),
              ),
            ),

            // GÖNDER BUTONU
            Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: GestureDetector(
                onTap: _handleSend,
                child: Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: const BoxDecoration(
                    color: AppColors.secondaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_upward,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
