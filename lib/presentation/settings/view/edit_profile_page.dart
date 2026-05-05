import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart'; // Carousel DatePicker için gerekli
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/analytics/analytics_service.dart';
import 'package:outnest/domain/services/analytics/event_configs/click_hide_saved_events_analytics_config.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/domain/usecases/upload_profile_picture_usecase.dart';
import 'package:outnest/presentation/settings/view/components/profile_input_row.dart';
import 'package:outnest/presentation/shared/dialogs/show_popups.dart';
import 'package:outnest/presentation/shared/form/formatters/name_surname_formatter.dart';
import 'package:outnest/presentation/shared/form/sanitizer.dart';
import 'package:outnest/presentation/shared/form/validators/validate_bio.dart';
import 'package:outnest/presentation/shared/form/validators/validate_date_of_birth.dart';
import 'package:outnest/presentation/shared/form/validators/validate_name_surname.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _dobController;

  late DateTime _selectedDob;

  bool _hideSavedEvents = false;
  String _profileImageUrl = '';
  String _nameSurname = '';

  bool _profileImageChanged = false;

  late String _username;
  late String _previousName;
  late String _previousBio;
  late String _previousDob;
  late bool _previousHideSavedEvents;

  final _formKey = GlobalKey<FormState>();

  bool _hasChanges = false;
  String? _lastLoggedRemoteImageUrl;

  // Carousel dönerken seçilen geçici tarih
  DateTime _tempSelectedDate =
      getIt<SessionService>().currentUser?.birthDate ?? DateTime(2000, 1);

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  void _initializeUserData() {
    final user = getIt<SessionService>().currentUser;

    _nameController = TextEditingController(text: user?.nameSurname ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');

    _dobController = TextEditingController(
      text: user?.birthDate != null
          ? '${user!.birthDate.day} ${_getMonthName(user.birthDate.month)} ${user.birthDate.year}'
          : '',
    );
    _username = user?.username ?? '';
    _nameSurname = user?.nameSurname ?? '';
    _profileImageUrl = user?.profileImageUrl ?? '';
    if (_profileImageUrl.startsWith('http')) {
      getIt<LoggingService>().debug(
        'EditProfilePage init profile image URL: ${fixEmulatorUrl(_profileImageUrl)}',
      );
    }
    _hideSavedEvents = user?.hideSavedEvents ?? false;
    _selectedDob = user?.birthDate ?? DateTime(2002, 1);

    // Önceki değerleri sakla
    _previousName = user?.nameSurname ?? '';
    _previousBio = user?.bio ?? '';
    _previousDob = _dobController.text;
    _previousHideSavedEvents = user?.hideSavedEvents ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _onFieldChanged(String value) {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  // --- FOTOĞRAF SEÇİM MENÜSÜ ---
  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Gölge için transparent
      elevation: 0,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            // Üst Gölge
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 27.h),
                  _buildPhotoOptionItem(
                    icon: Icons.add_a_photo_outlined,
                    label: 'Fotoğraf Çek',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  SizedBox(height: 27.h),
                  _buildPhotoOptionItem(
                    icon: Icons.image_outlined,
                    label: 'Fotoğraflardan Seç',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  SizedBox(height: 27.h),
                  _buildPhotoOptionItem(
                    icon: Icons.delete_outline,
                    label: 'Fotoğrafı Kaldır',
                    textColor: Colors.redAccent,
                    iconColor: Colors.redAccent,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        //TODO: Fotoğraf kaldırma işlemi
                        _profileImageUrl = '';
                        _profileImageChanged = true;
                        _hasChanges = true;
                      });
                    },
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoOptionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color textColor = Colors.black,
    Color iconColor = Colors.black,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 24.sp, color: iconColor),
          SizedBox(width: 20.w),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // --- CAROUSEL TARİH SEÇİMİ (YENİLENMİŞ) ---
  void _showCarouselDatePicker() {
    _tempSelectedDate = DateTime(2002, 1); // Varsayılan veya mevcut değer

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Gölge için transparent
      elevation: 0,
      builder: (BuildContext context) {
        return Container(
          height: 300.h, // Yükseklik sınırı
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            // Üst Gölge
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Üst Bar (Vazgeç / Bitti)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Vazgeç',
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Seçimi onayla
                        final formattedDate =
                            '${_tempSelectedDate.day} ${_getMonthName(_tempSelectedDate.month)} ${_tempSelectedDate.year}';
                        _dobController.text = formattedDate;
                        _selectedDob = _tempSelectedDate;
                        _onFieldChanged(formattedDate);
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Bitti',
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade200),

              // Cupertino Date Picker
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _selectedDob,
                  minimumDate: DateTime(1900),
                  maximumDate: DateTime.now(),
                  onDateTimeChanged: (DateTime newDate) {
                    _tempSelectedDate = newDate;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Profili Düzenle',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                await _saveProfileChanges();
                if (context.mounted) Navigator.pop(context, true);
              } else {
                showErrorPopup(
                  context,
                  message: 'Lütfen hatalı alanları düzeltin.',
                );
              }
            },
            child: Text(
              'Bitti',
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.tertiaryColor,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 10.h),

                  // 1. Profil Fotonuz
                  _buildProfilePhotoSection(),
                  SizedBox(height: 32.h),

                  // 2. Form Alanları
                  ProfileInputRow(
                    label: 'İsim',
                    controller: _nameController,
                    onChanged: _onFieldChanged,
                    formatters: [NameSurnameFormatter()],
                    validator: (value) =>
                        validateNameSurname(_nameController.text),
                  ),

                  ProfileInputRow(
                    label: 'Hakkında',
                    controller: _bioController,
                    maxLines: 3,
                    maxLength: 40,
                    onChanged: _onFieldChanged,
                    validator: (value) => validateBio(_bioController.text),
                  ),

                  ProfileInputRow(
                    label: 'Doğum Tarihi',
                    controller: _dobController,
                    readOnly: true, // Sadece inputa basılınca açılır
                    canChange: false,
                    onTap: null,
                    validator: (value) => validateDateOfBirth(_selectedDob),
                  ),

                  // 3. Ayırıcı Çizgi ve Switch
                  Divider(color: Colors.grey.shade200, thickness: 1),
                  /*Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Kaydedilen Buluşmaları Gizle',
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      Transform.scale(
                        scale: 0.8,
                        child: Switch.adaptive(
                          value: _hideSavedEvents,
                          activeColor: Colors.white,
                          activeTrackColor: AppColors.primaryColor,
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: Colors.grey.shade300,
                          onChanged: (val) {
                            setState(() {
                              _hideSavedEvents = val;
                              _hasChanges = true;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                
                */
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- AVATAR BÖLÜMÜ ---
  Widget _buildProfilePhotoSection() {
    String? remoteImageUrl;

    if (_profileImageUrl.isNotEmpty && _profileImageUrl.startsWith('http')) {
      remoteImageUrl = fixEmulatorUrl(_profileImageUrl);
      if (_lastLoggedRemoteImageUrl != remoteImageUrl) {
        _lastLoggedRemoteImageUrl = remoteImageUrl;
        getIt<LoggingService>().debug(
          'Trying to load profile image from Firebase URL: $remoteImageUrl',
        );
      }
    }

    return Column(
      children: [
        GestureDetector(
          onTap: () => _showPhotoOptions(),
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 38.r,
                backgroundColor: Colors.grey.shade200,
                child: ClipOval(
                  child: SizedBox(
                    width: 76.r,
                    height: 76.r,
                    child: _profileImageUrl.isEmpty
                        ? Icon(Icons.person, size: 38.sp, color: Colors.grey)
                        : (_profileImageUrl.startsWith('http')
                              ? CachedNetworkImage(
                                  imageUrl: remoteImageUrl!,
                                  fadeInDuration: Duration.zero,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) {
                                    getIt<LoggingService>().error(
                                      'Profile image load failed. url=$url error=$error',
                                    );
                                    return Icon(
                                      Icons.person,
                                      size: 38.sp,
                                      color: Colors.grey,
                                    );
                                  },
                                )
                              : Image.file(
                                  File(_profileImageUrl),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(
                                        Icons.person,
                                        size: 38.sp,
                                        color: Colors.grey,
                                      ),
                                )),
                  ),
                ),
              ),

              // DÜZENLEME (KALEM) İKONU
              Container(
                padding: EdgeInsets.all(4.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.edit, size: 13.sp, color: Colors.black),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          _nameSurname.isNotEmpty ? '@$_username' : '',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            color: Colors.blueAccent,
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 80, // Performans için kaliteyi biraz düşürebilirsin
        maxWidth: 1000, // Çok büyük resimleri küçültmek iyi olur
      );

      if (pickedFile != null) {
        setState(() {
          _profileImageUrl = pickedFile.path; // Yerel dosya yolunu kaydet
          _profileImageChanged = true; // Değişiklik olduğunu işaretle
          _hasChanges = true;
        });
      }
    } catch (e) {
      debugPrint('Fotoğraf seçerken hata oluştu: $e');
      // İstersen burada bir snackbar ile kullanıcıya hata gösterebilirsin
    }
  }

  Future<void> _saveProfileChanges() async {
    try {
      debugPrint('Profil değişiklikleri kaydediliyor...');
      final updatedData = <String, dynamic>{};

      if (_profileImageChanged) {
        try {
          final newURL = await getIt<UploadProfilePicture>().call(
            userID: getIt<SessionService>().currentUser!.userID,
            filePath: _profileImageUrl,
          );
          updatedData['profileImageUrl'] = newURL;
        } catch (e) {
          debugPrint('Profil resmi yüklenirken hata oluştu: $e');
          updatedData['profileImageUrl'] = '';
        }
      }

      final analytics = getIt<AnalyticsService>();
      if (_nameController.text != _previousName) {
        updatedData['nameSurname'] = sanitizeName(_nameController.text);
      }
      if (_bioController.text != _previousBio) {
        updatedData['bio'] = sanitizeInput(_bioController.text);
      }

      if (_dobController.text != _previousDob) {
        updatedData['birthDate'] = _selectedDob;
      }
      if (_hideSavedEvents != _previousHideSavedEvents) {
        updatedData['hideSavedEvents'] = _hideSavedEvents;
      }

      if (updatedData.isNotEmpty) {
        await getIt<UserRepository>().updateUser(
          getIt<SessionService>().currentUser!.userID,
          updatedData,
        );
      }
      await getIt<SessionService>().refreshSession();

      if (updatedData.containsKey('hideSavedEvents')) {
        getIt<AnalyticsService>().logClickHideSavedEvents(
          ClickHideSavedEventsAnalyticsConfig(value: _hideSavedEvents),
        );
      }
    } catch (e) {
      debugPrint('Profil değişiklikleri kaydedilirken hata oluştu: $e');
      // Hata durumunda kullanıcıya bildirim göstermek isteyebilirsiniz
      showErrorPopup(
        context,
        message:
            'Profil değişiklikleri kaydedilirken hata oluştu. Lütfen tekrar deneyin.',
      );
    }
  }
}
