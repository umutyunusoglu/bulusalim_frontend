import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:outnest/application/data_providers/turkey_cities_provider.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/enums/account_type_enum.dart';
import 'package:outnest/core/utils/types/enums/gender_enum.dart';
import 'package:outnest/domain/datasources/university_datasource.dart';
import 'package:outnest/domain/entities/user/user_entity.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/analytics/analytics_service.dart';
import 'package:outnest/domain/services/auth_service.dart';
import 'package:outnest/domain/usecases/upload_profile_picture_usecase.dart';
import 'package:outnest/presentation/auth/registration_loading_screen.dart';
import 'package:outnest/presentation/auth/view/components/otp_row.dart';
import 'package:outnest/presentation/auth/view/components/register_step_view.dart';
import 'package:outnest/presentation/shared/bottom_sheet_option.dart';
import 'package:outnest/presentation/shared/dialogs/show_popups.dart';
import 'package:outnest/presentation/shared/form/formatters/name_surname_formatter.dart';
import 'package:outnest/presentation/shared/form/formatters/username_formatter.dart';
import 'package:outnest/presentation/shared/form/validators/validate_date_of_birth.dart';
import 'package:outnest/presentation/shared/form/validators/validate_name_surname.dart';
import 'package:outnest/presentation/shared/form/validators/validate_university_mail.dart';
import 'package:outnest/presentation/shared/form/sanitizer.dart';
import 'package:outnest/presentation/shared/form/validators/validate_username.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class RegisterInfoPage extends StatefulWidget {
  const RegisterInfoPage({super.key});

  @override
  State<RegisterInfoPage> createState() => _RegisterInfoPageState();
}

enum RegisterStep {
  username,
  name,
  dob,
  universityEmail,
  universityOtp,
  city,
  profilePhoto,
  permissions,
}

final Map<RegisterStep, RegisterStep> backSteps = {
  RegisterStep.name: RegisterStep.username,
  RegisterStep.dob: RegisterStep.name,
  RegisterStep.universityEmail: RegisterStep.dob,
  RegisterStep.universityOtp: RegisterStep.universityEmail,
  RegisterStep.city: RegisterStep.universityEmail,
  RegisterStep.profilePhoto: RegisterStep.city,
  RegisterStep.permissions: RegisterStep.profilePhoto,
};

