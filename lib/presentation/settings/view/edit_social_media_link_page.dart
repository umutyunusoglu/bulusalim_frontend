import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/application/service_locators/get_it_init.dart';
import 'package:outnest/domain/entities/user/user_entity.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/session_service.dart';

enum SocialLinkType { instagram, whatsapp, website, email }

class EditSocialMediaLinkPage extends StatefulWidget {
  const EditSocialMediaLinkPage({
    super.key,
    required this.linkType,
    required this.initialValue,
  });
  final SocialLinkType linkType;
  final String initialValue;

  @override
  State<EditSocialMediaLinkPage> createState() =>
      _EditSocialMediaLinkPageState();
}

class _EditSocialMediaLinkPageState extends State<EditSocialMediaLinkPage> {
  late TextEditingController _linkController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Eğer initialValue null veya boş gelirse TextField hata vermesin diye kontrol ekledik
    _linkController = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  // Başlıklar
  String get _pageTitle {
    switch (widget.linkType) {
      case SocialLinkType.instagram:
        return 'Instagram';
      case SocialLinkType.whatsapp:
        return 'Whatsapp';
      case SocialLinkType.website:
        return 'Web Sitesi';
      case SocialLinkType.email:
        return 'İletişim E-Postası';
    }
  }

  // Açıklamalar
  String get _descriptionText {
    switch (widget.linkType) {
      case SocialLinkType.instagram:
        return 'Topluluğunun Instagram hesabına yönlendiren bağlantıyı ekle. Kullanıcılar profilinden hesabına ulaşabilir.';
      case SocialLinkType.whatsapp:
        return 'Topluluğunun WhatsApp grubuna yönlendiren bağlantıyı ekle. Kullanıcılar profilinden gruba katılabilir.';
      case SocialLinkType.website:
        return 'Topluluğunun web sitesine yönlendiren bağlantıyı ekle. Kullanıcılar profilinden sitenizi ziyaret edebilir.';
      case SocialLinkType.email:
        return 'Topluluk hesapları için iletişim e-postası, üyelerin topluluklarla iletişime geçmesini kolaylaştırmak için profilde görünür.';
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    // Önceki SnackBar'ları temizle (üst üste binmemesi için)
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center, // Metni ortalıyoruz
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF19446B), // Görseldeki koyu lacivert tonu
          ),
        ),
        backgroundColor: const Color(
          0xFFF2F2F7,
        ), // Görseldeki çok açık gri/mavi tonu
        behavior: SnackBarBehavior.floating,
        elevation: 0, // Gölgeyi kaldırıyoruz (düz görünüm için)
        shape: const StadiumBorder(), // Tam yuvarlak (hap) formu
        margin: EdgeInsets.only(
          bottom: 24.h,
          left: 40.w,
          right: 40.w,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleSave() async {
    final newValue = _linkController.text.trim();

    // 1. Değişiklik kontrolü: Eğer değer değişmediyse boşuna işlem yapma
    if (newValue == widget.initialValue) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final sessionService = getIt<SessionService>();
      final userRepository = getIt<UserRepository>();
      final currentUser = sessionService.currentUser;

      if (currentUser != null) {
        // Mevcut verileri koruyarak güncel veriyi hazırla
        final currentData =
            currentUser.communityData ??
            CommunityData(
              communityBio: '',
              communityPhotoUrl: '',
              communityTeamMembers: const [],
              instagramUrl: '',
              whatsappUrl: '',
              websiteUrl: '',
              contactEmail: '',
            );

        final updatedData = currentData.copyWith(
          instagramUrl: widget.linkType == SocialLinkType.instagram
              ? newValue
              : currentData.instagramUrl,
          whatsappUrl: widget.linkType == SocialLinkType.whatsapp
              ? newValue
              : currentData.whatsappUrl,
          websiteUrl: widget.linkType == SocialLinkType.website
              ? newValue
              : currentData.websiteUrl,
          contactEmail: widget.linkType == SocialLinkType.email
              ? newValue
              : currentData.contactEmail,
        );

        final updatedUser = currentUser.copyWith(communityData: updatedData);

        // --- ADIM 1: Backend Kaydı ---
        await userRepository.updateUser(
          updatedUser.userID,
          {
            'communityData': updatedUser.communityData?.toMap(),
          },
        );

        // --- ADIM 2: Global Session Yenileme ---
        await sessionService.refreshSession();

        if (mounted) {
          // İşlem başarılı olduğunda o şık SnackBar'ı gösteriyoruz
          _showSnackBar('Değişiklikler kaydedildi');
          Navigator.pop(context, newValue);
        }
      }
    } catch (e) {
      debugPrint('Kaydetme hatası: $e');
      // Hata durumunda rengi/mesajı farklı bir SnackBar gösterebilirsin
      _showSnackBar('Bir hata oluştu, tekrar deneyin');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: 26.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _pageTitle,
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        // Klavye açılınca taşma (overflow) olmaması için
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: TextField(
                controller: _linkController,
                textAlign: TextAlign.center,
                autofocus: true, // Sayfa açılınca klavye otomatik açılsın
                keyboardType: widget.linkType == SocialLinkType.email
                    ? TextInputType.emailAddress
                    : TextInputType.url,
                decoration: InputDecoration(
                  hintText: widget.linkType == SocialLinkType.email
                      ? 'örnek@edu.tr'
                      : 'link giriniz',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 16.h),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              _descriptionText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            SizedBox(height: 40.h),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: 160.w,
      height: 44.h,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E4E79),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22.r),
          ),
          elevation: 0,
        ),
        onPressed: _isLoading ? null : _handleSave,
        child: _isLoading
            ? SizedBox(
                height: 20.w,
                width: 20.w,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'kaydet',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
