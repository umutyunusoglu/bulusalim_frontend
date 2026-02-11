import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/enums/gender_enum.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/domain/usecases/upload_profile_picture_usecase.dart';
import 'package:outnest/screens/settings/profile_input_row.dart';
import 'package:flutter/cupertino.dart'; // Carousel DatePicker için gerekli
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _genderController;
  late TextEditingController _dobController;

  late GenderEnum _selectedGender;
  late DateTime _selectedDob;

  bool _hideSavedEvents = false;
  String _profileImageUrl = '';
  String _username = '';

  bool _profileImageChanged = false;

  late String _previousName;
  late String _previousBio;
  late String _previousGender;
  late String _previousDob;
  late bool _previousHideSavedEvents;

  bool _hasChanges = false;

  // Carousel dönerken seçilen geçici tarih
  DateTime _tempSelectedDate = DateTime(2002, 1);

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  void _initializeUserData() {
    final user = getIt<SessionService>().currentUser;

    _nameController = TextEditingController(text: user?.username ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _genderController = TextEditingController(
      text: user?.gender.toString() ?? '',
    );
    _dobController = TextEditingController(
      text: user?.birthDate != null
          ? '${user!.birthDate.day} ${_getMonthName(user.birthDate.month)} ${user.birthDate.year}'
          : '',
    );
    _username = user?.username ?? '';
    _profileImageUrl = user?.profileImageUrl ?? '';
    _hideSavedEvents = user?.hideSavedEvents ?? false;
    _selectedGender = user?.gender ?? GenderEnum.preferNotToSay;
    _selectedDob = user?.birthDate ?? DateTime(2002, 1);

    // Önceki değerleri sakla
    _previousName = user?.username ?? '';
    _previousBio = user?.bio ?? '';
    _previousGender = user?.gender.toString() ?? '';
    _previousDob = _dobController.text;
    _previousHideSavedEvents = user?.hideSavedEvents ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _genderController.dispose();
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

  // --- CİNSİYET SEÇİMİ (MODAL) ---
  void _showGenderSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
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
                      width: 36.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: const Color(0XFF8E8E93),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 22.h),
                  _buildGenderOption(icon: Icons.female, label: 'Kadın'),
                  SizedBox(height: 27.h),
                  _buildGenderOption(icon: Icons.male, label: 'Erkek'),

                  SizedBox(height: 27.h),
                  _buildGenderOption(
                    icon: Icons.block_outlined,
                    label: 'Belirtmek İstemiyorum',
                  ),
                  SizedBox(height: 27.h),
                  _buildGenderOption(
                    icon: Icons.circle_outlined,
                    label: 'Diğer',
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

  Widget _buildGenderOption({required IconData icon, required String label}) {
    return InkWell(
      onTap: () {
        _genderController.text = label;
        switch (label) {
          case 'Kadın':
            _selectedGender = GenderEnum.female;
          case 'Erkek':
            _selectedGender = GenderEnum.male;
          case 'Belirtmek İstemiyorum':
            _selectedGender = GenderEnum.preferNotToSay;
          case 'Diğer':
            _selectedGender = GenderEnum.other;
          default:
            _selectedGender = GenderEnum.preferNotToSay;
        }

        _onFieldChanged(label);
        Navigator.pop(context);
      },
      child: Row(
        children: [
          Icon(icon, size: 24.sp, color: Colors.black87),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
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
                  initialDateTime: _tempSelectedDate,
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
              await _saveProfileChanges();
              if (context.mounted) Navigator.pop(context, true);
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
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
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
              ),

              ProfileInputRow(
                label: 'Hakkında',
                controller: _bioController,
                maxLines: 3,
                maxLength: 40,
                onChanged: _onFieldChanged,
              ),

              ProfileInputRow(
                label: 'Cinsiyet',
                controller: _genderController,
                readOnly: true, // Sadece inputa basılınca açılır
                onTap: _showGenderSelector,
              ),

              ProfileInputRow(
                label: 'Doğum Tarihi',
                controller: _dobController,
                readOnly: true, // Sadece inputa basılınca açılır
                onTap: _showCarouselDatePicker, // Carousel açılır
              ),

              // 3. Ayırıcı Çizgi ve Switch
              Divider(color: Colors.grey.shade200, thickness: 1),
              Row(
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
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  // --- AVATAR BÖLÜMÜ ---
  Widget _buildProfilePhotoSection() {
    ImageProvider? imageProvider;

    if (_profileImageUrl.isNotEmpty) {
      // Eğer URL 'http' ile başlıyorsa sunucudaki resimdir
      if (_profileImageUrl.startsWith('http')) {
        imageProvider = CachedNetworkImageProvider(
          fixEmulatorUrl(_profileImageUrl),
        );
      } else {
        // Değilse, cihazdan yeni seçilmiş yerel bir dosyadır
        imageProvider = FileImage(File(_profileImageUrl));
      }
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 38.r,
              backgroundColor: Colors.grey.shade200,
              backgroundImage:
                  imageProvider, // Yukarıdaki mantığı buraya veriyoruz
              child: _profileImageUrl.isEmpty
                  ? Icon(Icons.person, size: 38.sp, color: Colors.grey)
                  : null,
            ),

            // DÜZENLEME (KALEM) İKONU
            GestureDetector(
              onTap: _showPhotoOptions,
              child: Container(
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
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Text(
          _username.isNotEmpty ? '@$_username' : '',
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
    if (_nameController.text != _previousName) {
      updatedData['username'] = _nameController.text.toLowerCase();
    }
    if (_bioController.text != _previousBio) {
      updatedData['bio'] = _bioController.text;
    }
    if (_genderController.text != _previousGender) {
      getIt<LoggingService>().info('Yeni cinsiyet seçildi: $_selectedGender');
      updatedData['gender'] = _selectedGender.toString().toLowerCase();
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

    debugPrint('Profil değişiklikleri kaydedildi.');
  }
}
