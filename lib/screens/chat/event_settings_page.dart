import 'package:bulusalim/components/stacked_avatars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class EventSettingsPage extends StatefulWidget {
  const EventSettingsPage({
    required this.eventID,
    required this.chatTitle,
    required this.participantAvatars,
    required this.location,
    required this.participantStatus,
    required this.remainingTime,
    this.isCreator = true,
    super.key,
  });

  final String eventID;
  final String chatTitle;
  final List<AvatarInfo> participantAvatars;
  final String location;
  final String participantStatus;
  final String remainingTime;
  final bool isCreator;

  @override
  State<EventSettingsPage> createState() => _EventSettingsPageState();
}

class _EventSettingsPageState extends State<EventSettingsPage> {
  bool isLocked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER
            _buildCustomHeader(context),

            // 2. AYARLAR İÇERİĞİ
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Etkinlik Ayarları',
                        style: TextStyle(
                          fontFamily: 'Urbanist',
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    SizedBox(height: 30.h),

                    // Etkinlik Konumu
                    _buildInfoRow(
                      'Etkinlik Konumu',
                      widget.location,
                      icon: Icons.location_on_outlined,
                    ),
                    _buildDivider(),

                    // Etkinlik Zamanı
                    _buildInfoRow(
                      'Etkinlik Zamanı',
                      '15.30 - 18.30',
                      icon: Icons.access_time,
                      isTime: true,
                    ),
                    SizedBox(height: 30.h),

                    // Etkinliği Kilitle
                    _buildSwitchRow(
                      'Etkinliği Kilitle',
                      'Etkinliğin diğer kullanıcıların karşısına çıkmasını engellersin.',
                      isLocked,
                      (val) => setState(() => isLocked = val),
                    ),
                    _buildDivider(),

                    // Katılımcı Seçenekleri
                    _buildActionRow(
                      'Katılımcı Seçenekleri',
                      subtitle:
                          'Etkinliğin hangi kullanıcıların karşısına çıkacağını düzenlersin.',
                    ),
                    _buildDivider(),

                    // Etkinliği Bildir
                    _buildActionRow('Etkinliği Bildir'),
                    _buildDivider(),

                    // Etkinlikten Ayrıl
                    _buildActionRow(
                      'Etkinlikten Ayrıl',
                      textColor: const Color(0xFFFF5722),
                    ),
                    _buildDivider(),

                    // Etkinliği İptal Et
                    if (widget.isCreator)
                      _buildActionRow(
                        'Etkinliği İptal Et',
                        textColor: const Color(0xFFFF5722),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETLAR ---

  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Icon(
              Icons.keyboard_backspace,
              color: Colors.blueGrey,
              size: 28.sp,
            ),
          ),
          SizedBox(width: 8.w),

          SizedBox(
            height: 40.h,
            child: StackedAvatars(avatarDataList: widget.participantAvatars),
          ),
          SizedBox(width: 10.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chatTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Urbanist',
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                    color: Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 12.sp,
                      color: Colors.grey,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        '${widget.location} • ${widget.participantStatus} • ${widget.remainingTime}',
                        style: TextStyle(
                          fontFamily: 'Urbanist',
                          fontSize: 11.sp,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // GÜNCELLENDİ: Font özellikleri uygulandı
  Widget _buildInfoRow(
    String title,
    String value, {
    IconData? icon,
    bool isTime = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Urbanist',
              fontSize: 16.sp, // 16px
              fontWeight: FontWeight.w500, // Medium (500)
              height: 1, // Line Height %100
              letterSpacing: 0, // Letter Spacing 0
              color: Colors.black87,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: isTime ? const Color(0xFFD8EED9) : const Color(0xFFD4E2EB),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              children: [
                if (icon != null)
                  Icon(icon, size: 16.sp, color: Colors.grey.shade700),
                if (icon != null) SizedBox(width: 6.w),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Urbanist',
                    fontSize: 13.sp,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // GÜNCELLENDİ: Font özellikleri uygulandı
  Widget _buildSwitchRow(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Urbanist',
                    fontSize: 16.sp, // 16px
                    fontWeight: FontWeight.w500, // Medium
                    height: 1, // %100
                    letterSpacing: 0,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Urbanist',
                    fontSize: 12.sp,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFFFF5722),
          ),
        ],
      ),
    );
  }

  // GÜNCELLENDİ: Font özellikleri uygulandı
  Widget _buildActionRow(String title, {String? subtitle, Color? textColor}) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Urbanist',
                fontSize: 16.sp, // 16px
                // Eğer özel renk (kırmızı) varsa da w500, yoksa da w500
                fontWeight: FontWeight.w500,
                height: 1, // %100
                letterSpacing: 0,
                color: textColor ?? Colors.black87,
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(height: 4.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Urbanist',
                  fontSize: 12.sp,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(color: Colors.grey.shade200, thickness: 1);
  }
}