class _RegisterInfoPageState extends State<RegisterInfoPage>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController();

  // --- CONTROLLER'LAR ---
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _universityController = TextEditingController();
  final _cityDisplayController = TextEditingController();
  final _friendSearchController = TextEditingController();

  // --- İZİN STATE'LERİ (Varsayılan Kapalı) ---
  bool _permNotifications = false;
  bool _permLocation = false;
  bool _permCamera = false;
  bool _permPhotos = false;

  final _logger = getIt<LoggingService>();

  final List<TextEditingController> _eduOtpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );

  int _currentIndex = 0;
  DateTime? _selectedDate;

  String? _detectedUniversity;
  bool _isSendingEmail = false;
  bool _isVerifyingEmail = false;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _syncAllPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _usernameController.dispose();
    _nameController.dispose();
    _dobController.dispose();
    _universityController.dispose();
    _cityDisplayController.dispose();
    _friendSearchController.dispose();
    for (final c in _eduOtpControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      await _syncAllPermissions();
    }
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevPage() {
    if (_currentIndex > 0) {
      final currentStep = RegisterStep.values[_currentIndex];
      final backStep = backSteps[currentStep]!;
      final backIndex = RegisterStep.values.indexOf(backStep);

      if (_currentIndex - backIndex > 1) {
        _pageController.jumpToPage(backIndex);
      } else {
        _pageController.animateToPage(
          backIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      context.pop();
    }
  }

  bool _isRegistering = false;

  // --- KAYIT BİTİRME FONKSİYONU ---
  Future<void> _finishRegistration() async {
    if (_isRegistering) return; // Çift tıklamayı önle

    setState(() => _isRegistering = true);

    try {
      final username = sanitizeUsername(_usernameController.text);
      final name = sanitizeName(_nameController.text);
      final dob = _selectedDate!;
      GenderEnum gender = GenderEnum.fromString('Belirtmek İstemiyorum');
      final city = _cityDisplayController.text.trim();
      final List<String> interests = []; // Hobiler default boş liste

      final uploadUseCase = getIt<UploadProfilePicture>();
      var profileImageUrl = '';
      if (_selectedImage != null) {
        profileImageUrl =
            await uploadUseCase.call(
              userID: getIt<FirebaseAuth>().currentUser!.uid,
              filePath: _selectedImage!.path,
            ) ??
            '';
      }
      final isEmailVerified = _detectedUniversity != null;
      final university = isEmailVerified ? _detectedUniversity! : null;
      final universityEmail = isEmailVerified
          ? sanitizeEmail(_universityController.text)
          : null;

      final userRepository = getIt<UserRepository>();

      final newUser = UserEntity(
        userID: getIt<FirebaseAuth>().currentUser!.uid,
        username: username,
        nameSurname: name,
        birthDate: dob,
        gender: gender,
        university: university,
        universityEmail: universityEmail,
        profileImageUrl: profileImageUrl,
        city: city.isEmpty ? null : city,
        bio: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
        followeeCount: 0,
        hobbies: interests,
        followerCount: 0,
        accountType: AccountType.personal,
        communityData: null,
        phoneNumber: getIt<AuthService>().getUserPhoneNumber().toNullable(),
        capabilities: const {},
      );

      await userRepository.createUser(newUser);

      if (!mounted) return;
      context.go('/splash', extra: UniqueKey());
    } catch (e, stackTrace) {
      debugPrint('HATA OLUŞTU: $e');
      debugPrint('Stack Trace: $stackTrace');

      getIt<LoggingService>().error('Kayıt tamamlanamadı: $e');

      if (mounted) {
        showErrorPopup(
          context,
          message:
              'Kayıt gerçekleşirken bir sorunla karşılaşıldı. Lütfen tekrar deneyiniz',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRegistering = false);
      }
    }
  }

  void _showCityPicker() {
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Consumer(
              builder: (context, ref, child) {
                final cities = ref.watch(turkeyCitiesProvider);
                final filteredCities = cities
                    .where(
                      (c) =>
                          c.toLowerCase().contains(searchQuery.toLowerCase()),
                    )
                    .toList();

                return Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  padding: EdgeInsets.only(
                    top: 20.h,
                    left: 20.w,
                    right: 20.w,
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Şehrini Seç',
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onBackgroundColor,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Container(
                        height: 40.h,
                        decoration: BoxDecoration(
                          color: AppColors.inputFillColor,
                          borderRadius: BorderRadius.circular(25.r),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Row(
                          children: [
                            Icon(
                              Symbols.search,
                              color: AppColors.textGrey,
                              size: 20.sp,
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: TextField(
                                onChanged: (val) {
                                  setModalState(() {
                                    searchQuery = val;
                                  });
                                },
                                textAlignVertical: TextAlignVertical.center,
                                style: TextStyle(
                                  fontFamily: 'SF Pro Display',
                                  fontSize: 14.sp,
                                  color: AppColors.onBackgroundColor,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Şehir ara...',
                                  hintStyle: TextStyle(
                                    fontFamily: 'SF Pro Display',
                                    color: AppColors.textGrey,
                                    fontSize: 14.sp,
                                  ),
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Expanded(
                        child: ListView.builder(
                          itemCount: filteredCities.length,
                          itemBuilder: (context, index) {
                            final city = filteredCities[index];
                            final isSelected =
                                _cityDisplayController.text == city;
                            return ListTile(
                              title: Text(
                                city,
                                style: TextStyle(
                                  fontFamily: 'SF Pro Display',
                                  fontSize: 14.sp,
                                  color: isSelected
                                      ? AppColors.primaryColor
                                      : AppColors.onBackgroundColor,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(
                                      Symbols.check_circle,
                                      color: AppColors.primaryColor,
                                      size: 20.sp,
                                    )
                                  : null,
                              onTap: () {
                                setState(() {
                                  _cityDisplayController.text = city;
                                });
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
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
                        _selectedDate ??= initialDate;
                        final formattedDate = DateFormat(
                          'dd/MM/yyyy',
                          'tr_TR',
                        ).format(_selectedDate!);
                        _dobController.text = formattedDate;
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Localizations.override(
                  context: context,
                  locale: const Locale('tr', 'TR'),
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
              ),
            ],
          ),
        );
      },
    );
  }

  // --- BOTTOM SHEETS ---
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
              onTap: () => _pickImage(ImageSource.camera),
            ),
            BottomSheetOption(
              icon: Icons.image_outlined,
              text: 'Fotoğraflardan Seç',
              onTap: () => _pickImage(ImageSource.gallery),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // KAYIT FORMU
        GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: _currentIndex == 0
                  ? null
                  : IconButton(
                      icon: Icon(
                        Symbols.reply,
                        color: Colors.black,
                        size: 24.sp,
                      ),
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
                  onNext: () async {
                    final username = _usernameController.text.trim();

                    final exists = await getIt<UserRepository>()
                        .doesUsernameExist(username);
                    FocusScope.of(context).unfocus();

                    getIt<LoggingService>().warn(exists.toString());

                    if (exists) {
                      showErrorPopup(
                        context,
                        message: 'Bu kullanıcı adı zaten alınmış!',
                      );
                    } else {
                      _nextPage();
                    }
                  },
                  description:
                      'Uygulama içerisinde insanlar sizi bu isimle görecek.',
                  hintText: '@kullaniciadi',
                  inputFormatters: [UsernameFormatter()],
                  validator: () =>
                      validateUsername(_usernameController.text.trim()),
                ),

                // 2. AD SOYAD
                RegisterStepView(
                  title: 'Ad - Soyad',
                  controller: _nameController,
                  onNext: _nextPage,
                  hintText: 'Adınız ve Soyadınız',
                  description:
                      'Gerçek adınızı kullanmanızı öneririz, böylece arkadaşlarınız sizi daha kolay bulabilir.',
                  inputFormatters: [NameSurnameFormatter()],
                  validator: () =>
                      validateNameSurname(_nameController.text.trim()),
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
                  validator: () => validateDateOfBirth(_selectedDate),
                ),

                // 4. ÜNİVERSİTE MAİL
                RegisterStepView(
                  title: 'Üniversite Doğrulama',
                  controller: _universityController,
                  hintText: '@edu.tr',
                  enabled: !_isSendingEmail,
                  buttonText: _isSendingEmail
                      ? 'gönderiliyor...'
                      : 'kod gönder',
                  onChanged: _onUniversityEmailChanged,
                  description: _detectedUniversity != null
                      ? 'Tespit Edilen: $_detectedUniversity'
                      : "Üniversiteni doğruladığında, üniversite bilgin profilinde otomatik olarak görünür. Yalnızca Türkiye'deki üniversiteler desteklenmektedir.",

                  validator: () => validateUniversityMail(
                    _universityController.text.trim(),
                    _detectedUniversity,
                  ),

                  onNext: () async {
                    if (_isSendingEmail) return;
                    setState(() => _isSendingEmail = true);
                    FocusScope.of(context).unfocus();

                    try {
                      print(FirebaseAuth.instance.currentUser?.uid);
                      await getIt<UserRepository>().sendVerificationEmail(
                        sanitizeEmail(_universityController.text),
                      );
                      if (!mounted) return;
                      _nextPage();
                    } on FirebaseFunctionsException catch (error) {
                      if (mounted) {
                        if (error.code == 'resource-exhausted') {
                          showErrorPopup(
                            context,
                            message:
                                'Çok fazla mail yollama isteği gönderdiniz. Lütfen 1 dakika sonra tekrar deneyin!',
                          );

                          _logger.error(
                            'FirebaseAuthException: ${error.code} - ${error.message}',
                          );
                        } else {
                          _logger.error(
                            'Bir hata oluştu: ${error.code} - ${error.message}',
                          );
                        }
                        _logger.error(
                          'Verification email gönderilemedi: $error',
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isSendingEmail = false);
                    }
                  },

                  // BURAYA "ATLA" ÖZELLİĞİ EKLENDİ
                  onSkip: () =>
                      _pageController.jumpToPage(RegisterStep.city.index),

                  footerWidget: TextButton(
                    onPressed: () async {
                      final Uri url = Uri.parse(
                        'https://forms.gle/KfpyB3Y2SeiX28R47',
                      );
                      launchUrl(url, mode: LaunchMode.inAppWebView);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                    ),
                    child: Text(
                      'Üniversitenizi bulamıyor musunuz? Bize bildirin.',
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 12.sp,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),

                // 5. DOĞRULAMA KODU
                RegisterStepView(
                  title: 'Doğrulama Kodu',
                  buttonText: 'onayla',
                  enabled: !_isVerifyingEmail,
                  description:
                      '${_universityController.text} adresine gelen kodu giriniz.',
                  customContent: OtpRow(controllers: _eduOtpControllers),

                  onNext: () async {
                    FocusScope.of(context).unfocus();

                    if (_isVerifyingEmail) return;
                    setState(() => _isVerifyingEmail = true);
                    final otpCode = _eduOtpControllers
                        .map((c) => c.text)
                        .join();
                    try {
                      print('otpCode: $otpCode');
                      await getIt<UserRepository>().verifyEmail(
                        sanitizeEmail(_universityController.text),
                        _detectedUniversity!,
                        otpCode,
                      );

                      if (!mounted) return;
                      setState(() => _isVerifyingEmail = false);
                      _nextPage();
                    } catch (e) {
                      if (mounted) {
                        showErrorPopup(
                          context,
                          message: 'Kod hatalı veya geçersiz',
                        );
                        setState(() => _isVerifyingEmail = true);
                      }
                    }
                  },
                ),

                // 6. ŞEHİR SEÇİMİ
                RegisterStepView(
                  title: 'Şehrini Seç',
                  controller: _cityDisplayController,
                  hintText: 'lütfen seçiniz',
                  description:
                      "Sana en uygun buluşmaları gösterebilmemiz için lütfen yaşadığın şehri doğru gir. Daha sonra Ayarlar'dan değişiklik yapabilirsin.",
                  readOnly: true,
                  onTapInput: _showCityPicker,
                  onNext: () {
                    if (_cityDisplayController.text.trim().isEmpty) {
                      showErrorPopup(
                        context,
                        message: 'Lütfen bir şehir seçiniz.',
                      );
                      return;
                    }
                    _nextPage();
                  },
                ),

                // 7. PROFİL FOTOĞRAFI
                RegisterStepView(
                  title: 'Profil Fotoğrafı',
                  onSkip: _nextPage,
                  customContent: GestureDetector(
                    onTap: _showPhotoPicker,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 180.w,
                          height: 180.w,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F1F5),
                            shape: BoxShape.circle,
                            image: _selectedImage != null
                                ? DecorationImage(
                                    image: FileImage(_selectedImage!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 2,
                            ),
                          ),
                          child: _selectedImage == null
                              ? Icon(
                                  Icons.camera_alt_outlined,
                                  size: 45.sp,
                                  color: Colors.grey.shade400,
                                )
                              : null,
                        ),
                        if (_selectedImage != null)
                          Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 18.sp,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // 8. CİHAZ İZİNLERİ
                RegisterStepView(
                  title: 'Cihaz İzinleri',
                  onNext: _finishRegistration,
                  buttonText: 'bitir',
                  customContent: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPermissionTile(
                        title: 'Bildirimler',
                        description:
                            'Outnest uygulamasına bu cihaza güncellemeler ve önemli bildirimler göndermesine izin verilir.',
                        permission: Permission.notification,
                        value: _permNotifications,
                      ),
                      _buildPermissionTile(
                        title: 'Konum Servisleri',
                        description:
                            'Bulunduğun konuma göre içerik sunabilmemiz için konum bilgine erişilir.',
                        permission: Permission.locationWhenInUse,
                        value: _permLocation,
                      ),

                      _buildPermissionTile(
                        title: 'Kamera',
                        description:
                            'Fotoğraf ve video çekebilmek için kameraya erişim gerekir.',
                        permission: Permission.camera,
                        value: _permCamera,
                      ),

                      _buildPermissionTile(
                        title: 'Fotoğraflar',
                        description:
                            'Galerinden içerik seçebilmek için fotoğraflara erişim gerekir.',
                        permission: Permission.photos,
                        value: _permPhotos,
                      ),

                      // ALT BİLGİLENDİRME METİNLERİ
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Gizlilik ve veri kullanımı hakkında daha fazla bilgi al',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 12.sp,
                              color: AppColors.tertiaryColor,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'Cihaz izinlerinizi daha sonra Ayarlar sayfasından düzenleyebilirsiniz.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textGrey,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // YÜKLEME EKRANI
        if (_isRegistering)
          const Positioned.fill(
            child: RegistrationLoadingScreen(),
          ),
      ],
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

  Timer? _debounce;

  void _onUniversityEmailChanged(String email) {
    if (_isSendingEmail) return;
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _checkUniversity(email);
    });
  }

  Future<void> _checkUniversity(String email) async {
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _detectedUniversity = null);
      return;
    }
    try {
      final uniNames = await getIt<UniversityDatasource>().getUniversityOfMail(
        email,
        'Turkiye',
      );
      setState(() {
        _detectedUniversity = uniNames.isNotEmpty ? uniNames.first : null;
      });
    } catch (_) {
      setState(() => _detectedUniversity = null);
    }
  }

  Future<void> _syncAllPermissions() async {
    final notification = await Permission.notification.status;
    final bluetooth = await Permission.bluetooth.status;
    final location = await Permission.locationWhenInUse.status;
    final camera = await Permission.camera.status;
    final photos = await Permission.photos.status;

    if (!mounted) return;

    setState(() {
      _permNotifications = notification.isGranted;
      _permLocation = location.isGranted;
      _permCamera = camera.isGranted;
      _permPhotos = photos.isGranted || photos.isLimited;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (!mounted) return;
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        if (!mounted) return;
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showErrorPopup(
          context,
          message: 'Resim seçilirken bir hata oluştu',
        );
      }
    }
  }

  Future<void> _handlePermissionTap(Permission permission) async {
    final status = await permission.status;

    if (status.isGranted || status.isLimited) {
      return;
    }

    final result = await permission.request();

    if (!mounted) return;

    if (result.isPermanentlyDenied) {
      _showSettingsDialog();
    }

    await _syncAllPermissions();
  }

  Widget _buildPermissionTile({
    required String title,
    required String description,
    required Permission permission,
    required bool value,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: () => _handlePermissionTap(permission),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: value ? Colors.black87 : Colors.black,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade500,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                SizedBox(width: 6.w),
                Icon(
                  Icons.chevron_right,
                  size: 18.sp,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'İzin Gerekli',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontWeight: FontWeight.w600,
            fontSize: 17.sp,
            color: Colors.black,
          ),
        ),
        content: Text(
          "Bu özelliği kullanabilmek için cihaz ayarlarından Outnest'e izin vermeniz gerekmektedir.",
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 14.sp,
            color: Colors.grey.shade700,
            height: 1.3,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: Text(
              'Ayarlara Git',
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
