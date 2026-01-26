import 'dart:convert';
import 'package:bulusalim/components/auth_input.dart';
import 'package:bulusalim/components/bottomsheetoption.dart';
import 'package:bulusalim/components/map_filter_chip.dart';
import 'package:bulusalim/components/otp_row.dart';
import 'package:bulusalim/components/register_step_view.dart';
import 'package:bulusalim/core/constants/theme/color_themes.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class RegisterInfoPage extends StatefulWidget {
  const RegisterInfoPage({super.key});

  @override
  State<RegisterInfoPage> createState() => _RegisterInfoPageState();
}

class _RegisterInfoPageState extends State<RegisterInfoPage> {
  final PageController _pageController = PageController();

  // --- CONTROLLER'LAR ---
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _universityController = TextEditingController();
  final _genderDisplayController = TextEditingController();
  final _friendSearchController = TextEditingController();

  final List<TextEditingController> _eduOtpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );

  final List<String> _selectedInterests = [];
  Map<String, String> _categories = {};

  int _currentIndex = 0;
  bool _isLoadingConfig = true;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _fetchRemoteConfig();
  }

  // --- REMOTE CONFIG FETCH ---
  Future<void> _fetchRemoteConfig() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );
      await remoteConfig.fetchAndActivate();

      String jsonString = remoteConfig.getString('app_config');
      if (jsonString.isEmpty) {
        jsonString = remoteConfig.getString('categories');
      }

      if (jsonString.isNotEmpty) {
        final dynamic decoded = jsonDecode(jsonString);
        Map<String, dynamic>? categoriesMap;

        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('categories')) {
            final dynamic categoriesValue = decoded['categories'];
            if (categoriesValue is Map<String, dynamic>) {
              categoriesMap = categoriesValue;
            } else if (categoriesValue is String &&
                categoriesValue.isNotEmpty) {
              try {
                final parsed = jsonDecode(categoriesValue);
                if (parsed is Map<String, dynamic>) {
                  categoriesMap = parsed;
                }
              } catch (_) {}
            }
          } else {
            categoriesMap = decoded;
          }
        }

        if (categoriesMap != null) {
          final Map<String, String> newCategories = {};
          categoriesMap.forEach((key, value) {
            newCategories[key] = value.toString();
          });

          if (mounted) {
            setState(() {
              _categories = newCategories;
              _isLoadingConfig = false;
            });
          }
        }
      } else {
        if (mounted) setState(() => _isLoadingConfig = false);
      }
    } catch (e) {
      debugPrint("Remote Config Hatası: $e");
      if (mounted) setState(() => _isLoadingConfig = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _usernameController.dispose();
    _nameController.dispose();
    _dobController.dispose();
    _universityController.dispose();
    _genderDisplayController.dispose();
    _friendSearchController.dispose();
    for (var c in _eduOtpControllers) c.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.pop();
    }
  }

  // --- KAYIT BİTİRME FONKSİYONU ---
  void _finishRegistration() {
    // Burada API'ye kayıt isteği atılmalı ve SessionService güncellenmeli.
    // Başarılı olduktan sonra Home'a yönlendiriyoruz:
    context.go('/home');
  }

  void _toggleInterest(String category) {
    setState(() {
      if (_selectedInterests.contains(category)) {
        _selectedInterests.remove(category);
      } else {
        _selectedInterests.add(category);
      }
    });
  }

  // --- CUPERTINO DATE PICKER ---
  void _showDatePicker() {
    final initialDate = DateTime.now().subtract(const Duration(days: 365 * 18));
    final maxDate = DateTime.now();
    final minDate = DateTime(1920);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (BuildContext builder) {
        return SizedBox(
          height: 300.h,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Text(
                        'Tamam',
                        style: TextStyle(
                          color: AppColors.tertiaryColor,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () {
                        if (_selectedDate == null) {
                          _selectedDate = initialDate;
                        }
                        final formattedDate = DateFormat(
                          'dd/MM/yyyy',
                        ).format(_selectedDate!);
                        _dobController.text = formattedDate;
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _selectedDate ?? initialDate,
                  minimumDate: minDate,
                  maximumDate: maxDate,
                  onDateTimeChanged: (DateTime newDate) {
                    setState(() {
                      _selectedDate = newDate;
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- BOTTOM SHEETS ---
  void _selectGender(String gender) {
    setState(() => _genderDisplayController.text = gender);
    Navigator.pop(context);
  }

  void _showGenderPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return CustomActionBottomSheet(
          options: [
            BottomSheetOption(
              icon: Icons.female,
              text: 'Kadın',
              onTap: () => _selectGender('Kadın'),
            ),
            BottomSheetOption(
              icon: Icons.male,
              text: 'Erkek',
              onTap: () => _selectGender('Erkek'),
            ),
            BottomSheetOption(
              icon: Icons.brightness_5_outlined,
              text: 'Non-binary',
              onTap: () => _selectGender('Non-binary'),
            ),
            BottomSheetOption(
              icon: Icons.block_outlined,
              text: 'Belirtmek İstemiyorum',
              onTap: () => _selectGender('Belirtmek İstemiyorum'),
            ),
            BottomSheetOption(
              icon: Icons.circle_outlined,
              text: 'Diğer',
              onTap: () => _selectGender('Diğer'),
            ),
          ],
        );
      },
    );
  }

  void _showPhotoPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return CustomActionBottomSheet(
          options: [
            BottomSheetOption(
              icon: Icons.add_a_photo_outlined,
              text: 'Fotoğraf Çek',
              onTap: () => Navigator.pop(context),
            ),
            BottomSheetOption(
              icon: Icons.image_outlined,
              text: 'Fotoğraflardan Seç',
              onTap: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentIndex == 0
            ? null
            : IconButton(
                icon: Icon(Icons.undo, color: Colors.black, size: 24.sp),
                onPressed: _prevPage,
              ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: [
          // 1. KULLANICI ADI
          RegisterStepView(
            title: 'Kullanıcı Adı',
            controller: _usernameController,
            onNext: _nextPage,
            description: 'Uygulama içerisinde insanlar sizi bu isimle görecek.',
            hintText: '@kullaniciadi',
          ),

          // 2. AD SOYAD
          RegisterStepView(
            title: 'Ad - Soyad',
            controller: _nameController,
            onNext: _nextPage,
          ),

          // 3. DOĞUM TARİHİ
          RegisterStepView(
            title: 'Doğum Tarihi',
            controller: _dobController,
            onNext: _nextPage,
            hintText: 'GG/AA/YYYY',
            description:
                'Outnest topluluğuna katılabilmek için 18 yaşını doldurmuş olman gerekmektedir.',
            readOnly: true,
            onTapInput: _showDatePicker,
          ),

          // 4. ÜNİVERSİTE MAİL
          RegisterStepView(
            title: 'Üniversite Doğrulama',
            controller: _universityController,
            onNext: _nextPage,
            hintText: '@edu.tr',
            buttonText: 'gönder',
            description:
                'Üniversiteni doğruladığında, üniversite bilgin profilinde otomatik olarak görünür.',
            onSkip: () => _pageController.jumpToPage(5),
          ),

          // 5. ÜNİVERSİTE OTP
          RegisterStepView(
            title: 'Doğrulama Kodu',
            onNext: _nextPage,
            buttonText: 'gönder',
            description: 'Mail adresinize gelen 6 haneli kodu giriniz.',
            customContent: OtpRow(controllers: _eduOtpControllers),
            onSkip: _nextPage,
          ),

          // 6. CİNSİYET
          RegisterStepView(
            title: 'Cinsiyet',
            controller: _genderDisplayController,
            hintText: 'lütfen seçiniz',
            onNext: _nextPage,
            readOnly: true,
            onTapInput: _showGenderPicker,
            onSkip: _nextPage,
          ),

          // 7. PROFİL FOTOĞRAFI
          RegisterStepView(
            title: 'Profil Fotoğrafı',
            onNext: _nextPage,
            buttonText: 'devam',
            customContent: GestureDetector(
              onTap: _showPhotoPicker,
              child: Container(
                width: 120.w,
                height: 120.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F1F5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt_outlined,
                  size: 40.sp,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ),

          // 8. İLGİ ALANLARI
          RegisterStepView(
            title: 'İlgi Alanların',
            description: 'En az 3 adet seçmenizi öneririz.',
            onNext: _nextPage,
            onSkip: _nextPage,
            buttonText: 'devam',
            customContent: _isLoadingConfig
                ? SizedBox(
                    height: 100.h,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    ),
                  )
                : _categories.isEmpty
                ? Center(
                    child: Text(
                      "Kategoriler yüklenemedi.\nLütfen internet bağlantınızı kontrol edin.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                    ),
                  )
                : Wrap(
                    spacing: 12.w,
                    runSpacing: 12.h,
                    alignment: WrapAlignment.center,
                    children: _categories.entries.map((entry) {
                      final categoryName = entry.key;
                      final categoryEmoji = entry.value;
                      final isSelected = _selectedInterests.contains(
                        categoryName,
                      );

                      return MapFilterChip(
                        label: categoryName.toLowerCase(),
                        emoji: categoryEmoji,
                        isSelected: isSelected,
                        onTap: () => _toggleInterest(categoryName),
                      );
                    }).toList(),
                  ),
          ),

          // 9. ARKADAŞLARINI EKLE (SON ADIM)
          RegisterStepView(
            title: 'Arkadaşlarını Ekle',
            onNext: _finishRegistration, // Bitir ve Home'a git
            buttonText: 'bitir', // Metin güncellendi
            customContent: Column(
              children: [
                AuthInput(
                  controller: _friendSearchController,
                  hintText: 'Ara',
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey,
                    size: 24.sp,
                  ),
                ),
                SizedBox(height: 20.h),
                _buildActionRow(
                  Icons.contact_phone_outlined,
                  'Kişilerinden ara',
                ),
                Divider(color: Colors.grey.shade200),
                _buildActionRow(Icons.camera_alt_outlined, 'Instagram bağla'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          Icon(icon, color: Colors.black, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.black, size: 24.sp),
        ],
      ),
    );
  }
}
